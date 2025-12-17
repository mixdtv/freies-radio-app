import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:radiozeit/app/bottom_navigation/bottom_navigation_cubit.dart';
import 'package:radiozeit/data/model/visual_chunk.dart';
import 'package:radiozeit/features/player/media_player.dart';
import 'package:radiozeit/features/player/player_cubit.dart';
import 'package:radiozeit/features/visual/linear_visual.dart';
import 'package:radiozeit/features/visual/visual_cubit.dart';
import 'package:radiozeit/features/visual/visual_helper.dart';
import 'package:radiozeit/utils/colors.dart';
import 'package:radiozeit/utils/extensions.dart';

class RadioVisualPage extends StatefulWidget {
  static const String path = "/RadioVisualPage";

  const RadioVisualPage({super.key});

  @override
  State<RadioVisualPage> createState() => _RadioVisualPageState();
}

class _RadioVisualPageState extends State<RadioVisualPage> {
  ValueNotifier<VisualChunk?> activeChunk = ValueNotifier(null);
  List<VisualChunk> chunks = [];
  late MediaPlayer player;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var playerCubit = context.read<PlayerCubit>();
      player = context.read<PlayerCubit>().player;
      chunks = context.read<RadioVisualCubit>().state.chunks;
      player.position.addListener(_updateCurrentChunk);
      _updateCurrentChunk();

      String? slug = playerCubit.state.selectedRadio?.prefix;

      print("init page Slug $slug");
      if (slug != null) {
        context.read<RadioVisualCubit>().start(slug);
      }
    });
  }

  @override
  void dispose() {
    player.position.removeListener(_updateCurrentChunk);
    super.dispose();
  }

  _updateCurrentChunk() {
    double progressMs = VisualHelper.getPlayerProgress(player.position.value);

    if (activeChunk.value == null || activeChunk.value?.isCurrent(progressMs) == false) {
      var chunk = chunks.firstOrNullWhere((e) {
        var status = e.isCurrent(progressMs);

        return status;
      });
      //  print("progressMs $progressMs ");
      //   if(chunk == null) {
      //     print("NOT FOUND !!!!!!! startTime ${chunks.lastOrNull?.startTime} endTime${chunks.lastOrNull?.endTime}");
      //   }
      //  print("activeChunk ${chunk?.id}");
      activeChunk.value = chunk;
    } else {
      // print("playold progressMs $progressMs ${progressMs / 5} ${activeChunk.value}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RadioVisualCubit, RadioVisualState>(
      listener: (context, state) {
        chunks = state.chunks;
        _updateCurrentChunk();
      },
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Container(
                decoration: BoxDecoration(gradient: AppGradient.getPanelGradient(context)),
              child: SafeArea(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BackButton(
                    onPressed: () {
                      context.read<BottomNavigationCubit>().openMenu(false);
                      context.pop();
                    },
                  ),
                  Builder(builder: (context) {
                    String radioName = context.select((PlayerCubit cubit) => cubit.state.selectedRadio?.name ?? "");
                    return Text(
                      radioName,
                      style: Theme.of(context).textTheme.displayLarge,
                    );
                  }),
                  SizedBox(
                    width: 46,
                  )
                ],
              ))),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: activeChunk,
              builder: (context, value, child) {
                return Container(
                  // color: value == null ? Colors.red : Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: LinearVisual(chunk: value),
                );
              },
            ),
          )
        ],
        ),
      ),
    );
  }
}
