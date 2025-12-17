

import 'dart:async';

import 'package:bloc_presentation/bloc_presentation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:radiozeit/app/bottom_navigation/bottom_navigation_cubit.dart';
import 'package:radiozeit/app/bottom_navigation/menu_config.dart';
import 'package:radiozeit/data/api/repository.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/data/model/radio_program.dart';
import 'package:radiozeit/features/location/location_service.dart';
import 'package:radiozeit/features/location/model/city.dart';
import 'package:radiozeit/features/location/widgets/location_panel.dart';
import 'package:radiozeit/features/player/player_cubit.dart';
import 'package:radiozeit/features/radio_list/cubit/radio_favorite_cubit.dart';
import 'package:radiozeit/features/radio_list/cubit/radio_list_cubit.dart';
import 'package:radiozeit/features/radio_list/radio_list.dart';
import 'package:radiozeit/features/podcast/bloc/podcast_cubit.dart';
import 'package:radiozeit/features/radio_list/radio_list_big.dart';
import 'package:radiozeit/features/radio_list/radio_list_item.dart';
import 'package:radiozeit/features/radio_list/radio_list_search_page.dart';
import 'package:radiozeit/features/timeline/bloc/timeline_cubit.dart';
import 'package:radiozeit/features/transcript/radio_transcript_page.dart';
import 'package:radiozeit/utils/adaptive/screen_type.dart';
import 'package:radiozeit/utils/colors.dart';
import 'package:radiozeit/l10n/app_localizations.dart';

class RadioListPage extends StatefulWidget {
  static const String path = "/RadioListPage";

  const RadioListPage({super.key});

  @override
  State<RadioListPage> createState() => _RadioListPageState();
}

class _RadioListPageState extends State<RadioListPage> with SingleTickerProviderStateMixin {

