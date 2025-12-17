import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:radiozeit/app/app_page.dart';
import 'package:radiozeit/app/app_scope.dart';
import 'package:radiozeit/app/pages/appearance_page.dart';
import 'package:radiozeit/data/model/podcast.dart';
import 'package:radiozeit/features/auth/splash_page.dart';
import 'package:radiozeit/features/location/location_request_page.dart';
import 'package:radiozeit/features/location/model/location_city.dart';
import 'package:radiozeit/features/player/player_cubit.dart';
import 'package:radiozeit/features/podcast/podcast_episodes_page.dart';
import 'package:radiozeit/features/podcast/podcast_list_page.dart';
import 'package:radiozeit/features/radio_about/radio_about_page.dart';
import 'package:radiozeit/features/radio_list/cubit/radio_list_city_cubit.dart';
import 'package:radiozeit/features/radio_list/cubit/radio_list_search_cubit.dart';
import 'package:radiozeit/features/radio_list/page_radio_list_city.dart';
import 'package:radiozeit/features/radio_list/radio_list_page.dart';
import 'package:radiozeit/features/radio_list/radio_list_search_page.dart';
import 'package:radiozeit/features/timeline/radio_timeline_page.dart';
import 'package:radiozeit/features/transcript/radio_transcript_page.dart';
import 'package:radiozeit/features/visual/radio_visual_page.dart';
import 'package:radiozeit/features/visual/visual_cubit.dart';


class AppNavigation {

  static GoRouter initAppRouter({
    required String initPage
  }) {
      return GoRouter(

          initialLocation: initPage,

          routes: <RouteBase>[
            GoRoute(
              path: SplashPage.path,
              builder: (BuildContext context, GoRouterState state) {
                return  const SplashPage();
              },
            ),
            GoRoute(
              path: LocationRequestPage.path,
              builder: (BuildContext context, GoRouterState state) {
                return  const LocationRequestPage();
              },
            ),

            // App Scope ShellRoute
            ShellRoute(
              builder: (context, state, child) {
                return AppScope(child: child);
              },
                routes: [


              GoRoute(
                path: AppearancePage.path,
                builder: (BuildContext context, GoRouterState state) {
                  return  const AppearancePage();
                },
              ),

                  GoRoute(
                path: RadioSearchPage.path,
                builder: (BuildContext context, GoRouterState state) {
                  return  BlocProvider(
                      create: (context) => RadioListSearchCubit(),
                      child: const RadioSearchPage());
                },
              ),GoRoute(
                path: PageRadioListCity.path,
                builder: (BuildContext context, GoRouterState state) {
                  return  BlocProvider(
                      create: (context) => RadioListCityCubit(state.extra as LocationCity),
                      child: const PageRadioListCity());
                },
              ),

                  GoRoute(
                    path: RadioListPage.path,
                    builder: (BuildContext context, GoRouterState state) {
                      return  const AppPage(child: RadioListPage());
                    },
                  ),

              ShellRoute(
                  pageBuilder: (context, state, child) {
                    return CupertinoPage(
                        // key: state.pageKey,
                        // restorationId: state.pageKey.value,
                        child: AppPage(child: child)
                    );
                  },
                  routes: [
                    GoRoute(
                      path: RadioAboutPage.path,
                      builder: (BuildContext context, GoRouterState state) {
                        return  const RadioAboutPage();
                      },
                    ),GoRoute(
                      path: RadioTimeLinePage.path,
                      builder: (BuildContext context, GoRouterState state) {
                        return  const RadioTimeLinePage();
                      },
                    ),GoRoute(
                      path: RadioTranscriptPage.path,
                      builder: (BuildContext context, GoRouterState state) {
                        return  const RadioTranscriptPage();

                      },
                    ),GoRoute(
                      path: RadioVisualPage.path,
                      builder: (BuildContext context, GoRouterState state) {
                        return  BlocProvider(
                            create: (context) => RadioVisualCubit(context.read<PlayerCubit>().player),
                            child: const RadioVisualPage());
                      },
                    ),GoRoute(
                      path: PodcastListPage.path,
                      builder: (BuildContext context, GoRouterState state) {
                        return const PodcastListPage();
                      },
                    ),GoRoute(
                      path: PodcastEpisodesPage.path,
                      builder: (BuildContext context, GoRouterState state) {
                        final podcast = state.extra as Podcast?;
                        return PodcastEpisodesPage(podcast: podcast);
                      },
                    ),

                  ]),
            ])

          ]);
  }


}
