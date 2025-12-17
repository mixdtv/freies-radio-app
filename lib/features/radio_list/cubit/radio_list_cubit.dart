import 'package:bloc/bloc.dart';
import 'package:bloc_presentation/bloc_presentation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:radiozeit/data/api/repository.dart';
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
    Location? location;
    print("settings.isUserEnableLocation ${settings.isUserEnableLocation}");
    if(settings.isUserEnableLocation) {
      location = await _getRadioLocation();
      Location? oldLocation  = settings.getLocation();
      City city = settings.gpsCity;
      emit(state.copyWith(city:city));
      if(location != null ) {
        if(location.isChange(oldLocation)) {
          updateLocationCity(location);
          settings.saveLocation(location);
        }
      } else {
        location = oldLocation;
      }
    } else {
      LocationCity? selectedCity = settings.manualCity;
      print("settings.isUserEnableLocation ${settings.manualCity}");
      if(selectedCity != null) {
        location = selectedCity.location;
        emit(state.copyWith(city:selectedCity.city));
      }
    }

    _loadRadioList(location);
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

  _loadRadioList(Location? location) async {

    cancelLoadRadio = CancelToken();
    var resp = await repo.loadRadioList(location:location,cancel:cancelLoadRadio);
    if(resp.success) {
      emitPresentation(RadioListLoadedEvent(resp.radioList));
      emit(state.copyWith(
          isLoading: false,
          isListEmpty:resp.radioList.isEmpty,
          radioList: resp.radioList
      ));
    } else {
      if(!resp.isCanceled) {
        emit(state.copyWith(
            isLoading: false,
            loadingError: resp.message
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

  const RadioListState({
    required this.radioList,
    required this.isLoading,
    required this.loadingError,
    required this.isLocationEnabled,
    required this.isListEmpty,
    required this.city,
  });

  const RadioListState.init({
    this.radioList = const [],
    this.isLoading = false,
    this.isLocationEnabled = false,
    this.isListEmpty = false,
    this.loadingError = "",
    this.city = const City.empty(),
  });

  RadioListState copyWith({
    List<AppRadio>? radioList,

    bool? isLoading,
    bool? isListEmpty,
    bool? isLocationEnabled,
    String? loadingError,
    City? city
  }) {
    return RadioListState(
      radioList: radioList ?? this.radioList,
      isLoading: isLoading ?? this.isLoading,
      loadingError: loadingError ?? this.loadingError,
      isLocationEnabled: isLocationEnabled ?? this.isLocationEnabled,
      city: city ?? this.city,
      isListEmpty: isListEmpty ?? this.isListEmpty,
    );
  }

}
