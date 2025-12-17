import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:radiozeit/app/bottom_navigation/bottom_navigation_cubit.dart';
import 'package:radiozeit/app/widgets/shimmer.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/data/model/transcript_chunk.dart';
import 'package:radiozeit/data/model/transcript_chunk_line.dart';
import 'package:radiozeit/data/model/transcript_chunk_word.dart';
import 'package:radiozeit/features/player/media_player.dart';
import 'package:radiozeit/features/player/player_cubit.dart';
import 'package:radiozeit/features/radio_list/radio_list_page.dart';
import 'package:radiozeit/features/transcript/bloc/transcript_cubit.dart';
import 'package:radiozeit/features/transcript/dialogs/transcript_settings.dart';
import 'package:radiozeit/features/transcript/widgets/transcript_list.dart';
import 'package:radiozeit/utils/colors.dart';
import 'package:radiozeit/l10n/app_localizations.dart';


class RadioTranscriptPage extends StatefulWidget {
  static const String path = "/RadioTranscriptPage";

  const RadioTranscriptPage({super.key});

  @override
  State<RadioTranscriptPage> createState() => _RadioTranscriptPageState();
}

class _RadioTranscriptPageState extends State<RadioTranscriptPage> {
  late TranscriptCubit pageCubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pageCubit = context.read<TranscriptCubit>();
      PlayerCubit playerCubit = context.read<PlayerCubit>();
      AppRadio? radio = playerCubit.state.selectedRadio;

      print("init page Slug $radio");
      if(radio != null) {
        pageCubit.startTranscript(
              slug: radio.prefix,
              langCode: radio.lang
            );
      }
    });
  }

  @override
  void dispose() {
    pageCubit.stopProgressUpdate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _appBar(),
        // ValueListenableBuilder(
        //   valueListenable:  context.read<PlayerCubit>().player.position,
        //   builder: (context, value, child) => Text("Player progress ${value}s ")
        // ),

        Builder(
          builder: (context) {


            bool isLangChanging = context.select((TranscriptCubit bloc) => bloc.state.isLangChanging);
            bool isNotLoaded = context.select((TranscriptCubit bloc) => bloc.state.isNotLoaded);
            List<TranscriptChunkLine> list = context.select((TranscriptCubit bloc) => bloc.state.list);
            List<TranscriptChunkWord> wordList = context.select((TranscriptCubit bloc) => bloc.state.wordList);
            TranscriptFontSize fontSize = context.select((TranscriptCubit bloc) => bloc.state.fontSize);
            double progressMs = context.select((TranscriptCubit bloc) => bloc.state.progressMs);

            if(isLangChanging) {
              return Center(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: AppColors.orange,),
                    ),
                    Opacity(
                        opacity: 0.3,
                        child: Text(AppLocalizations.of(context)!.transcript_preparing,style: Theme.of(context).textTheme.headlineMedium,)),
                  ],
                ),
              );
            }
            if(isNotLoaded) {
              return Center(
                child: Opacity(
                    opacity: 0.3,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(AppLocalizations.of(context)!.transcript_not_work,style: Theme.of(context).textTheme.headlineMedium,),
                    )),
              );
            }
            if (list.isEmpty) {
              return const SizedBox();
            }

            return  Expanded(
              child: Stack(
                children: [
                  TranscriptList(
                      isDark: isDark,
                      lines: list,
                      chunks: wordList,
                      progressMs: progressMs,
                      fontSize: fontSize
                  ),
                ],
              ),
            );

          },
        )
      ],
      ),
    );
  }

  _appBar() {
    TextTheme textTheme = Theme
        .of(context)
        .textTheme;

    return Container(
        padding: EdgeInsets.only(bottom: 12, top: 5),
        decoration: BoxDecoration(
            gradient: AppGradient.getPanelGradient(context)
        ),
        child: SafeArea(child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BackButton(onPressed: () {
              context.read<BottomNavigationCubit>().openMenu(false);
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(RadioListPage.path);
              }
            },),
            InkWell(
              onTap: _showSettings,
              child: Column(
                children: [
                  Builder(
                      builder: (context) {
                        String radioName = context.select((PlayerCubit cubit) => cubit.state.selectedRadio?.name ?? "");
                        return Text(radioName, style: textTheme.displayLarge,);
                      }
                  ),
                  Builder(builder: (context) {
                    String? radioLang = context.select((TranscriptCubit bloc) => bloc.state.radioLang?.title);
                    String? selectedLang = context.select((TranscriptCubit bloc) => bloc.state.selectedLang?.title);
                    double speed = context.select((TranscriptCubit bloc) => bloc.state.speed.speed);

                    if(radioLang == null) return SizedBox();

                    return Text("${radioLang} > ${selectedLang ?? ""} (${speed}x)",
                      style: textTheme.bodyLarge?.copyWith(
                          color: textTheme.bodyLarge?.color?.withOpacity(0.6)),);

                  },),
                ],
              ),
            ),
            SizedBox(width: 46,)
          ],
        )));
  }

  _showSettings() {
    var cubit = context.read<TranscriptCubit>();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))
      ),
      builder: (context) {
        return SizedBox(
          height: 510,
          child: BlocProvider.value(
            value: cubit,
            child: const TranscriptSettings(),
          ),
        );
      },
    );
  }

  _loading(double width) {
    return Shimmer(
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(14, (index) {
            double max = Random(index).nextDouble() + 0.5;
            if (max > 1) max = 1;
            return Container(
              height: 24,
              width: width * max,
              margin: const EdgeInsets.only(bottom: 12, left: 10, right: 10),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white
              ),
            );
          }),
        ),
      ),
    );
  }
}
