import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';
import 'package:radiozeit/utils/app_logger.dart';

final _log = getLogger('MediaPlayer');

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
  onTaskRemoved() async {

    await stop();
    await destroy();
    await super.onTaskRemoved();
  }

  @override
  onNotificationDeleted() async{
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
    if(currentMedia != null) {
      playMediaItem(currentMedia!);
    }
  }


  @override
  playMediaItem(MediaItem item) async {

    currentMedia = item;
    mediaItem.add(item);
    play();
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
     _log.fine('State update: $event, playing: ${_player.playing}');

     if(event.processingState == ProcessingState.completed) {
       restartPlayer(sec: 0);
     }

     // Update loading state based on processing state AND playing state
     if(event.processingState == ProcessingState.buffering ||
        event.processingState == ProcessingState.loading) {
       isLoading.value = true;
     } else if(event.processingState == ProcessingState.ready && _player.playing) {
       // Only set loading to false when we're ready AND actually playing
       isLoading.value = false;
     }

     isPlaying.value = _player.playing;
  }
}