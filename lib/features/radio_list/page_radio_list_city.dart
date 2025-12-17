import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:radiozeit/app/bottom_navigation/bottom_navigation_cubit.dart';
import 'package:radiozeit/app/bottom_navigation/menu_config.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/features/location/model/location_city.dart';
import 'package:radiozeit/features/player/player_cubit.dart';
import 'package:radiozeit/features/radio_list/cubit/radio_favorite_cubit.dart';
import 'package:radiozeit/features/radio_list/cubit/radio_list_city_cubit.dart';
import 'package:radiozeit/features/radio_list/radio_list.dart';
import 'package:radiozeit/features/podcast/bloc/podcast_cubit.dart';
import 'package:radiozeit/features/timeline/bloc/timeline_cubit.dart';
import 'package:radiozeit/features/transcript/radio_transcript_page.dart';
import 'package:radiozeit/utils/colors.dart';
import 'package:radiozeit/l10n/app_localizations.dart';

class PageRadioListCity extends StatefulWidget {
  static const String path = "/PageRadioListCity";

  const PageRadioListCity({super.key});

  @override
  State<PageRadioListCity> createState() => _PageRadioListCityState();
}

class _PageRadioListCityState extends State<PageRadioListCity> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RadioListCityCubit>().loadList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _topBar(context),
            Expanded(
              child: Builder(builder: (context) {
                bool isLoading = context.select((RadioListCityCubit bloc) => bloc.state.isLoading);
                List<AppRadio> list = context.select((RadioListCityCubit bloc) => bloc.state.list);
                List<String> favorites = context.select((RadioFavoriteCubit bloc) => bloc.state.favoriteList);
                if(!isLoading && list.isEmpty) {
                  return Center(
                    child: Text(AppLocalizations.of(context)!.page_radio_list_title_not_found,style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
                        fontWeight: FontWeight.w500
                    ),),
                  );
                }
                return RadioList(
                    list: list,
                    isLoading: isLoading,
                    favorites: favorites,
                    setFavorite: (radio, state) {
                      context.read<RadioFavoriteCubit>().toggleFavorite(radio, state);
                    },
                    openRadio: (radio) => _openRadio(context,radio),
                );
              },),
            )
          ],
        ),
      ),
    );
  }

  _openRadio(BuildContext context,AppRadio radio) {
    context.read<BottomNavigationCubit>().openMenu(true);
    context.read<PlayerCubit>().selectRadio(radio);
    context.read<TimeLineCubit>().selectRadio(radio);
    if (radio.podcasts != null && radio.podcasts!.isNotEmpty) {
      context.read<PodcastCubit>().preloadPodcasts(radio.podcasts!, radioName: radio.name);
    }
    context.go(MenuConfig.getDefaultPagePath());
  }

  _topBar(BuildContext context) {
    LocationCity city = context.read<RadioListCityCubit>().state.city;
    return Container(

      decoration: BoxDecoration(
          gradient: AppGradient.getPanelGradient(context)
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 0,vertical: 12),
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              InkWell(
                onTap: () {
                  context.pop();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 6),
                  child: SvgPicture.asset("assets/icons/ic_arrow_left.svg",width: 24,color: Theme.of(context).colorScheme.onBackground,),
                ),
              ),
              Text(city.city.name,style: Theme.of(context).textTheme.displayLarge?.copyWith()),
              const SizedBox(width: 40,)
            ],
          ),
        ),
      ),
    );
  }
}
