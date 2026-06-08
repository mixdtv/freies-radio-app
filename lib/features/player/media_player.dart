import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';
import 'package:radiozeit/utils/app_logger.dart';

final _log = getLogger('MediaPlayer');

/// Types of audio content being played
enum PlaybackType { live, podcast, archive }

class MediaPlayer extends BaseAudioHandler {
  ValueNotifier<bool> isPlaying = ValueNotifier(false);
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<double> currentSpeed = ValueNotifier(1);
  ValueNotifier<double> position = ValueNotifier(0);
  ValueNotifier<double> duration = ValueNotifier(0);

  AudioPlayer _player = AudioPlayer();
  MediaItem? currentMedia;
  Timer? restartTimer;
  bool _isPaused = false;
  PlaybackType _playbackType = PlaybackType.live;
  String? _archivePlaylistUrl;
  Map<String, String>? _archiveHeaders;

  /// Exponential backoff state for stream restart. Auto-reconnects keep this
  /// counter (they call [play], not [playMediaItem]), so the delay actually
  /// escalates: 5, 10, 20, 40, 80, then capped at [_maxRestartDelaySec]. It is
  /// only reset to 0 by a user-initiated [playMediaItem] or after the stream
  /// has played steadily for [_sustainedPlaybackToReset] (see [_watchdogTick]).
  int _restartAttempts = 0;
  static const int _maxRestartDelaySec = 120;

  /// Stall watchdog for live streams.
  ///
  /// During a reception gap (tunnel, dead zone while driving) iOS's AVPlayer
  /// can drop the connection to a live progressive stream and get stuck
  /// `buffering` indefinitely — without ever emitting an error or `completed`
  /// event. None of the event-based recovery triggers fire, so the player
  /// sits silent until the app is restarted. The watchdog samples playback
  /// position; if it stops advancing while we believe we're playing, it forces
  /// a reconnect.
  Timer? _watchdogTimer;
  Duration _lastObservedPosition = Duration.zero;
  DateTime _lastProgressTime = DateTime.now();
  static const Duration _watchdogInterval = Duration(seconds: 5);
  static const Duration _stallThreshold = Duration(seconds: 15);
  /// How long the stream must play steadily before the reconnect backoff is
  /// cleared. Keying off sustained progress (not a momentary `ready`) stops a
  /// connect-then-stall stream from resetting the backoff into a tight loop.
  static const Duration _sustainedPlaybackToReset = Duration(seconds: 30);
  /// When the current uninterrupted run of playback progress began (null when
  /// not progressing).
  DateTime? _progressingSince;

  /// Reconnect immediately when network connectivity returns.
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  /// Throttle connectivity-triggered reconnects so a flapping connection
  /// (driving through patchy coverage) can't hammer reconnects.
  DateTime? _lastConnectivityReconnect;

  /// True once the user explicitly stopped playback. The watchdog keys off the
  /// player's transient `playing` flag, which can briefly lag a `stop()`; this
  /// records the user's intent so a stalled-then-stopped stream isn't revived.
  bool _userStopped = false;

  /// True once [destroy] has run; suppresses any late restart scheduling.
  bool _disposed = false;

  /// Cumulative duration of all segments before the current one (for archive playback).
  double _segmentOffset = 0;
  /// Duration of each segment in seconds (for archive playback).
  List<double> _segmentDurations = [];

