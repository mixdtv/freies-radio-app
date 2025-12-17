import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppColors {
  static const Color orange = Color(0xffF94E18);
  static const Color green = Color(0xff0DC942);
  static const Color buttonGray = Color(0xff2B282F);
}

class AppGradient { //background: linear-gradient(96deg, rgba(32, 30, 35, 0.60) 31.51%, rgba(57, 53, 62, 0.60) 90.27%), #201E23;
  static LinearGradient getPanelGradient(BuildContext context) {
    if(Theme.of(context).brightness == Brightness.dark) {
      return panelGradientDark;
    }
    return panelGradientLight;
  }

  static const shimmerGradient = LinearGradient(
    colors: [
      Color(0xFFEBEBF4),
      Color(0xFFF4F4F4),
      Color(0xFFEBEBF4),
    ],
    stops: [
      0.1,
      0.3,
      0.4,
    ],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
    tileMode: TileMode.clamp,
  );
  static const LinearGradient panelGradientDark = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.topRight,
      colors: [
    Color(0xff201E23),
    Color(0xff302C33),
  ]);

  static const LinearGradient panelGradientLight = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.topRight,
      colors: [
    Color(0xffEFF2F5),
    Color(0xffEFF2F5),
  ]);
}