import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:radiozeit/data/api/repository.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/features/location/model/location_city.dart';


class RadioListSearchCubit extends Cubit<RadioListSearchState> {
  final Repository repo = Repository.getInstance();

  CancelToken? loadRadio;
  CancelToken? loadCity;
  RadioListSearchCubit() : super(const RadioListSearchState.init());


  @override
  close() async {
    loadRadio?.cancel();
    loadCity?.cancel();
    await super.close();
  }

  search(String query) {
    if(state.query == query) return;

    emit(state.copyWith(query: query));
    loadRadio?.cancel();
    loadCity?.cancel();

    if(query.length < 3) {
      emit(state.copyWith(
          cities: [],
          radios: [],
          isCityNotFound: false,
          isRadioNotFound: false,
          isLoadingRadio: false,
          isLoadingCity: false,
      ));
    } else {
      _loadRadioList(query);
      _loadCities(query);
    }
  }

  _loadRadioList(String query) async {
    emit(state.copyWith(
        isLoadingRadio: true,
        isRadioNotFound:false
    ));
    loadRadio = CancelToken();
    var resp = await repo.loadRadioList(query:query,cancel:loadRadio);
    if(resp.success) {
      emit(state.copyWith(
          isLoadingRadio: false,
          isRadioNotFound:  resp.radioList.isEmpty,
          radios: resp.radioList
      ));
    } else {
      emit(state.copyWith(
        isLoadingRadio: false,
      ));
    }
  }



  _loadCities(String query) async {
    emit(state.copyWith(
        isLoadingCity: true,
        isCityNotFound: false,
    ));
    loadCity = CancelToken();
    var resp = await repo.loadCityList(query:query,cancel:loadCity);
    if(resp.success) {
      emit(state.copyWith(
          isLoadingCity: false,
          isCityNotFound: resp.cityList.isEmpty,
          cities: resp.cityList
      ));
    } else {
      emit(state.copyWith(
          isLoadingCity: false,
      ));
    }
  }
}

class RadioListSearchState {
  final List<LocationCity> cities;
  final List<AppRadio> radios;
  final bool isLoadingRadio;
  final bool isRadioNotFound;
  final bool isCityNotFound;
  final bool isLoadingCity;
  final String query;

  const RadioListSearchState({
    required this.cities,
    required this.radios,
    required this.isLoadingRadio,
    required this.isLoadingCity,
    required this.query,
    required this.isRadioNotFound,
    required this.isCityNotFound,
  });

  const RadioListSearchState.init({
    this.cities = const [],
    this.radios = const [],
    this.isLoadingRadio = false,
    this.isLoadingCity = false,
    this.isCityNotFound = false,
    this.isRadioNotFound = false,
    this.query = "",
  });

  RadioListSearchState copyWith({
    List<LocationCity>? cities,
    List<AppRadio>? radios,
    bool? isLoadingRadio,
    bool? isRadioNotFound,
    bool? isCityNotFound,
    bool? isLoadingCity,
    String? query,
  }) {
    return RadioListSearchState(
      cities: cities ?? this.cities,
      radios: radios ?? this.radios,
      isLoadingRadio: isLoadingRadio ?? this.isLoadingRadio,
      isRadioNotFound: isRadioNotFound ?? this.isRadioNotFound,
      isCityNotFound: isCityNotFound ?? this.isCityNotFound,
      isLoadingCity: isLoadingCity ?? this.isLoadingCity,
      query: query ?? this.query,
    );
  }
}
