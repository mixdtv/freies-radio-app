import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:radiozeit/app/bottom_navigation/bottom_navigation_cubit.dart';
import 'package:radiozeit/app/style.dart';
import 'package:radiozeit/config/app_config.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/data/model/radio_program.dart';
import 'package:radiozeit/features/player/player_cubit.dart';
import 'package:radiozeit/features/player/widgets/player_controls.dart';
import 'package:radiozeit/features/player/widgets/player_progress.dart';
import 'package:radiozeit/features/podcast/podcast_episodes_page.dart';
import 'package:radiozeit/features/podcast/podcast_list_page.dart';
import 'package:radiozeit/features/radio_about/radio_about_page.dart';
import 'package:radiozeit/features/timeline/bloc/timeline_cubit.dart';
import 'package:radiozeit/features/timeline/radio_timeline_page.dart';
import 'package:radiozeit/features/transcript/radio_transcript_page.dart';
import 'package:radiozeit/features/visual/radio_visual_page.dart';
import 'package:radiozeit/utils/adaptive/form_factor.dart';
import 'package:radiozeit/utils/adaptive/screen_type.dart';
import 'package:radiozeit/utils/colors.dart';
import 'package:radiozeit/l10n/app_localizations.dart';

class AppMenuBottom extends StatelessWidget {
  const AppMenuBottom({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      bool isShow = context.select((BottomNavigationCubit cubit) => cubit.state.isActive);
      bool isRadioSelected = context.select((PlayerCubit cubit) => cubit.state.selectedRadio != null);
      if(!isRadioSelected) return SizedBox();

      return SizedBox(
        height: isShow ? 122 + 4 + 49 : 122 + 4 + 6,
        child: Stack(
          fit: StackFit.loose,
          children: [
            Container(
                decoration: BoxDecoration(
                    gradient: AppGradient.getPanelGradient(context)
                ),
                margin: const EdgeInsets.only(top: 4),
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),

                      child: isShow ? _menu() : const SizedBox(height: 6,)
                    ),
                    BlocBuilder<TimeLineCubit, TimeLineState>(
                      builder: (context, state) {
                        return PlayerControls(
                          activeProgram: state.activeEpg ,
                          selectedRadio: state.activeRadio,
                        );
                      },
                    ),
                  ],
                )),
            Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: PlayerProgress())
          ],
        ),
      );
    }
        );
  }

  _menu() {
    return Builder(
      builder: (context) {
        int page = context.select((BottomNavigationCubit cubit) => cubit.state.page);
        AppRadio? selectedRadio = context.select((TimeLineCubit cubit) => cubit.state.activeRadio);
        bool hasPodcasts = selectedRadio?.podcasts != null && selectedRadio!.podcasts!.isNotEmpty;

        // Define all available menu items
        final allMenuItems = {
          'transcript': {'index': 0, 'getName': (AppLocalizations loc) => loc.transcript},
          'timeline': {'index': 1, 'getName': (AppLocalizations loc) => loc.timeline},
          'podcasts': {'index': 2, 'getName': (AppLocalizations loc) => 'Podcasts'},
          'visual': {'index': 3, 'getName': (AppLocalizations loc) => loc.visual},
          'about': {'index': 4, 'getName': (AppLocalizations loc) => loc.about},
        };

        // Filter menu items: hide 'podcasts' if station has none
        final visibleItems = AppConfig.visibleMenuItems
            .where((item) => allMenuItems.containsKey(item))
            .where((item) => item != 'podcasts' || hasPodcasts)
            .map((item) => {
                  'key': item,
                  'index': allMenuItems[item]!['index'] as int,
                  'getName': allMenuItems[item]!['getName'] as String Function(AppLocalizations),
                })
            .toList();

        double maxWidth = ScreenType.getFormFactor(context) == ScreenType.big ? 350 : MediaQuery.of(context).size.shortestSide;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.only(top: 14,left: 16,right: 16),
              width: maxWidth,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  for (var i = 0; i < visibleItems.length; i++) ...[
                    _menuTab(
                      context: context,
                      index: visibleItems[i]['index'] as int,
                      currentIndex: page,
                      name: (visibleItems[i]['getName'] as String Function(AppLocalizations))(AppLocalizations.of(context)!),
                    ),
                    if (i < visibleItems.length - 1) const SizedBox(width: 24),
                  ],
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  _menuTab({
    required BuildContext context,
    required int index,
    required int currentIndex,
    required String name
  }) {
    TextStyle? textStyle;
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    if(index == currentIndex) {
      textStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          height: 1,
          fontFamily: isDark ? AppStyle.fontInter : AppStyle.fontDMMono,
          fontWeight: isDark ? FontWeight.w600 : FontWeight.w500);
    } else {
      textStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          height: 1,
          fontFamily: isDark ? AppStyle.fontInter : AppStyle.fontDMMono,
          color: Theme.of(context).textTheme.titleSmall?.color?.withOpacity(0.3),
          fontWeight: isDark ? FontWeight.w600 : FontWeight.w500);
    }



    return InkWell(
      onTap: () => _onMenuSelect(context,index),
      child: Padding(
        padding: const EdgeInsets.only(top: 8,bottom: 16),
        child: Text(name.toUpperCase(),style: textStyle,),
      ),
    );
  }

  _onMenuSelect(BuildContext context, int page) {
    context.read<BottomNavigationCubit>().toPage(page);
    switch (page) {
      case 0:
        context.replace(RadioTranscriptPage.path);
      case 1:
        context.replace(RadioTimeLinePage.path);
      case 2:
        // Navigate directly to podcast detail if there's only one podcast
        final selectedRadio = context.read<TimeLineCubit>().state.activeRadio;
        if (selectedRadio?.podcasts?.length == 1) {
          context.replace(PodcastEpisodesPage.path);
        } else {
          context.replace(PodcastListPage.path);
        }
      case 3:
        context.replace(RadioVisualPage.path);
      case 4:
        context.replace(RadioAboutPage.path);
    }
  }
}
