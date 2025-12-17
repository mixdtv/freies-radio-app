import 'package:flutter/cupertino.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/data/model/radio_program.dart';

class AppDataRepository {
  int offsetSec = 0;
  ValueNotifier<RadioEpg?> activeProgram = ValueNotifier(null);
  ValueNotifier<AppRadio?> activeRadio = ValueNotifier(null);


  playRadio(AppRadio radio) {
    offsetSec = 0;
    activeProgram.value = null;
    activeRadio.value = radio;
  }

  playArchiveEpg(RadioEpg epg) {
    offsetSec = DateTime.now().second - epg.start.second;
    activeProgram.value = epg;
  }

  DateTime getPlayingDate() {
    return DateTime.now().subtract(Duration(seconds: offsetSec));
  }
}