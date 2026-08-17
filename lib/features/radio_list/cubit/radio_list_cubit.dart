import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:bloc_presentation/bloc_presentation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:radiozeit/data/api/repository.dart';
import 'package:radiozeit/data/model/now_playing.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/features/location/location_service.dart';
import 'package:radiozeit/features/location/model/location.dart';
import 'package:radiozeit/features/location/model/city.dart';
import 'package:radiozeit/features/location/model/location_city.dart';
import 'package:radiozeit/utils/settings.dart';
class RadioListEvent {
  const RadioListEvent();
}

class RadioListLoadedEvent extends RadioListEvent{
  final List<AppRadio> radioList;

  const RadioListLoadedEvent(
     this.radioList,
  );
}

class RadioListLocationErrorEvent extends RadioListEvent{
  final LocationPermissionStatus status;

  const RadioListLocationErrorEvent(
     this.status,
  );
}

class RadioListCubit extends Cubit<RadioListState> with BlocPresentationMixin<RadioListState,RadioListEvent>{
  AppSettings settings = AppSettings.getInstance();
  Repository repo = Repository.getInstance();
  CancelToken? cancelLoadRadio;

  RadioListCubit() : super(RadioListState.init()
  );

  @override
  close() async {
    cancelLoadRadio?.cancel();
    await super.close();
  }

  startLoadRadio({bool isLoading = true}) async {
    cancelLoadRadio?.cancel();

    emit(state.copyWith(isLoading: isLoading,loadingError: "",city: const City.empty()));

    // Before anything that can wait. Inside _loadRadioList this was reached
    // only once a request was being issued, so a start with no stored position
    // — after location was switched off and on again — still sat behind the
    // position fix, which is the wait this exists to remove.
    _showCachedRadioList();

    if(!settings.isUserEnableLocation) {
      LocationCity? selectedCity = settings.manualCity;
      Location? location;
      if(selectedCity != null) {
        location = selectedCity.location;
        emit(state.copyWith(city:selectedCity.city));
      }
      _loadRadioList(location);
      return;
    }

    // The list used to wait for a position fix before asking for anything.
    // Measured on a Galaxy S22, that fix took between 0.1 and 5.6 seconds —
    // against 0.4 seconds for the request itself — so most of the wait was
    // the phone finding itself, with a 10 second ceiling behind it.
    //
    // Ask with the last known position straight away instead. A fresh fix
    // only costs a second request if the user has actually moved, since
    // isChange ignores anything under 5 km.
    Location? lastKnown = settings.getLocation();
    City knownCity = settings.gpsCity;
    if(!knownCity.isEmpty) emit(state.copyWith(city: knownCity));
    if(lastKnown != null) _loadRadioList(lastKnown);

    Location? fresh = await _getRadioLocation();

    if(fresh == null) {
      // No fix: whatever the last known position gave us is what there is.
      if(lastKnown == null) _loadRadioList(null);
      return;
    }

    // isChange(null) is true, so a first run with no stored position lands
    // here and loads once.
    if(fresh.isChange(lastKnown)) {
      updateLocationCity(fresh);
      settings.saveLocation(fresh);
      _loadRadioList(fresh);
    }
  }

  unPauseView() async {
    startLoadRadio(isLoading: false);
  }

  selectCity(LocationCity city) async {
    emit(state.copyWith(isLocationEnabled: false,city:city.city,isLoading: true));
    settings.isUserEnableLocation = false;
    settings.saveLocation(null);
    settings.gpsCity = const City.empty();
    await settings.setManualCity(city);
    print("selectCity ${city}");
    startLoadRadio();
  }

  Future<Location?> _getRadioLocation() async {
    Location? location;
    print("settings.isUserEnableLocation ${settings.isUserEnableLocation}");
    if(settings.isUserEnableLocation) {
      var isGpsEnabled = await LocationService.isHasPermission();
      if(isGpsEnabled) {
        emit(state.copyWith(isLocationEnabled: true));
        location = await LocationService.getLocation();
      } else {
        emit(state.copyWith(isLocationEnabled: false));
      }
    } else {
      emit(state.copyWith(isLocationEnabled: false));
    }
    return location;
  }

  updateLocationCity(Location location) async {
    var response = await repo.loadCityByCoordinates(location:location);
    if(response.success) {
      var city = response.city ?? const City.empty();
      settings.gpsCity = city;
      emit(state.copyWith(city:response.city ?? City.empty()));
    }
  }

  toggleLocation() {
    if(state.isLocationEnabled) {
      _disableLocation();
    } else {
      _enableLocation();
    }
  }

  _disableLocation() {
    emit(state.copyWith(isLocationEnabled: false));
    settings.isUserEnableLocation = false;
    settings.saveLocation(null);
    settings.gpsCity = const City.empty();
    startLoadRadio();
  }