  late GoRouter router;

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router = GoRouter.of(context);
      router.routerDelegate.addListener(_updateMenuStatus);
    });
  }

  _updateMenuStatus() {
    var currentPage = router.routerDelegate.currentConfiguration.uri.toString();
    if(router.routerDelegate.currentConfiguration.routes.last is GoRoute) {
      GoRoute route = router.routerDelegate.currentConfiguration.routes.last as GoRoute;
      if(route.path == RadioListPage.path){
        context.read<BottomNavigationCubit>().openMenu(false);
      }
      print("Page location $currentPage path ${route.path} ff ${router.routerDelegate.currentConfiguration.routes.first} ${router.routerDelegate.currentConfiguration.routes.last}");

    }

  }

  @override
  void dispose() {
    router.routerDelegate.removeListener(_updateMenuStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return BlocPresentationListener<RadioListCubit, RadioListEvent>(
      listener: (context, event) {
        if (event is RadioListLocationErrorEvent) {
          if(event.status == LocationPermissionStatus.FORBIDDEN_FOREVER) {
            _showSettingsDialog(context);
          } else if(event.status == LocationPermissionStatus.FORBIDDEN) {
            _onError(context, "Location permissions are denied");
          } else if(event.status == LocationPermissionStatus.DISABLED) {
            _onError(context, "Location services are disabled.");
          }

        }

        if(event is RadioListLocationErrorEvent) {

        }
      },
      child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 11,top: 6,left: 12,right: 2),
              decoration: BoxDecoration(
                gradient: AppGradient.getPanelGradient(context)
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    IconButton(
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: Icon(Icons.menu,color: textTheme.bodyMedium?.color,)),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(AppLocalizations.of(context)!.app_name,style: textTheme.displayLarge,),
                    ),
                    const Expanded(child: SizedBox()),
                    InkWell(
                      onTap: () => _showFavorite(context),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(AppLocalizations.of(context)!.title_favorite,style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),),
                      ),
                    )
                  ],
                ),
              ),
            ),
            Builder(
              builder: (context) {
                bool isEnableLocation = context.select((RadioListCubit cubit) => cubit.state.isLocationEnabled);
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LocationPanel(
                    isEnableLocation: isEnableLocation,
                    onSearch: _openSearchPage,
                    onToggleLocation: _toggleLocation,
                  ),
                );
              }
            ),

            Builder(
              builder: (context) {
                City city = context.select((RadioListCubit cubit) => cubit.state.city);

                if(city.isEmpty) return SizedBox();
                print("City $city");
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0,right: 16.0,bottom: 16.0),
                    child: Opacity(
                      opacity: 0.3,
                      child: Text("${AppLocalizations.of(context)!
                          .page_radio_list_location_city_title} ${city.name}",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),),
                    ),
                  ),
                );
              }
            ),
            Expanded(child: Builder(builder: (context) {
              RadioListCubit cubit = context.watch<RadioListCubit>();
              if(!cubit.state.isLoading && (!cubit.state.city.isEmpty || cubit.state.isLocationEnabled) && cubit.state.isListEmpty) {
                return Center(
                  child: Opacity(
                      opacity: 0.3,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(AppLocalizations.of(context)!.page_radio_list_not_found_in_location,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,),
                      )),
                );
              }
              List<String> favoriteList = context.select((RadioFavoriteCubit bloc) => bloc.state.favoriteList);

              if(ScreenType.getFormFactor(context) == ScreenType.big) {
                return RadioListBig(
                  list: cubit.state.radioList,
                  error: cubit.state.loadingError,
                  isLoading: cubit.state.isLoading,
                  reload: () => cubit.startLoadRadio(),
                  favorites: favoriteList,
                  setFavorite: _setFavorite,
                  openRadio: _openRadio,
                );
              }
              return RadioList(
                list: cubit.state.radioList,
                error: cubit.state.loadingError,
                isLoading: cubit.state.isLoading,
                reload: () => cubit.startLoadRadio(),
                favorites: favoriteList,
                setFavorite: _setFavorite,
                openRadio: _openRadio,
              );
            },)),
          ],
        ),
    );
  }

  _openSearchPage() {
    context.push(RadioSearchPage.path);
  }

  _toggleLocation() {
    context.read<RadioListCubit>().toggleLocation();
  }

  _onError(BuildContext context,String error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error),
    ));
  }

  static _showSettingsDialog(BuildContext context) {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.title_error),
        content: Text(AppLocalizations.of(context)!.location_disable_forever),
        actions: [
          TextButton(onPressed: () {
            Navigator.of(context).pop();
          }, child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(onPressed: () {
            Navigator.of(context).pop();
            Geolocator.openLocationSettings();
          }, child: Text(AppLocalizations.of(context)!.settings))
        ],
      );
    },);
  }


  _setFavorite(AppRadio radio,bool flag) {
    if(flag){
      context.read<RadioFavoriteCubit>().addToFavorite(radio);
    } else {
      context.read<RadioFavoriteCubit>().removeFromFavorite(radio);
    }
  }

  _openRadio(AppRadio radio) {
    context.read<BottomNavigationCubit>().openMenu(true);
    context.read<PlayerCubit>().selectRadio(radio);
    context.read<TimeLineCubit>().selectRadio(radio);
    if (radio.podcasts != null && radio.podcasts!.isNotEmpty) {
      context.read<PodcastCubit>().preloadPodcasts(radio.podcasts!, radioName: radio.name);
    }
    context.go(MenuConfig.getDefaultPagePath());
  }

  _showFavorite(BuildContext appContext) {
    showModalBottomSheet(
        context: appContext,
        useRootNavigator: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(12),topRight: Radius.circular(12))
        ),
        builder: (context) {
          return MultiBlocProvider(
            providers: [
              BlocProvider.value(value: appContext.read<RadioFavoriteCubit>()),
              BlocProvider.value(value: appContext.read<RadioListCubit>())
            ],
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8,bottom: 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CloseButton(color: Theme.of(context).colorScheme.onBackground),
                      Text(AppLocalizations.of(context)!.title_favorite,style: Theme.of(context).textTheme.displayLarge,),
                      SizedBox(width: 32,),
                    ],
                  ),
                ),
                Divider(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2),height: 24,thickness: 1),
                Expanded(
                  child: Builder(builder: (context) {
                    RadioListCubit cubit = context.watch<RadioListCubit>();
                    List<String> favoriteList = context.select((RadioFavoriteCubit bloc) => bloc.state.favoriteList);

                    if(ScreenType.getFormFactor(context) == ScreenType.big) {
                      return RadioListBig(
                        list: cubit.state.radioList.where((e) => favoriteList.contains(e.id)).toList(),
                        isLoading: cubit.state.isLoading,
                        favorites: favoriteList,
                        setFavorite: _setFavorite,
                        openRadio: (radio) {
                          Navigator.of(context).pop();
                          _openRadio(radio);
                        },
                      );
                    }
                    return RadioList(
                      list: cubit.state.radioList.where((e) => favoriteList.contains(e.id)).toList(),
                      isLoading: cubit.state.isLoading,
                      favorites: favoriteList,
                      setFavorite: _setFavorite,
                        openRadio: (radio) {
                          Navigator.of(context).pop();
                          _openRadio(radio);
                        }
                    );
                  },),
                ),
              ],
            ),
          );
        },
    );

  }


}
