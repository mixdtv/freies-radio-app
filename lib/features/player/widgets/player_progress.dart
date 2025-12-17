import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:radiozeit/features/player/media_player.dart';
import 'package:radiozeit/features/player/player_cubit.dart';

class PlayerProgress extends StatelessWidget {
  const PlayerProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerCubitState>(
      builder: (context, playerState) {
        final bool isPodcastPlaying = playerState.currentPodcastEpisode != null;

        if (!isPodcastPlaying) {
          return const SizedBox.shrink();
        }

        final player = context.read<PlayerCubit>().player;
        return _PodcastProgressSlider(player: player);
      },
    );
  }
}

class _PodcastProgressSlider extends StatefulWidget {
  final MediaPlayer player;

  const _PodcastProgressSlider({required this.player});

  @override
  State<_PodcastProgressSlider> createState() => _PodcastProgressSliderState();
}

class _PodcastProgressSliderState extends State<_PodcastProgressSlider> {
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
      setState(() {
        _position = widget.player.position.value;
      });
    }
  }

  void _onDurationChanged() {
    if (mounted) {
      setState(() {
        _duration = widget.player.duration.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double maxValue = _duration > 0 ? _duration : 1;
    final double currentValue = (_isDragging ? _dragValue : _position).clamp(0.0, maxValue);

    return Slider(
      min: 0,
      max: maxValue,
      value: currentValue,
      onChangeStart: (value) {
        setState(() {
          _isDragging = true;
          _dragValue = value.clamp(0.0, maxValue);
        });
      },
      onChanged: (double value) {
        setState(() {
          _dragValue = value.clamp(0.0, maxValue);
        });
      },
      onChangeEnd: (double value) {
        final seekPosition = value.clamp(0.0, maxValue);
        widget.player.seek(Duration(milliseconds: (seekPosition * 1000).toInt()));
        setState(() {
          _isDragging = false;
          _position = seekPosition;
        });
      },
    );
  }
}
