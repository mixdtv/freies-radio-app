import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:radiozeit/app/bottom_navigation/bottom_navigation_cubit.dart';
import 'package:radiozeit/app/bottom_navigation/menu_config.dart';
import 'package:radiozeit/app/widgets/input/input_search.dart';
import 'package:radiozeit/app/widgets/shimmer.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/data/model/radio_program.dart';
import 'package:radiozeit/features/location/model/location_city.dart';
import 'package:radiozeit/features/location/widgets/city_list.dart';
import 'package:radiozeit/features/player/player_cubit.dart';
import 'package:radiozeit/features/radio_list/cubit/radio_favorite_cubit.dart';
import 'package:radiozeit/features/radio_list/cubit/radio_list_cubit.dart';
import 'package:radiozeit/features/radio_list/cubit/radio_list_search_cubit.dart';
import 'package:radiozeit/features/radio_list/radio_list.dart';
import 'package:radiozeit/features/radio_list/widget/radio_not_found_info.dart';
import 'package:radiozeit/features/podcast/bloc/podcast_cubit.dart';
import 'package:radiozeit/features/timeline/bloc/timeline_cubit.dart';
import 'package:radiozeit/utils/colors.dart';
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

              // Only programmes of stations in the broadcaster list are shown:
              // a station hidden in the backend (showInApp: false) must not
              // surface through EPG search, and every row that is shown is
              // guaranteed to open (same match as _openProgram).
              List<AppRadio> knownStations = context.select((RadioListCubit cubit) => cubit.state.radioList);
              List<RadioEpg> visiblePrograms = programList
                  .where((p) => _stationFor(knownStations, p) != null)
                  .toList();
              // Filtered-empty only counts as "not found" when the EPG had
              // results; an empty query must stay a blank section.
              bool programNotFound = isProgramNotFound ||
                  (!isProgramLoading && programList.isNotEmpty && visiblePrograms.isEmpty);

              if(!isCityLoading && !isRadioLoading && !isProgramLoading && isCityNotFound && isRadioNotFound && programNotFound) {
                return Expanded(child: _noResults(context));
              }
              final l10n = AppLocalizations.of(context)!;

              // Programmes first: they are the most specific match and change
              // by the minute; stations second; cities last as the broadest
              // way in.
              childs.add(_groupTitle(context, l10n.programs));
              if(!isProgramLoading && programNotFound) {
                childs.add(_notFound(context, l10n.programs_not_found));
              } else {
                childs.add(_programList(context, visiblePrograms, isProgramLoading));
              }

              childs.add(_groupTitle(context, l10n.stations));
              if(!isRadioLoading && isRadioNotFound) {
                childs.add(_notFound(context, l10n.stations_not_found));
              } else {
                childs.add(RadioList(
                  list: radioList,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  isLoading: isRadioLoading,
                  placeholderCount: _placeholderRows,
                  showNotFoundInfo: false,
                  favorites: radioFavorites,
                  setFavorite: (radio, status) => context.read<RadioFavoriteCubit>().toggleFavorite(radio, status),
                  openRadio: (radio) => _openRadio(context,radio),
                ));
              }

              childs.add(_groupTitle(context, l10n.city));
              if(!isCityLoading && isCityNotFound) {
                childs.add(_notFound(context, l10n.city_not_found));
              } else {
                childs.add(
                    CityList(
                      shrinkWrap: true,
                      isLoading: isCityLoading,
                      physics: const NeverScrollableScrollPhysics(),
                      list:cityList.take(_maxCities).toList(),
                      onSelectCity: (city) => _onSelectCity(context,city),
                    )
                );
              }

              // Page footer, after the last section, not wedged between two.
              childs.add(Padding(
                padding: const EdgeInsets.all(32.0),
                child: RadioNotFoundInfo(),
              ));

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

  /// Nothing matched in any section: name the query (typos jump out), say
  /// what was searched (the ±7-day programme window is the usual surprise),
  /// give one next step, and keep "station missing?" as an aside below.
  Widget _noResults(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = context.select((RadioListSearchCubit cubit) => cubit.state.query);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onBackground.withOpacity(0.5),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.search_no_results_title(query),
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(l10n.search_no_results_scope, style: muted, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(l10n.search_no_results_hint, style: muted, textAlign: TextAlign.center),
          const SizedBox(height: 40),
          RadioNotFoundInfo(),
        ],
      ),
    );
  }

  /// The cities endpoint returns every match alphabetically with no limit;
  /// a short prefix like "bad" would otherwise push the footer off screen.
  static const int _maxCities = 5;

  /// Shimmer rows per section while a search is running. Three sections
  /// stack on one screen, so each gets a hint of a list, not a full page.
  static const int _placeholderRows = 3;

  /// The quiet "nothing here" row every section shares: same size, same
  /// weight, sitting where the first result would be.
  Widget _notFound(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        text,
        style: Theme.of(context).textTheme.displayMedium?.copyWith(
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
        ),
      ),
    );
  }

  static Widget _programPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 180,
                height: 14,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 6),
              Container(
                width: 120,
                height: 10,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _programList(BuildContext context, List<RadioEpg> programs, bool isLoading) {
    if (isLoading) {
      return Shimmer(
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: _placeholderRows,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) => ShimmerLoading(child: _programPlaceholder()),
        ),
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

  /// The station a programme belongs to, matched on the EPG slug or the
  /// station prefix (case-insensitive), or null when it is not in the list.
  static AppRadio? _stationFor(List<AppRadio> stations, RadioEpg program) {
    final id = program.broadcasterId.toLowerCase();
    for (final radio in stations) {
      if (radio.epgPrefix.toLowerCase() == id || radio.prefix.toLowerCase() == id) {
        return radio;
      }
    }
    return null;
  }

  _openProgram(BuildContext context, RadioEpg program) {
    // Find the matching station from the loaded radio list
    final radio = _stationFor(context.read<RadioListCubit>().state.radioList, program);

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
