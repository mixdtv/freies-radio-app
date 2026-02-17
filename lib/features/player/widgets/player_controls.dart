import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:radiozeit/data/model/podcast.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/data/model/radio_program.dart';
import 'package:radiozeit/features/player/media_player.dart';
import 'package:radiozeit/features/player/player_cubit.dart';
import 'package:radiozeit/features/player/widgets/expanded_player.dart';
import 'package:radiozeit/features/timeline/bloc/timeline_cubit.dart';

/// Compact mini player bar displayed at the bottom of the app.
///
/// Shows: thin progress indicator + show/episode title + circular play button.
/// Tapping the text area opens the full-screen [ExpandedPlayer].
/// Adapts display and behavior to the current content type (live/podcast/archive).
class PlayerControls extends StatelessWidget {
  final RadioEpg activeProgram;
  final AppRadio? selectedRadio;
  final int progress;

  const PlayerControls({
    super.key,
    required this.activeProgram,
    this.selectedRadio,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerCubitState>(
      builder: (context, playerState) {
        final isLive = playerState.isPlayingLive;
        final isPodcast = playerState.isPlayingPodcast;
        final isArchive = playerState.isPlayingArchive;
        final player = context.read<PlayerCubit>().player;

        bool isDark = Theme.of(context).brightness == Brightness.dark;
        TextTheme textTheme = Theme.of(context).textTheme;

        return SizedBox(
          height: 60,
          child: Column(
            children: [
              // Thin progress indicator at top
              _buildProgressBar(context, player, isLive, isArchive, isDark,
                  archiveProgram: isArchive ? playerState.currentArchiveProgram : null),
              // Content row
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Tappable area -> opens expanded player
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openExpandedPlayer(context),
                          child: Row(
                            children: [
                              Icon(
                                Icons.keyboard_arrow_up,
                                size: 24,
                                color: isDark
                                    ? Colors.white.withOpacity(0.4)
                                    : Colors.black.withOpacity(0.4),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: isArchive
                                    ? _buildArchiveText(
                                        playerState.currentArchiveProgram!,
                                        textTheme)
                                    : isPodcast
                                        ? _buildPodcastText(
                                            playerState.currentPodcastEpisode!,
                                            textTheme)
                                        : _buildLiveText(textTheme),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Play/Pause circular button
                      _MiniPlayButton(
                        player: player,
                        isLive: isLive,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(
      BuildContext context, MediaPlayer player, bool isLive, bool isArchive, bool isDark,
      {RadioEpg? archiveProgram}) {
    if (isLive) {
      return LinearProgressIndicator(
        value: progress / 100,
        minHeight: 2,
        backgroundColor: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.08),
        valueColor: AlwaysStoppedAnimation(
          isDark
              ? Colors.white.withOpacity(0.5)
              : Colors.black.withOpacity(0.5),
        ),
      );
    }

    // For archive: use EPG program duration instead of raw audio duration
    final double? programDuration = isArchive && archiveProgram != null
        ? archiveProgram.end.difference(archiveProgram.start).inSeconds.toDouble()
        : null;

    // Podcast / Archive: listen to position and duration
    return ValueListenableBuilder<double>(
      valueListenable: player.position,
      builder: (ctx, pos, _) {
        return ValueListenableBuilder<double>(
          valueListenable: player.duration,
          builder: (ctx, dur, _) {
            final effectiveDur = programDuration ?? dur;
            final value = effectiveDur > 0 ? (pos / effectiveDur).clamp(0.0, 1.0) : 0.0;
            return LinearProgressIndicator(
              value: value,
              minHeight: 2,
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation(
                isDark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.black.withOpacity(0.5),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLiveText(TextTheme textTheme) {
    final hasEpg = activeProgram.id.isNotEmpty;
    final subtitle = hasEpg ? activeProgram.subheadline : 'Live';
    final title = hasEpg ? activeProgram.title : (selectedRadio?.name ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(
              color: textTheme.bodySmall?.color?.withOpacity(0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 2),
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPodcastText(PodcastEpisode episode, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Podcast',
          style: textTheme.bodySmall?.copyWith(
            color: textTheme.bodySmall?.color?.withOpacity(0.6),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          episode.title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildArchiveText(RadioEpg program, TextTheme textTheme) {
    final dateStr = DateFormat('d. MMM').format(program.start);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Archiv · $dateStr',
          style: textTheme.bodySmall?.copyWith(
            color: textTheme.bodySmall?.color?.withOpacity(0.6),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          program.title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _openExpandedPlayer(BuildContext context) {
    final playerCubit = context.read<PlayerCubit>();
    final timelineCubit = context.read<TimeLineCubit>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: playerCubit),
            BlocProvider.value(value: timelineCubit),
          ],
          child: const ExpandedPlayer(),
        );
      },
    );
  }
}

/// Compact circular play/pause button for the mini player.
/// Handles loading, playing, and stopped states with correct
/// stop vs pause behavior per content type.
class _MiniPlayButton extends StatefulWidget {
  final MediaPlayer player;
  final bool isLive;
  final bool isDark;

  const _MiniPlayButton({
    required this.player,
    required this.isLive,
    required this.isDark,
  });

  @override
  State<_MiniPlayButton> createState() => _MiniPlayButtonState();
}

class _MiniPlayButtonState extends State<_MiniPlayButton> {
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
    if (mounted) setState(() => _isPlaying = widget.player.isPlaying.value);
  }

  void _onLoadingChanged() {
    if (mounted) setState(() => _isLoading = widget.player.isLoading.value);
  }

  void _onTap() {
    if (_isPlaying) {
      if (widget.isLive) {
        widget.player.stop();
      } else {
        widget.player.pause();
      }
    } else {
      if (!widget.isLive && widget.player.isPause()) {
        widget.player.resume();
      } else {
        widget.player.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isDark ? Colors.white : Colors.black,
        ),
        child: _isLoading
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    widget.isDark ? Colors.black : Colors.white,
                  ),
                ),
              )
            : Icon(
                _isPlaying
                    ? (widget.isLive ? Icons.stop : Icons.pause)
                    : Icons.play_arrow,
                color: widget.isDark ? Colors.black : Colors.white,
                size: 22,
              ),
      ),
    );
  }
}
