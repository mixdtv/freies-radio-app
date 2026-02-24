import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:radiozeit/data/api/repository.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/data/model/radio_program.dart';
import 'package:radiozeit/features/location/model/location_city.dart';


class RadioListSearchCubit extends Cubit<RadioListSearchState> {
  final Repository repo = Repository.getInstance();

  CancelToken? loadRadio;
  CancelToken? loadCity;
  CancelToken? loadPrograms;
  RadioListSearchCubit() : super(const RadioListSearchState.init());


  @override
  close() async {
    loadRadio?.cancel();
    loadCity?.cancel();
    loadPrograms?.cancel();
    await super.close();
  }

  search(String query) {
    if(state.query == query) return;

    emit(state.copyWith(query: query));
    loadRadio?.cancel();
    loadCity?.cancel();
    loadPrograms?.cancel();

    if(query.length < 3) {
      emit(state.copyWith(
          cities: [],
          radios: [],
          programs: [],
          isCityNotFound: false,
          isRadioNotFound: false,
          isProgramNotFound: false,
          isLoadingRadio: false,
          isLoadingCity: false,
          isLoadingPrograms: false,
      ));
    } else {
      _loadRadioList(query);
      _loadCities(query);
      _loadPrograms(query);
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



  /// Time window matching TimeLineCubit._lookbackDays.
  static const int _lookbackDays = 7;

  _loadPrograms(String query) async {
    emit(state.copyWith(
        isLoadingPrograms: true,
        isProgramNotFound: false,
    ));
    loadPrograms = CancelToken();
    final now = DateTime.now();
    var resp = await repo.searchEpg(
      query: query,
      from: now.subtract(const Duration(days: _lookbackDays)),
      to: now.add(const Duration(days: _lookbackDays)),
      cancelToken: loadPrograms,
    );
    if(resp.success) {
      emit(state.copyWith(
          isLoadingPrograms: false,
          isProgramNotFound: resp.list.isEmpty,
          programs: resp.list,
      ));
    } else {
      emit(state.copyWith(
          isLoadingPrograms: false,
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
  final List<RadioEpg> programs;
  final bool isLoadingRadio;
  final bool isRadioNotFound;
  final bool isCityNotFound;
  final bool isProgramNotFound;
  final bool isLoadingCity;
  final bool isLoadingPrograms;
  final String query;

  const RadioListSearchState({
    required this.cities,
    required this.radios,
    required this.programs,
    required this.isLoadingRadio,
    required this.isLoadingCity,
    required this.isLoadingPrograms,
    required this.query,
    required this.isRadioNotFound,
    required this.isCityNotFound,
    required this.isProgramNotFound,
  });

  const RadioListSearchState.init({
    this.cities = const [],
    this.radios = const [],
    this.programs = const [],
    this.isLoadingRadio = false,
    this.isLoadingCity = false,
    this.isLoadingPrograms = false,
    this.isCityNotFound = false,
    this.isRadioNotFound = false,
    this.isProgramNotFound = false,
    this.query = "",
  });

  RadioListSearchState copyWith({
    List<LocationCity>? cities,
    List<AppRadio>? radios,
    List<RadioEpg>? programs,
    bool? isLoadingRadio,
    bool? isRadioNotFound,
    bool? isCityNotFound,
    bool? isProgramNotFound,
    bool? isLoadingCity,
    bool? isLoadingPrograms,
    String? query,
  }) {
    return RadioListSearchState(
      cities: cities ?? this.cities,
      radios: radios ?? this.radios,
      programs: programs ?? this.programs,
      isLoadingRadio: isLoadingRadio ?? this.isLoadingRadio,
      isRadioNotFound: isRadioNotFound ?? this.isRadioNotFound,
      isCityNotFound: isCityNotFound ?? this.isCityNotFound,
      isProgramNotFound: isProgramNotFound ?? this.isProgramNotFound,
      isLoadingCity: isLoadingCity ?? this.isLoadingCity,
      isLoadingPrograms: isLoadingPrograms ?? this.isLoadingPrograms,
      query: query ?? this.query,
    );
  }
}
