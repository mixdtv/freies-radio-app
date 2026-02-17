import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:radiozeit/app/bottom_navigation/bottom_navigation_cubit.dart';
import 'package:radiozeit/features/player/player_cubit.dart';
import 'package:radiozeit/features/podcast/bloc/podcast_cubit.dart';
import 'package:radiozeit/features/radio_list/cubit/radio_list_cubit.dart';
import 'package:radiozeit/features/timeline/bloc/timeline_cubit.dart';
import 'package:radiozeit/features/timeline/radio_timeline_page.dart';

/// Handles deep links like freiesradio:///show/{stationPrefix}.
///
/// Waits for the radio list to load, finds the matching station,
/// selects it, and navigates to the timeline page.
class DeepLinkPage extends StatefulWidget {
  static const String path = '/show/:stationPrefix';

  final String stationPrefix;

  const DeepLinkPage({super.key, required this.stationPrefix});

  @override
  State<DeepLinkPage> createState() => _DeepLinkPageState();
}

class _DeepLinkPageState extends State<DeepLinkPage> {
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryNavigate();
    });
  }

  void _tryNavigate() {
    if (_handled || !mounted) return;

    final radioListCubit = context.read<RadioListCubit>();
    final radioList = radioListCubit.state.radioList;

    if (radioList.isEmpty) {
      // List not loaded yet — ensure loading is triggered and wait
      if (!radioListCubit.state.isLoading) {
        radioListCubit.startLoadRadio();
      }
      return;
    }

    final radio = radioList.cast().firstWhere(
      (r) => r.prefix == widget.stationPrefix || r.id == widget.stationPrefix,
      orElse: () => null,
    );

    if (radio == null) {
      // Station not found — go to radio list
      context.go('/RadioListPage');
      return;
    }

    _handled = true;
    context.read<BottomNavigationCubit>().openMenu(true);
    context.read<PlayerCubit>().selectRadio(radio);
    context.read<TimeLineCubit>().selectRadio(radio);
    if (radio.podcasts != null && radio.podcasts!.isNotEmpty) {
      context.read<PodcastCubit>().preloadPodcasts(radio.podcasts!, radioName: radio.name);
    }
    context.go(RadioTimeLinePage.path);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RadioListCubit, RadioListState>(
      listenWhen: (prev, curr) =>
          prev.radioList.length != curr.radioList.length ||
          prev.isLoading != curr.isLoading,
      listener: (context, state) => _tryNavigate(),
      child: const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
