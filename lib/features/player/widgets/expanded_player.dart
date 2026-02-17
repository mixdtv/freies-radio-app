import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:radiozeit/features/player/media_player.dart';
import 'package:radiozeit/features/player/player_cubit.dart';
import 'package:radiozeit/features/timeline/bloc/timeline_cubit.dart';

/// Full-screen expanded player view inspired by the DLF app.
///
/// Opens as a modal bottom sheet from the mini player.
/// Adapts to three content types:
///
/// **Live radio**: EPG-based progress (non-seekable), skip ±15s via HLS DVR buffer.
/// **Podcast**: Seekable position/duration progress, skip ±15s enabled.
/// **Archive**: Seekable position/duration progress, skip ±15s enabled.
class ExpandedPlayer extends StatelessWidget {
  const ExpandedPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerCubitState>(
      builder: (context, playerState) {
        return BlocBuilder<TimeLineCubit, TimeLineState>(
          builder: (context, timelineState) {
            final player = context.read<PlayerCubit>().player;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final textColor = isDark ? Colors.white : Colors.black;

            final isLive = playerState.isPlayingLive;
            final isPodcast = playerState.isPlayingPodcast;
            final isArchive = playerState.isPlayingArchive;

            return Container(
              height: MediaQuery.of(context).size.height * 0.92,
              decoration: BoxDecoration(
                color: isDark
                    ? Theme.of(context).colorScheme.surface
                    : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    // Drag handle
                    const SizedBox(height: 12),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: textColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Icon(Icons.keyboard_arrow_down,
                                size: 28, color: textColor),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sie hören',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Cover image
                    Expanded(
                      flex: 5,
                      child: _buildCoverImage(
                        context,
                        isLive: isLive,
                        isPodcast: isPodcast,
                        isArchive: isArchive,
                        playerState: playerState,
                        timelineState: timelineState,
                        textColor: textColor,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Content badge
                    _buildBadge(context, isLive, isPodcast, isArchive,
                        playerState, textColor),

                    const SizedBox(height: 16),

                    // Title
                    _buildTitle(context, isLive, isPodcast, isArchive,
                        playerState, timelineState),

                    // Subtitle
                    _buildSubtitle(context, isLive, isPodcast, isArchive,
                        playerState, timelineState, textColor),

                    const Spacer(flex: 2),

                    // Progress section
                    if (isLive)
                      _buildLiveProgress(
                          context, timelineState, isDark, textColor)
                    else
                      _SeekableProgressBar(
                          player: player,
                          isDark: isDark,
                          textColor: textColor),

                    if (isLive && timelineState.activeEpg.id.isEmpty)
                      const SizedBox(height: 48),

                    const SizedBox(height: 32),

                    // Transport controls
                    _TransportControls(
                      player: player,
                      isLive: isLive,
                      isDark: isDark,
                      textColor: textColor,
                    ),

                    const Spacer(flex: 2),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCoverImage(
    BuildContext context, {
    required bool isLive,
    required bool isPodcast,
    required bool isArchive,
    required PlayerCubitState playerState,
    required TimeLineState timelineState,
    required Color textColor,
  }) {
    String? imageUrl;

    if (isPodcast) {
      final url = playerState.currentPodcastEpisode!.imageUrl;
      if (url.isNotEmpty) imageUrl = url;
    } else if (isArchive) {
      final url = playerState.currentArchiveProgram!.icon;
      if (url.isNotEmpty) imageUrl = url;
    } else {
      final url = timelineState.activeEpg.icon;
      if (url.isNotEmpty) imageUrl = url;
    }

    // Fallback to radio logo
    imageUrl ??= playerState.selectedRadio?.thumbnail;

    if (imageUrl == null || imageUrl.isEmpty) {
      return Icon(Icons.radio, size: 80, color: textColor.withOpacity(0.15));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.radio, size: 80, color: textColor.withOpacity(0.15)),
        ),
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context,
    bool isLive,
    bool isPodcast,
    bool isArchive,
    PlayerCubitState playerState,
    Color textColor,
  ) {
    String label;
    IconData icon;

    if (isPodcast) {
      label = 'Podcast';
      icon = Icons.podcasts;
    } else if (isArchive) {
      final program = playerState.currentArchiveProgram!;
      label = 'Archiv · ${DateFormat('d. MMM').format(program.start)}';
      icon = Icons.history;
    } else {
      label = 'Live';
      icon = Icons.sensors;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor.withOpacity(0.7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: textColor.withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(
    BuildContext context,
    bool isLive,
    bool isPodcast,
    bool isArchive,
    PlayerCubitState playerState,
    TimeLineState timelineState,
  ) {
    String title;

    if (isPodcast) {
      title = playerState.currentPodcastEpisode!.title;
    } else if (isArchive) {
      title = playerState.currentArchiveProgram!.title;
    } else {
      final epg = timelineState.activeEpg;
      title = epg.id.isNotEmpty
          ? epg.title
          : (timelineState.activeRadio?.name ?? '');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineLarge,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSubtitle(
    BuildContext context,
    bool isLive,
    bool isPodcast,
    bool isArchive,
    PlayerCubitState playerState,
    TimeLineState timelineState,
    Color textColor,
  ) {
    String? subtitle;

    if (isPodcast) {
      final ep = playerState.currentPodcastEpisode!;
      subtitle = ep.pubDate != null
          ? DateFormat('MMM d, yyyy').format(ep.pubDate!)
          : ep.description;
    } else if (isArchive) {
      final prog = playerState.currentArchiveProgram!;
      final startTime = DateFormat('HH:mm').format(prog.start);
      final endTime = DateFormat('HH:mm').format(prog.end);
      subtitle = '$startTime – $endTime';
      if (prog.subheadline.isNotEmpty) {
        subtitle = '$subtitle · ${prog.subheadline}';
      }
    } else {
      final epg = timelineState.activeEpg;
      if (epg.id.isNotEmpty) {
        if (epg.subheadline.isNotEmpty) subtitle = epg.subheadline;
        if (epg.hosts.isNotEmpty) {
          final hosts = epg.hosts.join(', ');
          subtitle = subtitle != null ? '$subtitle\n$hosts' : hosts;
        }
      } else if (timelineState.activeRadio != null) {
        subtitle = timelineState.activeRadio!.tags.join(', ');
      }
    }

    if (subtitle == null || subtitle.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 32, top: 8),
      child: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: textColor.withOpacity(0.5),
            ),
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildLiveProgress(BuildContext context, TimeLineState timelineState,
      bool isDark, Color textColor) {
    final epg = timelineState.activeEpg;
    if (epg.id.isEmpty) return const SizedBox.shrink();

    final double clampedProgress =
        timelineState.progress.toDouble().clamp(0, 100);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // "Live" label aligned with progress
          Align(
            alignment: Alignment((clampedProgress / 50) - 1, 0),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Live',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textColor.withOpacity(0.7),
                      ),
                ),
              ),
            ),
          ),
          // Non-seekable slider
          IgnorePointer(
            child: SliderTheme(
              data: Theme.of(context).sliderTheme.copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    activeTrackColor: isDark ? Colors.white : Colors.black,
                    inactiveTrackColor: (isDark ? Colors.white : Colors.black)
                        .withOpacity(0.15),
                    thumbColor: isDark ? Colors.white : Colors.black,
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
              child: Slider(
                value: clampedProgress,
                min: 0,
                max: 100,
                onChanged: (_) {},
              ),
            ),
          ),
          // Time labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatEpgTime(epg.start),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textColor.withOpacity(0.5),
                      ),
                ),
                Text(
                  _formatEpgTime(epg.end),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textColor.withOpacity(0.5),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatEpgTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m Uhr';
  }
}

// ---------------------------------------------------------------------------
// Seekable progress bar for podcasts and archives
// ---------------------------------------------------------------------------

class _SeekableProgressBar extends StatefulWidget {
  final MediaPlayer player;
  final bool isDark;
  final Color textColor;

  const _SeekableProgressBar({
    required this.player,
    required this.isDark,
    required this.textColor,
  });

  @override
  State<_SeekableProgressBar> createState() => _SeekableProgressBarState();
}

class _SeekableProgressBarState extends State<_SeekableProgressBar> {
  double _position = 0;
  double _duration = 0;
  bool _isDragging = false;
  double _dragValue = 0;

  @override
  void initState() {
    super.initState();
    _position = widget.player.position.value;
    _duration = widget.player.duration.value;
    widget.player.position.addListener(_onPositionChanged);
    widget.player.duration.addListener(_onDurationChanged);
  }

  @override
  void dispose() {
    widget.player.position.removeListener(_onPositionChanged);
    widget.player.duration.removeListener(_onDurationChanged);
    super.dispose();
  }

  void _onPositionChanged() {
    if (mounted && !_isDragging) {
      setState(() => _position = widget.player.position.value);
    }
  }

  void _onDurationChanged() {
    if (mounted) {
      setState(() => _duration = widget.player.duration.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxValue = _duration > 0 ? _duration : 1.0;
    final currentValue =
        (_isDragging ? _dragValue : _position).clamp(0.0, maxValue);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          SliderTheme(
            data: Theme.of(context).sliderTheme.copyWith(
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  activeTrackColor:
                      widget.isDark ? Colors.white : Colors.black,
                  inactiveTrackColor:
                      (widget.isDark ? Colors.white : Colors.black)
                          .withOpacity(0.15),
                  thumbColor: widget.isDark ? Colors.white : Colors.black,
                  overlayShape: SliderComponentShape.noOverlay,
                ),
            child: Slider(
              value: currentValue,
              min: 0,
              max: maxValue,
              onChangeStart: (v) {
                setState(() {
                  _isDragging = true;
                  _dragValue = v.clamp(0.0, maxValue);
                });
              },
              onChanged: (v) {
                setState(() => _dragValue = v.clamp(0.0, maxValue));
              },
              onChangeEnd: (v) {
                final pos = v.clamp(0.0, maxValue);
                widget.player
                    .seek(Duration(milliseconds: (pos * 1000).toInt()));
                setState(() {
                  _isDragging = false;
                  _position = pos;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatSeconds(currentValue),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: widget.textColor.withOpacity(0.5),
                      ),
                ),
                Text(
                  _formatSeconds(maxValue),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: widget.textColor.withOpacity(0.5),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSeconds(double seconds) {
    final dur = Duration(seconds: seconds.toInt());
    if (dur.inHours > 0) {
      return '${dur.inHours}:${(dur.inMinutes % 60).toString().padLeft(2, '0')}:${(dur.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${dur.inMinutes}:${(dur.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}

// ---------------------------------------------------------------------------
// Transport controls (play/pause, skip, prev/next)
// ---------------------------------------------------------------------------

class _TransportControls extends StatefulWidget {
  final MediaPlayer player;
  final bool isLive;
  final bool isDark;
  final Color textColor;

  const _TransportControls({
    required this.player,
    required this.isLive,
    required this.isDark,
    required this.textColor,
  });

  @override
  State<_TransportControls> createState() => _TransportControlsState();
}

class _TransportControlsState extends State<_TransportControls> {
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

  void _onPlayPauseTap() {
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

  void _skipForward() {
    final newPos = widget.player.position.value + 15;
    final maxPos = widget.player.duration.value;
    final clamped = newPos > maxPos ? maxPos : newPos;
    widget.player.seek(Duration(milliseconds: (clamped * 1000).toInt()));
  }

  void _skipBackward() {
    final newPos = widget.player.position.value - 15;
    final clamped = newPos < 0 ? 0.0 : newPos;
    widget.player.seek(Duration(milliseconds: (clamped * 1000).toInt()));
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.textColor.withOpacity(0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Skip back 15s
          _SkipButton(
            seconds: 15,
            isForward: false,
            color: activeColor,
            onTap: _skipBackward,
          ),
          // Play / Pause / Loading
          GestureDetector(
            onTap: _isLoading ? null : _onPlayPauseTap,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isDark ? Colors.white : const Color(0xff1a1a2e),
              ),
              child: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(18),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
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
                      size: 36,
                    ),
            ),
          ),
          // Skip forward 15s
          _SkipButton(
            seconds: 15,
            isForward: true,
            color: activeColor,
            onTap: _skipForward,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom 15s skip button (Material Design lacks a 15s icon)
// ---------------------------------------------------------------------------

class _SkipButton extends StatelessWidget {
  final int seconds;
  final bool isForward;
  final Color color;
  final VoidCallback? onTap;

  const _SkipButton({
    required this.seconds,
    required this.isForward,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final arrow = Icon(Icons.replay, color: color, size: 32);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            isForward
                ? Transform.flip(flipX: true, child: arrow)
                : arrow,
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$seconds',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
