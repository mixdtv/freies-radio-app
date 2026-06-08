# Stream Reliability & Recovery

An analysis of our audio stream infrastructure, recovery mechanisms, weaknesses, and recommended improvements.

## Architecture Overview

```
Source Streams (external)
    |
    v
FFmpeg (capture & encode)  -->  /tmp/hls/  (5s AAC segments, m3u8 playlist)
    |                      -->  /tmp/dash/ (5s Opus segments, mpd manifest)
    |                      -->  /tmp/wav/  (5s PCM segments for transcription)
    |
    v
aac_archive_watcher  -->  /recordings/{station}/{YYYY}/{MM}/{DD}/
                          (1-minute m4a files, lossless concat)
    |
    v
App (just_audio)  <--  HLS live stream
                  <--  ConcatenatingAudioSource (archive segments)
                  <--  Direct URL (podcasts)
```

---

## App-Side Recovery (freies-radio-app)

### Live Stream Recovery

**Location:** `lib/features/player/media_player.dart`

Recovery only applies to **live** streams. `restartPlayer()` is the single entry point and
returns early for archives, podcasts, a disposed handler, or a user-stopped player.

| Trigger | Action | Delay |
|---------|--------|-------|
| `playbackEventStream` error | `restartPlayer()` | Exponential backoff |
| `ProcessingState.completed` for live | `restartPlayer()` | Exponential backoff |
| Error on `_player.setUrl()` | `restartPlayer()` | Exponential backoff |
| **Stall watchdog** — position not advancing ≥15s while "playing" | `restartPlayer()` | Exponential backoff |
| **Connectivity regained** while stalled/retrying | `restartPlayer(immediate: true)` | Immediate (0s) |

**Flow:** Trigger fires → cancel existing timer → wait backoff delay → `play()` → player
reconnects to the live edge. Auto-reconnects call `play()` (not `playMediaItem()`) so the
backoff counter is preserved across attempts; only a user-initiated `playMediaItem()` or
sustained playback resets it.

**Why the watchdog exists:** On iOS, after a reception gap (tunnel / dead zone while
driving) AVPlayer can drop the connection to a live progressive stream and get stuck
`buffering` indefinitely — *without* emitting an `error` or `completed` event. The three
event-based triggers never fire, so the player sat silent until the app was force-restarted.
The watchdog (a 5s `Timer.periodic`) samples playback position; if it stops advancing for
≥15s while the player believes it is playing, it forces a reconnect. It tracks *any* position
change as progress (so a backward seek on a seekable live/HLS-DVR stream isn't mistaken for a
stall), and a brief mid-stream rebuffer that self-recovers (under the 15s threshold) does not
count as a stall. The connectivity listener (`connectivity_plus`) additionally makes
reconnection near-instant when the network returns, instead of waiting out the backoff.

**Exponential backoff** (`restartPlayer`, `_maxRestartDelaySec = 120`):
`delay = min(5 × 2^attempts, 120)` → **5, 10, 20, 40, 80, then 120s** capped.

- The counter escalates across repeated failures because reconnects call `play()` (which
  does not reset it). It is **reset to 0** only by a user-initiated `playMediaItem()` or after
  the stream plays steadily for `_sustainedPlaybackToReset` (30s) — keyed off sustained
  progress in `_watchdogTick`, **not** a momentary `ready` event (which a connect-then-stall
  stream would emit every cycle, pinning the delay at the minimum). The sustained-playback
  clock tolerates brief hiccups and is restarted only on an actual (re)start in `play()`.
- The connectivity-regain path does **not** zero the counter — it reconnects immediately
  (0s) but lets the backoff keep escalating, so a flapping connection can't defeat it.

**Limitations:**
- No retry limit / circuit breaker — a permanently-down stream retries forever (now every
  ≤120s in steady state, up from a flat ~5–20s loop before this work). Deliberately not
  bounded: a hard "give up" would break recovery from long-but-recoverable outages
  (tunnels, backend restarts). Self-heals via the connectivity listener when signal returns.
- No user notification during retries (silent recovery).
- Watchdog relies on the Dart isolate staying alive in the background; this holds while the
  audio session is active (incl. during a buffering stall) under `UIBackgroundModes: audio`.

### Podcast Recovery

