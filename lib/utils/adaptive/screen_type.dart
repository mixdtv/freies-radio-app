import 'package:flutter/cupertino.dart';
import 'package:radiozeit/utils/adaptive/form_factor.dart';

enum ScreenType {
  big,small;

  static ScreenType getFormFactor(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.shortestSide;
    //print("Size ${MediaQuery.of(context).size} deviceWidth $deviceWidth");
    if (deviceWidth > FormFactor.tablet) return ScreenType.big;
     return ScreenType.small;
  }
}