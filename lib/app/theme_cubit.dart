import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:radiozeit/utils/settings.dart';



class ThemeCubit extends Cubit<ThemeCubitState> {
  AppSettings  settings = AppSettings.getInstance();

  ThemeCubit(String themeType) : super(ThemeCubitState(themeType : themeType));

  setTheme(String themeType) {
    emit(ThemeCubitState(themeType: themeType));
    settings.setThemeType(themeType);
  }
}

@immutable
class ThemeCubitState {
  final String themeType;

  const ThemeCubitState({
    required this.themeType,
  });
}


