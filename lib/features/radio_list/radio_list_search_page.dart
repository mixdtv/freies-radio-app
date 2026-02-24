import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:radiozeit/app/bottom_navigation/bottom_navigation_cubit.dart';
import 'package:radiozeit/app/bottom_navigation/menu_config.dart';
import 'package:radiozeit/app/widgets/input/input_search.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/data/model/radio_program.dart';
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

              bool isProgramLoading = context.select((RadioListSearchCubit cubit) => cubit.state.isLoadingPrograms);
              bool isProgramNotFound = context.select((RadioListSearchCubit cubit) => cubit.state.isProgramNotFound);
              List<RadioEpg> programList = context.select((RadioListSearchCubit cubit) => cubit.state.programs);

              if(!isCityLoading && !isRadioLoading && !isProgramLoading && isCityNotFound && isRadioNotFound && isProgramNotFound) {
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
              // Programs section (before stations for better visibility)
              childs.add(_groupTitle(context, AppLocalizations.of(context)!.timeline));
              if(!isProgramLoading && isProgramNotFound) {
                childs.add(
                    Center(
                      child: Opacity(
                          opacity: 0.3,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(AppLocalizations.of(context)!.stations_not_found,style: Theme.of(context).textTheme.bodyLarge,),
                          )),
                    )
                );
              } else {
                childs.add(_programList(context, programList, isProgramLoading));
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
    context.push(MenuConfig.getDefaultPagePath());
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

  Widget _programList(BuildContext context, List<RadioEpg> programs, bool isLoading) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: programs.length,
      itemBuilder: (context, index) {
        final program = programs[index];
        final timeStr = '${program.start.hour.toString().padLeft(2, '0')}:${program.start.minute.toString().padLeft(2, '0')}';
        final dateStr = '${program.start.day}.${program.start.month}.';
        return ListTile(
          leading: Icon(Icons.radio, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4)),
          title: Text(program.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '$dateStr $timeStr · ${program.subheadline}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
            ),
          ),
          onTap: () => _openProgram(context, program),
        );
      },
    );
  }

  _openProgram(BuildContext context, RadioEpg program) {
    // Find the matching station from the loaded radio list
    final radioListCubit = context.read<RadioListCubit>();
    final radio = radioListCubit.state.radioList.cast<AppRadio?>().firstWhere(
      (r) => r!.epgPrefix.toLowerCase() == program.broadcasterId.toLowerCase()
           || r.prefix.toLowerCase() == program.broadcasterId.toLowerCase(),
      orElse: () => null,
    );

    if (radio == null) return;

    context.read<BottomNavigationCubit>().openMenu(true);
    context.read<PlayerCubit>().selectRadio(radio);
    context.read<TimeLineCubit>().selectRadio(radio);
    context.read<TimeLineCubit>().scrollToProgram(program.id);
    if (radio.podcasts != null && radio.podcasts!.isNotEmpty) {
      context.read<PodcastCubit>().preloadPodcasts(radio.podcasts!, radioName: radio.name);
    }
    context.push(MenuConfig.getDefaultPagePath());
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
