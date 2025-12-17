import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:radiozeit/app/bottom_navigation/bottom_navigation_cubit.dart';
import 'package:radiozeit/app/bottom_navigation/menu_config.dart';
import 'package:radiozeit/app/widgets/input/input_search.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/features/location/model/location_city.dart';
import 'package:radiozeit/features/location/widgets/city_list.dart';
import 'package:radiozeit/features/location/widgets/city_preview.dart';
import 'package:radiozeit/features/player/player_cubit.dart';
import 'package:radiozeit/features/radio_list/cubit/radio_favorite_cubit.dart';
import 'package:radiozeit/features/radio_list/cubit/radio_list_cubit.dart';
import 'package:radiozeit/features/radio_list/cubit/radio_list_search_cubit.dart';
import 'package:radiozeit/features/radio_list/page_radio_list_city.dart';
import 'package:radiozeit/features/radio_list/radio_list.dart';
import 'package:radiozeit/features/radio_list/radio_list_item.dart';
import 'package:radiozeit/features/radio_list/widget/radio_not_found_info.dart';
import 'package:radiozeit/features/podcast/bloc/podcast_cubit.dart';
import 'package:radiozeit/features/timeline/bloc/timeline_cubit.dart';
import 'package:radiozeit/features/transcript/radio_transcript_page.dart';
import 'package:radiozeit/utils/colors.dart';
import 'package:radiozeit/utils/settings.dart';
import 'package:radiozeit/l10n/app_localizations.dart';

class RadioSearchPage extends StatelessWidget {
  static final String path = "/RadioSearchPage";

  const RadioSearchPage({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _topBar(context),

            Builder(builder: (context) {
              List<Widget> childs = [];
              bool isCityLoading = context.select((RadioListSearchCubit cubit) => cubit.state.isLoadingCity);
              bool isCityNotFound = context.select((RadioListSearchCubit cubit) => cubit.state.isCityNotFound);
              List<LocationCity> cityList = context.select((RadioListSearchCubit cubit) => cubit.state.cities);

              bool isRadioLoading = context.select((RadioListSearchCubit cubit) => cubit.state.isLoadingRadio);
              bool isRadioNotFound = context.select((RadioListSearchCubit cubit) => cubit.state.isRadioNotFound);
              List<AppRadio> radioList = context.select((RadioListSearchCubit cubit) => cubit.state.radios);
              List<String> radioFavorites = context.select((RadioFavoriteCubit cubit) => cubit.state.favoriteList);



              if(!isCityLoading && !isRadioLoading && isCityNotFound && isRadioNotFound) {
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset("assets/icons/ic_search_not_found.svg"),
                      const SizedBox(height: 14,),
                      Text(AppLocalizations.of(context)!.stations_not_found,style: Theme.of(context).textTheme.headlineLarge,),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32,vertical: 14),
                        child: RadioNotFoundInfo(),
                      )
                    ],
                  ),
                );
              }
              childs.add(_groupTitle(context, AppLocalizations.of(context)!.city));
              if(!isCityLoading && isCityNotFound) {
                childs.add(
                    Center(
                      child: Opacity(
                          opacity: 0.3,
                          child: Text(AppLocalizations.of(context)!.city_not_found,style: Theme.of(context).textTheme.headlineMedium,)),
                    )
                );
              } else {
                childs.add(
                    CityList(
                      shrinkWrap: true,
                      isLoading: isCityLoading,
                      physics: const NeverScrollableScrollPhysics(),
                      list:cityList,
                      onSelectCity: (city) => _onSelectCity(context,city),
                    )
                );
              }
              childs.add(_groupTitle(context, AppLocalizations.of(context)!.stations));

              if(!isRadioLoading && isRadioNotFound) {
                childs.add(Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset("assets/icons/ic_search_not_found.svg"),
                    const SizedBox(height: 14,),
                    Text(AppLocalizations.of(context)!.stations_not_found,style: Theme.of(context).textTheme.headlineLarge,),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32,vertical: 14),
                      child: RadioNotFoundInfo(),
                    )
                  ],
                ));
              } else {
                childs.add(RadioList(
                  list: radioList,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  isLoading: isRadioLoading,
                  favorites: radioFavorites,
                  setFavorite: (radio, status) => context.read<RadioFavoriteCubit>().toggleFavorite(radio, status),
                  openRadio: (radio) => _openRadio(context,radio),
                ));
              }
              
              
              
              
              return Expanded(child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: childs,
                ),
              ));

            })

            
          ],
        ),
      ),
    );
  }

  _openRadio(BuildContext context, AppRadio radio) {
    context.read<BottomNavigationCubit>().openMenu(true);
    context.read<PlayerCubit>().selectRadio(radio);
    context.read<TimeLineCubit>().selectRadio(radio);
    if (radio.podcasts != null && radio.podcasts!.isNotEmpty) {
      context.read<PodcastCubit>().preloadPodcasts(radio.podcasts!, radioName: radio.name);
    }
    context.go(MenuConfig.getDefaultPagePath());
  }

  _onSelectCity(BuildContext context, LocationCity city) {
    context.read<RadioListCubit>().selectCity(city);
    context.pop();
  }
  
  _groupTitle(BuildContext context,String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16,top: 24),
      child: Text(title,style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
          fontWeight: FontWeight.w500
      ),),
    );
  }

  _topBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradient.getPanelGradient(context)
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16,vertical: 12),
          height: 65,
          child: InputSearch(
            isActive: true,
            isAutoFocus: true,
            hint: AppLocalizations.of(context)!.input_placeholder_search_city,
            onCancel: () {
              context.pop();
            },
            onSearch: (query) {
              context.read<RadioListSearchCubit>().search(query);
            },
          ),
        ),
      ),
    );
  }
}
