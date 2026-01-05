
import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';
import 'package:radiozeit/data/model/podcast.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/data/model/radio_program.dart';
import 'package:radiozeit/features/player/archive_audio_service.dart';
import 'package:radiozeit/features/player/media_player.dart';
import 'package:radiozeit/utils/settings.dart';

class PlayerCubit extends Cubit<PlayerCubitState> {
  MediaPlayer player;
  AppSettings settings = AppSettings.getInstance();
  final ArchiveAudioService _archiveService = ArchiveAudioService();
  final String deviceId;

  PlayerCubit(this.player, {required this.deviceId}) : super(PlayerCubitState()) {
    _archiveService.setDeviceId(deviceId);
  }


  @override
  close() async {
    await player.stop();
    player.destroy();
    super.close();
  }

  setSpeed(double speed) {
    player.setSpeed(speed);
  }

  selectRadio(AppRadio radio) {
    if(state.selectedRadio?.id == radio.id) {
      if(player.isPause() || player.isStopped()){
        player.play();
      }
      return;
    }

    _playLiveRadio(radio);
  }

  /// Switch to live radio stream, even if a podcast or archive is playing
  switchToLiveRadio() {
    final radio = state.selectedRadio;
    if (radio == null) return;

    // If already playing live radio (no podcast or archive), do nothing
    if (state.currentPodcastEpisode == null && state.currentArchiveProgram == null) return;

    _playLiveRadio(radio);
  }

  _playLiveRadio(AppRadio radio) {
    settings.setLastRadio(radio.id);
    emit(state.copyWith(
      selectedRadio: radio,
      currentPodcastEpisode: null,
      currentArchiveProgram: null,
      clearPodcast: true,
      clearArchive: true,
    ));
    player.playMediaItem(MediaItem(
        id: radio.stream.getPlatformStream(),
        title: radio.name,
        displayTitle: radio.name,
        displaySubtitle: radio.tags.join(", "),
        extras: {"prefix":radio.prefix},
        artUri:Uri.parse(radio.thumbnail)
    ));

    // player.playMediaItem(MediaItem(
    //   id: 'https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3',
    //   album: "Science Friday",
    //   title: "A Salute To Head-Scratching Science",
    //   artist: "Science Friday and WNYC Studios",
    //   duration: const Duration(milliseconds: 5739820),
    //   artUri: Uri.parse(
    //       'https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg'),
    // ));
  }

  /// Play archived audio for a past program using HLS streaming.
  ///
  /// Uses the backend's HLS playlist endpoint which serves an m3u8 playlist
  /// pointing to individual 1-minute m4a segments. This provides instant
  /// response, gapless playback, and full seeking support.
  playArchiveProgram(RadioEpg program) {
    final radio = state.selectedRadio;
    if (radio == null) return;

    final playbackInfo = _archiveService.buildPlaybackInfo(
      program: program,
      streamPrefix: radio.prefix,
    );

    if (playbackInfo == null) return;

    emit(state.copyWith(
      currentArchiveProgram: program,
      currentPodcastEpisode: null,
      clearPodcast: true,
    ));

    player.playArchiveHls(
      url: playbackInfo.playlistUrl,
      headers: playbackInfo.headers,
      item: MediaItem(
        id: 'archive:${program.id}',
        title: program.title,
        displayTitle: program.title,
        displaySubtitle: program.subheadline,
        duration: Duration(seconds: program.duration),
        extras: {
          'prefix': radio.prefix,
          'isArchive': true,
        },
        artUri: program.icon.isNotEmpty ? Uri.tryParse(program.icon) : null,
      ),
    );
  }

  pause() {
    player.pause();
  }

  unPause() {
    player.play();
  }

  playPodcastEpisode(PodcastEpisode episode, String podcastTitle) {
    emit(state.copyWith(
      currentPodcastEpisode: episode,
      clearPodcast: false,
    ));

    Uri? artUri;
    if (episode.imageUrl.isNotEmpty && Uri.tryParse(episode.imageUrl)?.hasAbsolutePath == true) {
      artUri = Uri.parse(episode.imageUrl);
    }

    player.playMediaItem(MediaItem(
      id: episode.audioUrl,
      title: episode.title,
      displayTitle: episode.title,
      displaySubtitle: podcastTitle,
      album: podcastTitle,
      artist: episode.description,
      artUri: artUri,
    ));
  }

}

class PlayerCubitState {
  AppRadio? selectedRadio;
  PodcastEpisode? currentPodcastEpisode;
  RadioEpg? currentArchiveProgram;

  PlayerCubitState({
    this.selectedRadio,
    this.currentPodcastEpisode,
    this.currentArchiveProgram,
  });

  /// Whether currently playing archived content (not live)
  bool get isPlayingArchive => currentArchiveProgram != null;

  /// Whether currently playing podcast content
  bool get isPlayingPodcast => currentPodcastEpisode != null;

  /// Whether playing live radio stream
  bool get isPlayingLive => !isPlayingArchive && !isPlayingPodcast;

  PlayerCubitState copyWith({
    AppRadio? selectedRadio,
    PodcastEpisode? currentPodcastEpisode,
    RadioEpg? currentArchiveProgram,
    bool clearPodcast = false,
    bool clearArchive = false,
  }) {
    return PlayerCubitState(
      selectedRadio: selectedRadio ?? this.selectedRadio,
      currentPodcastEpisode: clearPodcast ? null : (currentPodcastEpisode ?? this.currentPodcastEpisode),
      currentArchiveProgram: clearArchive ? null : (currentArchiveProgram ?? this.currentArchiveProgram),
    );
  }
}
