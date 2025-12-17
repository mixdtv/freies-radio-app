
import 'package:audio_service/audio_service.dart';
import 'package:bloc/bloc.dart';
import 'package:radiozeit/data/model/podcast.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/data/model/radio_program.dart';
import 'package:radiozeit/features/player/media_player.dart';
import 'package:radiozeit/utils/settings.dart';

class PlayerCubit extends Cubit<PlayerCubitState> {
  MediaPlayer player;
  AppSettings settings = AppSettings.getInstance();
  PlayerCubit(this.player) : super(PlayerCubitState());


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

  /// Switch to live radio stream, even if a podcast from the same station is playing
  switchToLiveRadio() {
    final radio = state.selectedRadio;
    if (radio == null) return;

    // If already playing live radio (no podcast), do nothing
    if (state.currentPodcastEpisode == null) return;

    _playLiveRadio(radio);
  }

  _playLiveRadio(AppRadio radio) {
    settings.setLastRadio(radio.id);
    emit(state.copyWith(
      selectedRadio: radio,
      currentPodcastEpisode: null,
      clearPodcast: true,
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

  playProgram(RadioEpg program) {
    emit(state.copyWith(currentProgram: program));

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

  PlayerCubitState({
    this.selectedRadio,
    this.currentPodcastEpisode,
  });

  PlayerCubitState copyWith({
    AppRadio? selectedRadio,
    RadioEpg? currentProgram,
    PodcastEpisode? currentPodcastEpisode,
    bool clearPodcast = false,
  }) {
    return PlayerCubitState(
      selectedRadio: selectedRadio ?? this.selectedRadio,
      currentPodcastEpisode: clearPodcast ? null : (currentPodcastEpisode ?? this.currentPodcastEpisode),
    );
  }
}