  _enableLocation() async {
    emit(state.copyWith(isLocationEnabled: true,city: const City.empty()));
    settings.isUserEnableLocation = true;
    await settings.setManualCity(null);
    var isGpsEnabled = await LocationService.isHasPermission();
    if(!isGpsEnabled) {
      var status = await LocationService.requestLocationPermission();
      if(status != LocationPermissionStatus.ALLOW) {
        emit(state.copyWith(isLocationEnabled: false));
        settings.isUserEnableLocation = false;
        emitPresentation(RadioListLocationErrorEvent(status));
        return;
      }
    }
    startLoadRadio();
  }

  /// Put the last known list on screen before the request goes out.
  ///
  /// Only when nothing is displayed yet, so a refresh never replaces fresh
  /// data with older data mid-scroll.
  ///
  /// Clears isLoading as well, and must: RadioList renders its shimmer
  /// placeholder instead of the list for as long as that flag is set, so a
  /// cached list emitted without clearing it is displayed to nobody.
  _showCachedRadioList() {
    if(state.radioList.isNotEmpty) return;
    var cached = AppRadio.listFromJsonString(settings.cachedRadioList);
    if(cached.isEmpty) return;
    emit(state.copyWith(radioList: cached, isListEmpty: false, isLoading: false));
  }

  /// Fill in who currently has each aggregated station's stream.
  ///
  /// Only aggregated stations are asked about: for a station broadcasting its
  /// own programme, "who is on air" is the station itself and says nothing.
  ///
  /// Runs after the list is displayed and never blocks it. If the EPG is
  /// unreachable, or older than this build and has no such endpoint, the map
  /// stays empty and the rows keep their member strip.
  _loadNowPlaying(List<AppRadio> radios) async {
    var slugs = radios
        .where((r) => r.members.isNotEmpty && r.epgPrefix.isNotEmpty)
        .map((r) => r.epgPrefix)
        .toList();
    if(slugs.isEmpty) return;

    var onAir = await repo.loadNowPlaying(epgSlugs: slugs);
    if(onAir.isEmpty || isClosed) return;
    emit(state.copyWith(nowPlaying: onAir));
  }

  _loadRadioList(Location? location) async {
    // Cancel any request still in flight: a fresh position can start a second
    // one, and the older answer must not land on top of the newer.
    cancelLoadRadio?.cancel();
    cancelLoadRadio = CancelToken();
    var resp = await repo.loadRadioList(location:location,cancel:cancelLoadRadio);
    if(resp.success) {
      settings.cachedRadioList = jsonEncode(resp.raw);
      emitPresentation(RadioListLoadedEvent(resp.radioList));
      emit(state.copyWith(
          isLoading: false,
          isListEmpty:resp.radioList.isEmpty,
          radioList: resp.radioList
      ));
      // Deliberately not awaited: the list is already on screen and must not
      // wait on a second request to be usable.
      _loadNowPlaying(resp.radioList);
    } else {
      if(!resp.isCanceled) {
        // With a cached list already on screen an error banner would sit over
        // working content; the next successful start replaces it quietly. The
        // cache itself is left alone either way — only success overwrites it.
        emit(state.copyWith(
            isLoading: false,
            loadingError: state.radioList.isEmpty ? resp.message : ""
        ));
      }
    }
  }

}

@immutable
class RadioListState {
  final List<AppRadio> radioList;
  final bool isLoading;
  final bool isListEmpty;
  final String loadingError;
  final City city;
  final isLocationEnabled;

  /// Who currently has each aggregated station's stream, keyed by EPG slug.
  /// Empty until the EPG answers, and empty for good if it never does — the
  /// list does not wait for it.
  final Map<String, NowPlaying> nowPlaying;

  const RadioListState({
    required this.radioList,
    required this.isLoading,
    required this.loadingError,
    required this.isLocationEnabled,
    required this.isListEmpty,
    required this.city,
    this.nowPlaying = const {},
  });

  const RadioListState.init({
    this.radioList = const [],
    this.isLoading = false,
    this.isLocationEnabled = false,
    this.isListEmpty = false,
    this.loadingError = "",
    this.city = const City.empty(),
    this.nowPlaying = const {},
  });

  RadioListState copyWith({
    List<AppRadio>? radioList,

    bool? isLoading,
    bool? isListEmpty,
    bool? isLocationEnabled,
    String? loadingError,
    City? city,
    Map<String, NowPlaying>? nowPlaying
  }) {
    return RadioListState(
      radioList: radioList ?? this.radioList,
      isLoading: isLoading ?? this.isLoading,
      loadingError: loadingError ?? this.loadingError,
      isLocationEnabled: isLocationEnabled ?? this.isLocationEnabled,
      city: city ?? this.city,
      isListEmpty: isListEmpty ?? this.isListEmpty,
      nowPlaying: nowPlaying ?? this.nowPlaying,
    );
  }

}
