import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:radiozeit/app/bottom_navigation/bottom_navigation_cubit.dart';
import 'package:radiozeit/app/bottom_navigation/menu_config.dart';
import 'package:radiozeit/app/style.dart';
import 'package:radiozeit/data/model/podcast.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/data/model/radio_program.dart';
import 'package:radiozeit/features/player/media_player.dart';
import 'package:radiozeit/features/player/player_cubit.dart';
import 'package:radiozeit/features/player/widgets/play_button.dart';
import 'package:radiozeit/features/radio_list/radio_list_page.dart';
import 'package:radiozeit/features/transcript/radio_transcript_page.dart';
import 'package:radiozeit/utils/colors.dart';

class PlayerControls extends StatelessWidget {
  final RadioEpg activeProgram;
  final AppRadio? selectedRadio;

  const PlayerControls({super.key, required this.activeProgram, this.selectedRadio});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerCubitState>(
      builder: (context, playerState) {
        final podcastEpisode = playerState.currentPodcastEpisode;
        final archiveProgram = playerState.currentArchiveProgram;
        final bool isPodcastPlaying = podcastEpisode != null;
        final bool isArchivePlaying = archiveProgram != null;

        TextTheme textTheme = Theme.of(context).textTheme;
        bool isDark = Theme.of(context).brightness == Brightness.dark;
        MediaPlayer player = context.read<PlayerCubit>().player;

        return Container(
          height: 122,
          child: Stack(
            children: [
              Positioned(
                left: 16,
                right: isDark ? 100 : 104,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () {
                    if(selectedRadio != null && !isPodcastPlaying && !isArchivePlaying) {
                      if(GoRouterState.of(context).fullPath == RadioListPage.path) {
                        context.read<BottomNavigationCubit>().openMenu(true);
                        context.push(MenuConfig.getDefaultPagePath());
                      } else {
                        context.replace(MenuConfig.getDefaultPagePath());
                        context.read<BottomNavigationCubit>().toPage(MenuConfig.getDefaultPageIndex());
                      }
                    }
                  },
                  child: isArchivePlaying
                    ? _buildArchiveInfo(context, archiveProgram, textTheme, isDark)
                    : isPodcastPlaying
                      ? _buildPodcastInfo(context, podcastEpisode, textTheme, isDark)
                      : _buildRadioInfo(context, activeProgram, selectedRadio, textTheme, isDark),
                ),
              ),
              Positioned(
                  top: 0,
                  right: 0,
                  child: _PlayButtonWrapper(
                    player: player,
                    isPodcast: isPodcastPlaying,
                    isArchive: isArchivePlaying,
                  )
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildRadioInfo(BuildContext context, RadioEpg activeProgram, AppRadio? selectedRadio, TextTheme textTheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(activeProgram.id.isNotEmpty ? activeProgram.subheadline :"Live",
            style: textTheme.bodyLarge?.copyWith(
                fontFamily: isDark ? AppStyle.fontInter : AppStyle.fontDMMono,
                color: textTheme.bodyLarge?.color?.withOpacity(0.6))
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(activeProgram.id.isNotEmpty ? activeProgram.title : selectedRadio?.name ?? "",style: textTheme.titleLarge,),
        ),
        Text(activeProgram.id.isNotEmpty ? activeProgram.hosts.join(" ") : selectedRadio?.tags.join(", ") ?? "",
            maxLines: 2,
            style: textTheme.bodyLarge?.copyWith(
                fontFamily: isDark ? AppStyle.fontInter : AppStyle.fontDMMono,
                color: textTheme.bodyLarge?.color?.withOpacity(0.6))
        ),
      ],
    );
  }

  Widget _buildPodcastInfo(BuildContext context, PodcastEpisode episode, TextTheme textTheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Podcast",
            style: textTheme.bodyLarge?.copyWith(
                fontFamily: isDark ? AppStyle.fontInter : AppStyle.fontDMMono,
                color: textTheme.bodyLarge?.color?.withOpacity(0.6))
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            episode.title,
            style: textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          episode.pubDate != null
            ? DateFormat('MMM d, yyyy').format(episode.pubDate!)
            : episode.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyLarge?.copyWith(
              fontFamily: isDark ? AppStyle.fontInter : AppStyle.fontDMMono,
              color: textTheme.bodyLarge?.color?.withOpacity(0.6))
        ),
      ],
    );
  }

  Widget _buildArchiveInfo(BuildContext context, RadioEpg program, TextTheme textTheme, bool isDark) {
    // Format the time range for display
    final startTime = DateFormat('HH:mm').format(program.start);
    final endTime = DateFormat('HH:mm').format(program.end);
    final dateStr = DateFormat('d. MMM').format(program.start);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Archiv · $dateStr",
            style: textTheme.bodyLarge?.copyWith(
                fontFamily: isDark ? AppStyle.fontInter : AppStyle.fontDMMono,
                color: textTheme.bodyLarge?.color?.withOpacity(0.6))
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            program.title,
            style: textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          "$startTime – $endTime · ${program.subheadline}",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyLarge?.copyWith(
              fontFamily: isDark ? AppStyle.fontInter : AppStyle.fontDMMono,
              color: textTheme.bodyLarge?.color?.withOpacity(0.6))
        ),
      ],
    );
  }
}

class _PlayButtonWrapper extends StatefulWidget {
  final MediaPlayer player;
  final bool isPodcast;
  final bool isArchive;

  const _PlayButtonWrapper({
    required this.player,
    required this.isPodcast,
    this.isArchive = false,
  });

  @override
  State<_PlayButtonWrapper> createState() => _PlayButtonWrapperState();
}

class _PlayButtonWrapperState extends State<_PlayButtonWrapper> {
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.player.isPlaying.value;
    _isLoading = widget.player.isLoading.value;
    widget.player.isPlaying.addListener(_onPlayingChanged);
    widget.player.isLoading.addListener(_onLoadingChanged);
  }

  @override
  void dispose() {
    widget.player.isPlaying.removeListener(_onPlayingChanged);
    widget.player.isLoading.removeListener(_onLoadingChanged);
    super.dispose();
  }

  void _onPlayingChanged() {
    if (mounted) {
      setState(() {
        _isPlaying = widget.player.isPlaying.value;
      });
    }
  }

  void _onLoadingChanged() {
    if (mounted) {
      setState(() {
        _isLoading = widget.player.isLoading.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Archive and podcast both use pause/resume, live radio uses stop
    final bool usesPauseResume = widget.isPodcast || widget.isArchive;

    return PlayButton(
      onClick: () {
        print("player.isPlaying.value ${widget.player.isPlaying.value}, isPodcast: ${widget.isPodcast}, isArchive: ${widget.isArchive}");
        if (widget.player.isPlaying.value) {
          if (usesPauseResume) {
            widget.player.pause();
          } else {
            widget.player.stop();
          }
        } else {
          if (usesPauseResume && widget.player.isPause()) {
            widget.player.resume();
          } else {
            widget.player.play();
          }
        }
      },
      isPlay: _isPlaying,
      isLoading: _isLoading,
      isPodcast: usesPauseResume,
    );
  }
}
