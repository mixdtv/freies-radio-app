import 'package:bloc/bloc.dart';
import 'package:bloc_presentation/bloc_presentation.dart';
import 'package:flutter/foundation.dart';
import 'package:radiozeit/data/api/repository.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/features/location/model/location_city.dart';
import 'package:radiozeit/utils/settings.dart';

class RadioListCityEvent {
  const RadioListCityEvent();
}


class RadioListCityCubit extends Cubit<RadioListCityState> with BlocPresentationMixin<RadioListCityState,RadioListCityEvent>{
  AppSettings settings = AppSettings.getInstance();
  Repository repo = Repository.getInstance();

  RadioListCityCubit(LocationCity city) : super(RadioListCityState.init(city: city));

  loadList() async {
    if(state.isLoading) return;

    emit(state.copyWith(isLoading: true,loadingError: ""));

    var resp = await repo.loadRadioList(location:state.city.location);
    if(resp.success) {
      emit(state.copyWith(
          isLoading: false,
          list: resp.radioList
      ));
    } else {
      emit(state.copyWith(
          isLoading: false,
          loadingError: resp.message
      ));
    }
  }
}

@immutable
class RadioListCityState {
  final List<AppRadio> list;
  final bool isLoading;
  final String loadingError;
  final LocationCity city;


  const RadioListCityState.init({
    this.list = const [],
    this.isLoading = false,
    this.loadingError = "",
    required this.city
  });

  const RadioListCityState({
    required this.list,
    required this.isLoading,
    required this.loadingError,
    required this.city,
  });

  RadioListCityState copyWith({
    List<AppRadio>? list,
    bool? isLoading,
    String? loadingError,
    LocationCity? city,
  }) {
    return RadioListCityState(
      list: list ?? this.list,
      isLoading: isLoading ?? this.isLoading,
      loadingError: loadingError ?? this.loadingError,
      city: city ?? this.city,
    );
  }
}
