import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/utils/settings.dart';

class RadioFavoriteCubit extends Cubit<RadioFavoriteState> {
  final AppSettings settings = AppSettings.getInstance();

  RadioFavoriteCubit() : super(const RadioFavoriteState(favoriteList: [])) {
    _init();
  }
  _init() async {
    emit(RadioFavoriteState(
        favoriteList: settings.getFavoriteList()
    ));
  }

  toggleFavorite(AppRadio radio,bool value) {
    if(value) {
      addToFavorite(radio);
    } else {
      removeFromFavorite(radio);
    }
  }

  addToFavorite(AppRadio radio) {
    List<String> newList = List.from(state.favoriteList);
    newList.add(radio.id);
    settings.saveFavoriteList(newList);
    emit(RadioFavoriteState(favoriteList: newList));
  }

  removeFromFavorite(AppRadio radio) {
    List<String> newList = List.from(state.favoriteList.where((e) => e != radio.id));
    settings.saveFavoriteList(newList.toList());
    emit(RadioFavoriteState(favoriteList: newList));
  }
}

class RadioFavoriteState{
  final List<String> favoriteList;

  const RadioFavoriteState({
    required this.favoriteList,
  });
}
