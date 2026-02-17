import 'dart:async';

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

  MediaPlayer() {


    _player.playbackEventStream
        .listen(_transformEvent,
        onError: (Object e, StackTrace st) {
          _log.severe('Error on playbackEventStream', e, st);
          restartPlayer();
        });


    _player.positionStream.listen((value) {
      position.value = value.inMilliseconds / 1000;
    });



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



  restartPlayer({int sec = 5}) {
    restartTimer?.cancel();
    if(sec == 0) {
      _restartNow();
    } else {
      restartTimer = Timer(Duration(seconds: sec),() {
        _restartNow();
      },
      );
    }

  }

  _restartNow() {
    // Don't restart archives - they use session-based playback
    if (_playbackType == PlaybackType.archive) {
      _log.info('Skipping restart for archive playback');
      return;
    }
    if(currentMedia != null) {
      playMediaItem(currentMedia!);
    }
  }


  @override
  playMediaItem(MediaItem item) async {
    _playbackType = PlaybackType.live;
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

      // Fetch the playlist to get segment URLs
      // iOS HLS doesn't support standard M4A, so we use ConcatenatingAudioSource
      final segmentUrls = await _fetchSegmentUrls(url, headers);
      if (segmentUrls.isEmpty) {
        _log.warning('No segments found in playlist');
        isLoading.value = false;
        _notificationStop();
        return;
      }

      _log.info('Loading ${segmentUrls.length} segments via ConcatenatingAudioSource');

      // Build concatenating source from segment URLs with auth headers
      final audioSources = segmentUrls.map((segmentUrl) =>
        AudioSource.uri(Uri.parse(segmentUrl), headers: headers)
      ).toList();

      final playlist = ConcatenatingAudioSource(children: audioSources);
      final mediaDuration = await _player.setAudioSource(playlist);
      _log.info('Playlist loaded, duration=$mediaDuration');

      if (mediaDuration != null) {
        duration.value = mediaDuration.inMilliseconds / 1000;
      }

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
    await _player.seek(position);
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
    if(currentMedia == null) return;

    restartTimer?.cancel();
    position.value = 0;
    duration.value = 0;


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
    _notificationStop();
    restartTimer?.cancel();
    await _player.stop();
  }




  destroy() {
    _log.info('destroy');
    restartTimer?.cancel();
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
         restartPlayer(sec: 0);
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
     } else if(event.processingState == ProcessingState.ready) {
       isLoading.value = false;
     }

     isPlaying.value = _player.playing;
  }

  /// Fetch segment URLs from an HLS playlist
  Future<List<String>> _fetchSegmentUrls(String playlistUrl, Map<String, String> headers) async {
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
      final segmentUrls = <String>[];

      for (final line in lines) {
        final trimmed = line.trim();
        // Segment URLs are lines that don't start with # and end with audio extension
        if (trimmed.isNotEmpty &&
            !trimmed.startsWith('#') &&
            (trimmed.endsWith('.m4a') || trimmed.endsWith('.aac') || trimmed.endsWith('.ts'))) {
          segmentUrls.add(trimmed);
        }
      }

      return segmentUrls;
    } catch (e, st) {
      _log.severe('Error fetching playlist', e, st);
      return [];
    }
  }
}