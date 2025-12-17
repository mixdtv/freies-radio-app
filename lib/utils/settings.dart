import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:radiozeit/app/style.dart';
import 'package:radiozeit/data/model/translate_lang.dart';
import 'package:radiozeit/features/location/location_service.dart';
import 'package:radiozeit/features/location/model/location.dart';
import 'package:radiozeit/features/location/model/city.dart';
import 'package:radiozeit/features/location/model/location_city.dart';
import 'package:radiozeit/features/transcript/bloc/transcript_cubit.dart';
import 'package:radiozeit/utils/extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AppSettings {
  late SharedPreferences _prefs;

  static AppSettings? _instance;

  static AppSettings getInstance() {
    _instance ??= AppSettings._();
    return _instance!;
  }

  AppSettings._();

  loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
  }

  saveFavoriteList(List<String> ids) {
    _prefs.setString("favorites", ids.join(","));
  }

  List<String> getFavoriteList() {
    String favorite = _prefs.getString("favorites") ?? "";
    if(favorite.isEmpty) return [];
    return favorite
        .split(",")
        .toList();
  }

  setLastRadio(String id) async {
    await _prefs.setString("last_radio", id);
  }

  String getLastRadioId() {
    return _prefs.getString("last_radio") ?? "";
  }

  String getThemeType() {
    return _prefs.getString("theme_type") ?? AppStyle.themeDark;
  }

  setThemeType(String flag) async{
    await _prefs.setString("theme_type",flag);
  }

  setSpeed(TranscriptSpeed speed) {
    _prefs.setString("speed", speed.toString());
  }

  TranscriptSpeed getSpeed() {
    String size = _prefs.getString("speed") ?? "";
    if(size.isEmpty) {
      return TranscriptSpeed.speedNormal;
    }
    return TranscriptSpeed.values
        .firstOrNullWhere((e) => e.toString() == size) ?? TranscriptSpeed.speedNormal;
  }

  setTextSize(TranscriptFontSize size) {
    _prefs.setString("textSile", size.toString());
  }

  saveLocation(Location? location) {
    _prefs.setString("location", location?.toString() ?? "");
  }


  Location? getLocation() {
    String location = _prefs.getString("location") ?? "";
    return Location.fromString(location);
  }

  TranscriptFontSize getTextSize() {
    String size = _prefs.getString("textSile") ?? "";
    if(size.isEmpty) {
      return TranscriptFontSize.medium;
    }
    return TranscriptFontSize.values
        .firstOrNullWhere((e) => e.toString() == size) ?? TranscriptFontSize.medium;
  }
  saveLang(TranslateLang lang) {
    _prefs.setString("lang", lang.toString());
  }

  TranslateLang? getLang() {
    String lang = _prefs.getString("lang") ?? "";
    if(lang.isEmpty) {
      return null;
    }
    var parts = lang.split("_");
    return TranslateLang(title: parts[1],code: parts[0]);
  }


  bool get isAskLocationLater => _prefs.getBool("isAskLocationLather") ?? false;
  set isAskLocationLater(bool value) => _prefs.setBool("isAskLocationLather",value);

  bool get isFirstStart => _prefs.getBool("isFirstStart") ?? true;
  set isFirstStart(bool value) => _prefs.setBool("isFirstStart",value);
  int get restartAppCountBeforeAskLocation => _prefs.getInt("restartAppCountBeforeAskLocation") ?? 0;
  set restartAppCountBeforeAskLocation(int value) => _prefs.setInt("restartAppCountBeforeAskLocation",value);
  bool get isUserEnableLocation => _prefs.getBool("isUserEnableLocation") ?? false;
  set isUserEnableLocation(bool value) => _prefs.setBool("isUserEnableLocation",value);

  set gpsCity(City city) => _prefs.setString("locationCity", city.toString());
  City get gpsCity => City.fromString(_prefs.getString("locationCity"));

  setManualCity(LocationCity? city) async =>  await _prefs.setString("manual_city", city?.toString() ?? "");
  LocationCity? get manualCity => LocationCity.fromString(_prefs.getString("manual_city"));

  bool hasSelectedLang() => _prefs.containsKey("lang");

  Future<String> getDeviceId() async{



    if(_prefs.containsKey("device_id")) {
      return _prefs.getString("device_id") ?? "";
    }

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String? id;
    try {
      if(Platform.isAndroid) {
        id = await const AndroidId().getId();
      } else {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        id = iosInfo.identifierForVendor;
      }
    } catch (e) {
      // empty
    }

    id ??= const Uuid().v4();

    _prefs.setString("device_id", id);
    return id;
  }

  String getAppLang() {
    String lang = _prefs.getString("app_lang") ?? "";
    if(lang.isEmpty) {
      lang = Platform.localeName.toLowerCase().contains("de") ? "de" : "en";
    }
    return lang;
  }

  setAppLang(String lang) {
    _prefs.setString("app_lang", lang);
  }

}