- **No auto-restart.** Podcasts flow through `playMediaItem` but are tagged
  `extras: {'isPodcast': true}` → `_playbackType = PlaybackType.podcast`, so `restartPlayer`
  skips them (a restart would jump back to position 0 and lose the listener's place). They
  stop on error/complete.
- Pause/resume supported.
- User must manually restart.

### Archive Recovery

- **No auto-restart.** `restartPlayer` returns early for `PlaybackType.archive` ("Don't
  restart archives — they use session-based playback").
- If segment fetch fails, playback stops permanently.
- No retry on individual segment failures.

### Error Detection Points

| Layer | File | Mechanism |
|-------|------|-----------|
| Audio player | `media_player.dart` | `playbackEventStream.onError` |
| Audio player | `media_player.dart` | `_transformEvent` processing state (`completed`/`ready`) |
| Audio player | `media_player.dart` | `_watchdogTick` position-stall detection |
| HTTP client | `http_api.dart` | 30-second connect/receive/send timeouts |
| HTTP client | `http_api.dart` | DioException mapping |
| User-facing | `error_mapper.dart` | Pattern matching on error messages |

---

## Backend-Side Recovery (radiozeit-backend)

### Stream Capture

- **One FFmpeg process per stream**, spawned as Celery task with `start_new_session=True`
- PID tracked in `{DIRECTORY_TO_WATCH}/{prefix}/{prefix}_ffmpeg.pid`
- Output: HLS (AAC 96k), DASH (Opus 128k), WAV (16kHz PCM) segments

### Stream Restarter Daemon

**File:** `stream_restarter.py`

- Polls `/api/v1/streams/check_restart` every **10 seconds**
- Checks if FFmpeg process is alive via `psutil.Process(pid).is_running()`
- If dead: restarts FFmpeg with original parameters
- If force restart: kills process, waits 7 seconds, respawns

### Scheduled Force Restarts

**File:** `config/celery_config.py:183-200`, `scheduled_tasks.py:24-110`

| Stream Type | Restart Interval | Schedule (UTC) |
|-------------|-----------------|----------------|
| Non-DLF streams | Every 6 hours | 02:50, 08:50, 14:50, 20:50 |
| DLF streams | Every 2 hours | 00:50, 02:50, 04:50, ... |

**Why force restarts?** FFmpeg processes accumulate memory/resources over time. Without periodic restarts, streams degrade in quality or stop producing segments. DLF streams are more aggressively restarted, suggesting they are less stable.

### Archive Recording

**File:** `aac_archive_watcher.py`

- Runs every 30 seconds
- Collects 12 HLS segments (= 60 seconds) from `/tmp/hls/`
- Concatenates losslessly into 1-minute m4a files
- Storage: `/recordings/{station}/{YYYY}/{MM}/{DD}/{station}-{YYYYMMDD}-{HHMM}-offset{Xms}.m4a`
- Offset tracks alignment to minute boundaries based on FFmpeg start timestamp

### Monitoring

| Component | Tool | Port |
|-----------|------|------|
| System metrics | Node Exporter | 9100 |
| GPU metrics | NVIDIA Exporter | 9400 |
| App metrics | Custom radiozeit_exporter | 9401 |
| Dashboards | Grafana | - |
| Scraping | Prometheus | - |

**Custom metrics:** `radiozeit_ffmpeg_processes_total`, `radiozeit_ffmpeg_streams_total`, `radiozeit_broadcasters_total`

---

## Weaknesses

### Critical

1. **Single point of failure per stream.** One FFmpeg process, one server. If the server goes down, all its streams are offline with no failover.

2. **No stream quality monitoring.** Only checks if FFmpeg process exists, not if it's actually producing audio. A zombie process that produces silence would go undetected.

3. **No circuit breaker in app.** If source stream is permanently down, the app retries forever — draining battery and generating useless network requests. *(Partially addressed: backoff now escalates to one attempt per 120s instead of a flat ~5s loop; a true circuit breaker is still open — see App-Side improvement #5.)*

4. **Archive playback has no recovery.** If a segment fails to load during archive playback, the entire playback stops. No retry, no skip-to-next-segment.

### Moderate

5. **10-second restart detection lag.** Stream restarter polls every 10 seconds. Combined with the 7-second restart wait, a stream can be down for ~17 seconds before recovery.

6. **No exponential backoff** (~~app~~ / backend). The **app** now escalates 5→10→20→40→80→120s (resolved); the **backend** restarter still uses fixed intervals that can hammer a struggling server.

7. **FFmpeg memory leaks require 2-6 hour restarts.** Each restart causes a brief stream interruption for all listeners.

8. **Archive timing precision.** Fixed -19 second offset (`audio_archive_service.py:25`) assumes consistent Whisper latency. No per-stream calibration.

9. **No user feedback during recovery.** App silently retries — user sees loading but doesn't know if recovery is happening or if stream is permanently down.

10. **Podcast "final chunk" problem.** Small final chunks (<30KB) never trigger transcription. Stream restarter has a fragile workaround (touching file mtime).

### Minor

11. ~~**No network connectivity monitoring in app.**~~ *(Resolved: `connectivity_plus` listener triggers an immediate reconnect when the network returns.)*

12. **Hardcoded paths.** `/tmp/wav/`, `/tmp/hls/`, `/tmp/dash/` are not configurable.

13. **API key authentication disabled by default.** Stream endpoints are unprotected unless explicitly enabled.

14. **File watcher is a single process.** If `file_watcher.py` crashes, transcription stops. No watchdog monitors it.

---

## Recommended Improvements

### App-Side (Priority Order)

| # | Improvement | Effort | Impact | Status |
|---|------------|--------|--------|--------|
| 1 | **Exponential backoff.** Escalates 5→10→20→40→80→120s; resets only on user play or 30s sustained playback. | Small | Prevents battery drain on dead streams | ✅ Done |
| 2 | **Stall watchdog.** Detect a live stream stuck `buffering` (position not advancing ≥15s) and force a reconnect — catches iOS silent stalls that emit no error. | Small | Fixes "won't reconnect after reception hole" | ✅ Done |
| 3 | **Network connectivity listener.** Use `connectivity_plus` to reconnect immediately when network returns. | Small | Instant recovery after reception gaps | ✅ Done |
| 4 | **User feedback during recovery.** Show "Reconnecting..." state instead of generic loading. After prolonged failure, show "Stream unavailable" with retry button. | Small | Better UX | ☐ Open |
| 5 | **Circuit breaker / max-retry.** Optionally stop or widen retries after prolonged continuous failure (paired with #4). Intentionally omitted for now — must not break recovery from long-but-recoverable outages. | Small | Bounds worst-case battery | ☐ Open |
| 6 | **Archive segment retry.** On individual segment load failure, retry 2-3 times before giving up. | Small | More robust archive playback | ☐ Open |
| 7 | **Background audio recovery.** Ensure recovery works correctly when app is backgrounded / screen locked. | Medium | Reliability | ◑ Partial (watchdog runs in bg while session active) |

**Verification:** the live recovery cycle (stall → escalating backoff → recover → reset),
podcast no-restart, and hiccup-tolerant reset were verified on the iOS simulator; build +
launch + live playback were verified on a physical Android device (Galaxy S22). The watchdog
and `connectivity_plus` are pure-Dart / cross-platform; `connectivity_plus` is GMS-free and
its `ACCESS_NETWORK_STATE` permission auto-merges, so the F-Droid build is unaffected.

### Backend-Side (Priority Order)

| # | Improvement | Effort | Impact |
|---|------------|--------|--------|
| 1 | **Stream audio health check.** Verify segments are being written (check file modification time, not just process existence). Alert if no new segments for >15 seconds. | Small | Catches zombie FFmpeg |
| 2 | **Reduce restart detection lag.** Decrease heartbeat from 10s to 3-5s. Or use process exit monitoring instead of polling. | Small | Faster recovery |
| 3 | **Graceful FFmpeg restart.** Start new FFmpeg before killing old one (overlap briefly) to minimize listener interruption during scheduled restarts. | Medium | Seamless restarts |
| 4 | **Fallback stream URLs.** Support multiple source URLs per stream with automatic failover. | Medium | Source redundancy |
| 5 | **Stream quality metrics.** Track bitrate, segment production rate, error count per stream. Expose via Prometheus. | Medium | Observability |
| 6 | **Alerting on stream failure.** Push notification (Slack/email) when a stream fails to restart after N attempts. | Small | Operational awareness |
| 7 | **Investigate FFmpeg memory leak.** Profile FFmpeg over 6+ hours to determine if leak is in FFmpeg, shell wrapper, or Celery. Could extend restart interval if fixed. | Medium | Fewer interruptions |

---

## Open Questions

1. **What is the actual user impact of the 6-hour restarts?** Do listeners experience dropouts? How long is the gap? The app's 5-second retry should mask short gaps, but needs verification.

2. **Why do DLF streams need 2-hour restarts vs 6 hours for others?** Is this a DLF-specific issue (their source stream resets sessions?) or an FFmpeg configuration difference?

3. **What happens to the archive watcher during a restart?** Are segments lost during the FFmpeg restart window? Is there a gap in recordings?

4. **Do we have metrics on stream failure frequency?** How often do streams actually drop outside of scheduled restarts?

5. **What is the app's behavior when switching between WiFi and cellular?** Does just_audio handle network transitions gracefully, or does it need a manual restart?

6. **Are there source streams that are particularly unreliable?** Would per-stream retry configuration be valuable?

7. **Should the app cache the last few HLS segments locally** for instant playback on reconnect (avoiding the cold-start buffering delay)?

8. **Is there a plan for geographic redundancy?** Multiple servers run different stream sets, but there's no automatic failover between servers.

9. **What is the disk space consumption of /recordings/?** Is there a retention/cleanup policy for old archives?

10. **Should archive playback fall back to re-fetching the playlist** if a segment fails, in case the backend has regenerated it with different segment URLs?
