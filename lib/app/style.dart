import 'package:flutter/material.dart';

class AppStyle {

  static const String fontDMMono = "DMMono";
  static const String fontInter = "inter";
  static const String themeDark = "dark";
  static const String themeLight = "light";
  static const String themeAuto = "auto";

  static const inputColorDark = Color(0xff2B282F);
  static const inputColorLight = Color(0xffe8e8e8);

  static ThemeData dark() {
    return  ThemeData(
        colorScheme: ColorScheme(
            brightness: Brightness.dark,
            primary: Color(0xff17161A),
            onPrimary: Colors.white,
            secondary: Color(0xff2F2C33),
            onSecondary: Colors.white,
            error: Colors.red,
            onError: Colors.white,
            background: Color(0xff0E0E0F),
            onBackground: Colors.white,
            surface: Color(0xff17161A),
            onSurface: Colors.white,
        ),

        dividerTheme: DividerThemeData(
          color: Colors.white.withOpacity(0.2),
        ),
       actionIconTheme: ActionIconThemeData(
         backButtonIconBuilder: (context) {
           return const Icon(Icons.chevron_left,size: 28,);
         },
       ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(

            textStyle: WidgetStateProperty.all(TextStyle(
                fontSize: 15,
                fontFamily:"inter",
                fontWeight: FontWeight.w700,
                color: Colors.white
            )),
            padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 0,vertical: 8)),
            shape: WidgetStateProperty.all(LinearBorder(
                bottom: LinearBorderEdge()
            )),
          )

        ),
        filledButtonTheme: FilledButtonThemeData(
            style: ButtonStyle(
              backgroundColor: MaterialStatePropertyAll(Color(0xff2F2F2F)),
              textStyle: MaterialStatePropertyAll(TextStyle(fontFamily:"inter",fontSize: 13,color: Colors.white,fontWeight: FontWeight.w400,height: 1.46))
            )
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: MaterialStatePropertyAll(Colors.white),
            textStyle: MaterialStatePropertyAll(TextStyle(
                fontSize: 13,
                fontFamily:"inter",
                fontWeight: FontWeight.w500,
                color: Colors.white
            ))
          )
        ),
        textSelectionTheme: TextSelectionThemeData(
            cursorColor: Colors.white,
            selectionHandleColor:  Colors.white
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xff4A4450)),
            borderRadius: BorderRadius.circular(40)
          ),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: inputColorDark),
              borderRadius: BorderRadius.circular(40)
          ),

          filled: true,
          fillColor:inputColorDark,
          isDense: true,

          contentPadding: const EdgeInsets.symmetric(horizontal: 12,vertical: 10),
          hintStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.3)
          ),

        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: Colors.white,
          trackHeight: 2,
          thumbColor: Colors.white,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 4),
          inactiveTrackColor: Color(0xff6C6C6F),
            overlayShape: SliderComponentShape.noOverlay
        ),
        fontFamily: "inter",
        textTheme: getTextStyle(isDark: true));
  }

  static ThemeData light() {
    return  ThemeData(

        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xffEFF2F5),
          onPrimary: Colors.black,
          secondary: Color(0xffEFF2F5),
          onSecondary: Colors.black,
          error: Colors.red,
          onError: Colors.white,
          background: Color(0xffEAEDF0),
          onBackground: Colors.black,
          surface: Color(0xffEFF2F5),
          onSurface: Colors.black
      ),

        dividerTheme: DividerThemeData(
          color: Colors.black.withOpacity(0.2),
        ),
        actionIconTheme: ActionIconThemeData(
          backButtonIconBuilder: (context) {
            return const Icon(Icons.chevron_left,size: 28,);
          },
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: ButtonStyle(

              textStyle: WidgetStateProperty.all(TextStyle(
                  fontSize: 15,
                  fontFamily:"inter",
                  fontWeight: FontWeight.w700,
                  color: Colors.black
              )),
              padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 0,vertical: 8)),
              shape: WidgetStateProperty.all(LinearBorder(
                  bottom: LinearBorderEdge()
              )),
            )

        ),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStatePropertyAll(Color(0xffEFF2F5)),
            textStyle: MaterialStatePropertyAll(TextStyle(fontFamily:"inter",fontSize: 13,color: Colors.black,fontWeight: FontWeight.w400,height: 1.46))
          )
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: Color(0xff0A0A0A),
          trackHeight: 2,
          thumbColor: Color(0xff0A0A0A),
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 4),
          inactiveTrackColor: Color(0xff0A0A0A).withOpacity(0.4),
            overlayShape: SliderComponentShape.noOverlay
        ),
        textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(
                foregroundColor: MaterialStatePropertyAll(Colors.black),
                textStyle: MaterialStatePropertyAll(TextStyle(
                    fontSize: 13,
                    fontFamily:"inter",
                    fontWeight: FontWeight.w500,
                    color: Colors.black
                ))
            )
        ),
        textSelectionTheme: TextSelectionThemeData(
            cursorColor: Colors.black,
            selectionHandleColor: Colors.black,
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
              borderRadius: BorderRadius.circular(40)
          ),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xffEFF2F5)),
              borderRadius: BorderRadius.circular(40)
          ),
          filled: true,
          fillColor:Color(0xffEFF2F5),
          isDense: true,

          contentPadding: const EdgeInsets.symmetric(horizontal: 12,vertical: 10),
          hintStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black.withOpacity(0.3)
          ),

        ),
      textTheme: getTextStyle(isDark: false)
    );
  }

  static TextTheme getTextStyle({required bool isDark}) {

    Color textColor = isDark ? Colors.white : Colors.black;

    return TextTheme(

      headlineLarge: TextStyle(fontFamily:"inter",fontSize: 26,color: textColor,fontWeight: FontWeight.w700,height: 1.46), //
      headlineMedium: TextStyle(fontFamily:"inter",fontSize: 24,color: textColor,fontWeight: FontWeight.w700,height: 1.46),
      headlineSmall: TextStyle(fontFamily:"inter",fontSize: 18,color: textColor,fontWeight: FontWeight.w700,height: 1.46),

      displayLarge: TextStyle(fontFamily:"inter",fontSize: 17,color: textColor,fontWeight: FontWeight.w700,height: 1.46),
      displayMedium: TextStyle(fontFamily:"inter",fontSize: 16,color: textColor,fontWeight: FontWeight.w400,height: 1.46),
      displaySmall: TextStyle(fontFamily:"inter",fontSize: 15,color: textColor,fontWeight: FontWeight.w400,height: 1.46),

      bodyLarge: TextStyle(fontFamily:"inter",fontSize: 13,color: textColor,fontWeight: FontWeight.w400,height: 1.46),
      bodyMedium: TextStyle(fontFamily:"inter",fontSize: 12,color: textColor,fontWeight: FontWeight.w400,height: 1.46),
      bodySmall: TextStyle(fontFamily:"inter",fontSize: 10,color: textColor,fontWeight: FontWeight.w400,height: 1.46),

      titleMedium: TextStyle(fontFamily:"inter",fontSize: 14,color: textColor,fontWeight: FontWeight.w400,height: 1.46),
      titleSmall: TextStyle(fontFamily:"inter",fontSize: 11,color: textColor,fontWeight: FontWeight.w400,height: 1.46),

// not use


       //

      labelSmall: TextStyle(fontFamily:"inter",fontSize: 11,color: textColor,fontWeight: FontWeight.w400,height: 1.46),
      labelLarge: TextStyle(fontFamily:"inter",fontSize: 16,color: textColor,fontWeight: FontWeight.w400,height: 1.46),
      labelMedium: TextStyle(fontFamily:"inter",fontSize: 13,color: textColor,fontWeight: FontWeight.w600,height: 1.46),

      titleLarge: TextStyle(fontFamily:"inter",fontSize: 17,color: textColor,fontWeight: FontWeight.w700,height: 1.46), //








    );
  }
}