  MediaPlayer() {


    _player.playbackEventStream
        .listen(_transformEvent,
        onError: (Object e, StackTrace st) {
          _log.severe('Error on playbackEventStream', e, st);
          restartPlayer();
        });


    _player.positionStream.listen((value) {
      if (_playbackType == PlaybackType.archive) {
        position.value = _segmentOffset + value.inMilliseconds / 1000;
      } else {
        position.value = value.inMilliseconds / 1000;
      }
    });

    _player.currentIndexStream.listen((index) {
      if (_playbackType == PlaybackType.archive && index != null && _segmentDurations.isNotEmpty) {
        double offset = 0;
        for (int i = 0; i < index && i < _segmentDurations.length; i++) {
          offset += _segmentDurations[i];
        }
        _segmentOffset = offset;
      }
    });

    _watchdogTimer = Timer.periodic(_watchdogInterval, (_) => _watchdogTick());

    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);
  }

  /// Periodically checks whether a live stream that should be playing has
  /// stopped advancing, and forces a reconnect if it has stalled past the
  /// threshold. See [_watchdogTimer].
  void _watchdogTick() {
    // Only monitor live playback that we believe is actively playing. In any
    // other state, keep the progress marker fresh so we don't falsely flag a
    // stall the moment playback (re)starts.
    final now = DateTime.now();
    if (_playbackType != PlaybackType.live ||
        _isPaused ||
        _userStopped ||
        currentMedia == null ||
        !_player.playing) {
      _lastObservedPosition = _player.position;
      _lastProgressTime = now;
      _progressingSince = null;
      return;
    }

    // Any change in position counts as progress — including a backward seek on
    // a seekable live (HLS DVR) stream. Tracking a high-water-mark instead
    // would flag healthy catch-up playback after a rewind as a false stall.
    final position = _player.position;
    if (position != _lastObservedPosition) {
      _lastObservedPosition = position;
      _lastProgressTime = now;
      // Clear the backoff only after the stream has played steadily for a
      // while, so a connect-then-stall flicker can't keep zeroing it.
      _progressingSince ??= now;
      if (_restartAttempts > 0 &&
          now.difference(_progressingSince!) >= _sustainedPlaybackToReset) {
        _log.info('Stream stable — resetting reconnect backoff');
        _restartAttempts = 0;
      }
      return;
    }

    // Position hasn't advanced this tick. We deliberately do NOT clear
    // _progressingSince here: a brief mid-stream rebuffer that self-recovers
    // (never reaching the stall threshold) shouldn't restart the
    // sustained-playback clock. The clock is reset only on an actual
    // (re)start in play(); a genuine stall below triggers restartPlayer().

    // Don't pile up restarts if one is already scheduled and waiting out its
    // backoff.
    if (restartTimer?.isActive ?? false) return;

    final stalledFor = now.difference(_lastProgressTime);
    if (stalledFor >= _stallThreshold) {
      _log.warning(
          'Live stream stalled ${stalledFor.inSeconds}s with no progress — reconnecting');
      restartPlayer();
    }
  }

  /// When connectivity returns after a gap, reconnect a stalled or retrying
  /// live stream immediately instead of waiting out the backoff delay.
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final hasNetwork =
        results.any((r) => r != ConnectivityResult.none);
    if (!hasNetwork) return;
    if (_playbackType != PlaybackType.live ||
        _isPaused ||
        _userStopped ||
        currentMedia == null) return;

    // Throttle: on a flapping connection, ignore regains that arrive right
    // after a reconnect we just triggered. The watchdog still backstops a
    // genuine stall within its threshold.
    final now = DateTime.now();
    if (_lastConnectivityReconnect != null &&
        now.difference(_lastConnectivityReconnect!) < _stallThreshold) {
      return;
    }

    final retryPending = restartTimer?.isActive ?? false;
    final sinceProgress = now.difference(_lastProgressTime);
    final stalled = _player.playing && sinceProgress >= _stallThreshold;

    // Don't interrupt healthy playback (e.g. on a WiFi/cellular handoff while
    // audio is still flowing) — only act if we're stalled or already retrying.
    if (retryPending || stalled) {
      _log.info(
          'Connectivity regained (retryPending=$retryPending, stalled=$stalled) — reconnecting now');
      _lastConnectivityReconnect = now;
      // Reconnect immediately (immediate:true => 0s delay) but DON'T zero
      // _restartAttempts — otherwise a flapping connection would reset the
      // counter every regain and the backoff could never escalate. A genuine
      // recovery clears the counter after sustained playback (see _watchdogTick).
      restartPlayer(immediate: true);
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    _log.info('onTaskRemoved - cleaning up player');
    await stop();
    // Clear media item to dismiss notification
    mediaItem.add(null);
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
    destroy();
    await super.onTaskRemoved();
  }

  @override
  Future<void> onNotificationDeleted() async {
    _log.info('onNotificationDeleted - stopping player');
    await stop();
    await super.onNotificationDeleted();
  }



  restartPlayer({bool immediate = false}) {
    restartTimer?.cancel();
    // Don't schedule restarts after teardown or after the user explicitly
    // stopped — a late completed/error event must not resurrect the player.
    // (play()/playMediaItem clear _userStopped before any legitimate restart.)
    if (_disposed || _userStopped) return;
    // Only live streams auto-restart. Archives use session-based playback and
    // podcasts must not restart from position 0 (they stop on error/complete).
    if (_playbackType == PlaybackType.archive ||
        _playbackType == PlaybackType.podcast) {
      _log.info('Skipping restart for $_playbackType playback');
      return;
    }

    final delaySec = immediate
        ? 0
        : min(5 * pow(2, _restartAttempts).toInt(), _maxRestartDelaySec);
    _restartAttempts++;
    _log.info('Scheduling restart in ${delaySec}s (attempt $_restartAttempts)');

    // Reset the stall marker so the watchdog gives the fresh connection a full
    // grace period before considering it stalled again.
    _lastProgressTime = DateTime.now();

    restartTimer = Timer(Duration(seconds: delaySec), () {
      // Reconnect via play() rather than playMediaItem() so we DON'T reset
      // _restartAttempts — that's what lets the backoff actually escalate
      // across repeated failures instead of looping at the minimum delay.
      if (currentMedia != null) {
        play();
      }
    });
  }


  @override
  playMediaItem(MediaItem item) async {
    // Podcasts flow through playMediaItem too, but must NOT be treated as live:
    // live streams auto-reconnect to the live edge, whereas a podcast restart
    // would jump back to position 0 and lose the listener's place.
    _playbackType = item.extras?['isPodcast'] == true
        ? PlaybackType.podcast
        : PlaybackType.live;
    _restartAttempts = 0;
    _isPaused = false;
    currentMedia = item;
    mediaItem.add(item);
    play();
  }

  /// Play archive content via HLS playlist.
  ///
  /// Uses the backend's HLS playlist endpoint which serves an m3u8 playlist
  /// pointing to individual 1-minute m4a segments. The player handles
  /// buffering, gapless playback, and seeking natively.
  playArchiveHls({
    required String url,
    required Map<String, String> headers,
    required MediaItem item,
  }) async {
    _playbackType = PlaybackType.archive;
    _archivePlaylistUrl = url;
    _archiveHeaders = headers;
    await _player.stop();
    _isPaused = false;
    _userStopped = false;
    currentMedia = item;
    mediaItem.add(item);
    restartTimer?.cancel();
    position.value = 0;
    duration.value = 0;

    _log.info('playArchiveHls: ${item.title}');
    _log.info('Playlist URL: $url');

    try {
      isLoading.value = true;
      _notificationBuffering();

      // Fetch the playlist to get segment URLs and durations
      // iOS HLS doesn't support standard M4A, so we use ConcatenatingAudioSource
      final segments = await _fetchSegments(url, headers);
      if (segments.isEmpty) {
        _log.warning('No segments found in playlist');
        isLoading.value = false;
        _notificationStop();
        return;
      }

      _log.info('Loading ${segments.length} segments via ConcatenatingAudioSource');

      // Store segment durations for cumulative position tracking
      _segmentDurations = segments.map((s) => s.duration).toList();
      _segmentOffset = 0;

      // Compute total duration from segment durations (more reliable than
      // player-reported duration for ConcatenatingAudioSource)
      duration.value = _segmentDurations.fold(0.0, (sum, d) => sum + d);

      // Build concatenating source from segment URLs with auth headers
      final audioSources = segments.map((s) =>
        AudioSource.uri(Uri.parse(s.url), headers: headers)
      ).toList();

      final playlist = ConcatenatingAudioSource(children: audioSources);
      await _player.setAudioSource(playlist);
      _log.info('Playlist loaded, duration=${duration.value}s (${_segmentDurations.length} segments)');

      _player.play();
      _notificationPlay();
      isLoading.value = false;
    } catch (e, st) {
      _log.severe('Error loading HLS playlist', e, st);
      isLoading.value = false;
      _notificationStop();
    }
  }



  @override
  setSpeed(double speed) async {
    _log.info('setSpeed $speed');
    currentSpeed.value = speed;
    _player.setSpeed(speed);
  }

  @override
  seek(Duration position) async {
    if (_playbackType == PlaybackType.archive && _segmentDurations.isNotEmpty) {
      // Convert absolute position to segment index + local offset
      double targetSec = position.inMilliseconds / 1000;
      double accumulated = 0;
      for (int i = 0; i < _segmentDurations.length; i++) {
        if (accumulated + _segmentDurations[i] > targetSec) {
          final localOffset = targetSec - accumulated;
          // Update offset immediately to avoid race between positionStream
          // and currentIndexStream (positionStream may fire first with the
          // local position before currentIndexStream updates the offset).
          _segmentOffset = accumulated;
          await _player.seek(
            Duration(milliseconds: (localOffset * 1000).toInt()),
            index: i,
          );
          return;
        }
        accumulated += _segmentDurations[i];
      }
      // Past the end — seek to last segment
      final lastIndex = _segmentDurations.length - 1;
      _segmentOffset = accumulated - _segmentDurations[lastIndex];
      await _player.seek(
        Duration(milliseconds: (_segmentDurations[lastIndex] * 1000).toInt()),
        index: lastIndex,
      );
    } else {
      await _player.seek(position);
    }
  }

  @override
  pause() async {
    _log.info('pause $currentMedia');
    if(currentMedia == null) return;
    _isPaused = true;
    restartTimer?.cancel();
    await _player.pause();
    _notificationPause();
  }

  /// Resume playback from paused position (for podcasts)
  resume() async {
    _log.info('resume $currentMedia');
    if(currentMedia == null) return;
    _isPaused = false;
    _userStopped = false;
    await _player.play();
    _notificationPlay();
  }

  bool isPause() => _isPaused;

  bool isStopped () => _player.playing == false;

  @override
  play() async {
    // If paused, resume instead of restarting (important for lock screen controls)
    if (_isPaused) {
      resume();
      return;
    }

    // For archive playback, restart the HLS stream
    if (_playbackType == PlaybackType.archive && _archivePlaylistUrl != null) {
      _log.info('play: restarting archive HLS');
      await playArchiveHls(
        url: _archivePlaylistUrl!,
        headers: _archiveHeaders ?? {},
        item: currentMedia!,
      );
      return;
    }

    await _player.stop();
    _isPaused = false;
    _userStopped = false;
    if(currentMedia == null) return;

    restartTimer?.cancel();
    position.value = 0;
    duration.value = 0;

    // Give the new connection a full grace period before the watchdog may
    // consider it stalled, and restart the sustained-playback clock so the
    // backoff is only cleared after this fresh connection proves itself.
    _lastObservedPosition = Duration.zero;
    _lastProgressTime = DateTime.now();
    _progressingSince = null;


    String url = currentMedia!.id;
    _log.info('play $url');

    Duration? mediaDuration;
    try {
      isLoading.value = true;
      _notificationBuffering();
      mediaDuration = await _player.setUrl(url);
    } catch (e,st) {
      _log.severe('Error on setUrl', e, st);
      isLoading.value = false;
      _notificationStop();
      restartPlayer();
      return;
    }
    _log.info('playMediaItem: duration $mediaDuration');
    if(mediaDuration != null) {
      duration.value = mediaDuration.inMilliseconds / 1000;
    }
    // Play regardless of duration - live streams have null duration
    _player.play();
    _notificationPlay();
  }

  @override
  stop() async {
    _log.info('stop $currentMedia');
    isLoading.value = false;
    _userStopped = true;
    _notificationStop();
    restartTimer?.cancel();
    await _player.stop();
  }




  destroy() {
    _log.info('destroy');
    _disposed = true;
    restartTimer?.cancel();
    _watchdogTimer?.cancel();
    _connectivitySub?.cancel();
    _player.dispose();
  }

  _notificationStop() {
    playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.play
        ],
      systemActions: {
        MediaAction.playPause
      },
      androidCompactActionIndices: [0],
        processingState: AudioProcessingState.ready,
        playing: false,
    ));
  }

  _notificationPlay() {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.stop
      ],
      systemActions: const {
        MediaAction.pause
      },
      androidCompactActionIndices: [0],
      processingState: AudioProcessingState.ready,
      playing: true,
    ));
  }

  _notificationPause() {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.play
      ],
      systemActions: const {
        MediaAction.play
      },
      androidCompactActionIndices: [0],
      processingState: AudioProcessingState.ready,
      playing: false,
    ));
  }

  _notificationBuffering() {
    playbackState.add(playbackState.value.copyWith(
      controls: [],
      systemActions: const {},
      androidCompactActionIndices: [0],
      processingState: AudioProcessingState.buffering,
      playing: false,
    ));
  }

   _transformEvent(PlaybackEvent event) {
     _log.fine('State update: $event, playing: ${_player.playing}, type: $_playbackType');

     if(event.processingState == ProcessingState.completed) {
       if (_playbackType == PlaybackType.live) {
         // Auto-restart for live streams (reconnect on drop)
         restartPlayer();
       } else {
         // Podcasts and archives stop when complete
         // HLS archives are handled natively by the player
         _log.info('Playback completed for $_playbackType content');
         _notificationStop();
       }
     }

     // Update loading state based on processing state
     if(event.processingState == ProcessingState.buffering ||
        event.processingState == ProcessingState.loading) {
       isLoading.value = true;
     } else if(event.processingState == ProcessingState.ready && _player.playing) {
       isLoading.value = false;
       // NB: do NOT reset _restartAttempts here — a momentary `ready` on a
       // connect-then-stall stream would zero the backoff every cycle. The
       // backoff is cleared only after sustained progress (see _watchdogTick).
     }

     isPlaying.value = _player.playing;
  }

  /// Fetch segment URLs and durations from an HLS playlist.
  /// Returns a list of (url, duration) pairs.
  Future<List<({String url, double duration})>> _fetchSegments(String playlistUrl, Map<String, String> headers) async {
    try {
      final response = await http.get(
        Uri.parse(playlistUrl),
        headers: headers,
      );

      if (response.statusCode != 200) {
        _log.warning('Failed to fetch playlist: ${response.statusCode}');
        return [];
      }

      final lines = response.body.split('\n');
      final segments = <({String url, double duration})>[];
      double nextDuration = 0;

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('#EXTINF:')) {
          // Parse duration from #EXTINF:5.015511,
          final durationStr = trimmed.substring(8).split(',').first;
          nextDuration = double.tryParse(durationStr) ?? 0;
        } else if (trimmed.isNotEmpty &&
            !trimmed.startsWith('#') &&
            (trimmed.endsWith('.m4a') || trimmed.endsWith('.aac') || trimmed.endsWith('.ts'))) {
          segments.add((url: trimmed, duration: nextDuration));
          nextDuration = 0;
        }
      }

      return segments;
    } catch (e, st) {
      _log.severe('Error fetching playlist', e, st);
      return [];
    }
  }
}