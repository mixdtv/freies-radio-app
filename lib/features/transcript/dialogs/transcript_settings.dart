import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/data/model/translate_lang.dart';
import 'package:radiozeit/features/player/player_cubit.dart';
import 'package:radiozeit/features/transcript/bloc/transcript_cubit.dart';
import 'package:radiozeit/features/transcript/widgets/button_switch.dart';
import 'package:radiozeit/utils/consts.dart';
import 'package:radiozeit/utils/extensions.dart';
import 'package:radiozeit/utils/settings.dart';

class TranscriptSettings extends StatefulWidget {
  const TranscriptSettings({super.key});

  @override
  State<TranscriptSettings> createState() => _TranscriptSettingsState();
}

class _TranscriptSettingsState extends State<TranscriptSettings> {

  ValueNotifier<TranscriptSpeed> speed = ValueNotifier(TranscriptSpeed.speedNormal);
  ValueNotifier<TranscriptFontSize> fontSize = ValueNotifier(TranscriptFontSize.medium);
  ValueNotifier<TranslateLang?> selectedLang = ValueNotifier(null);
  TranslateLang? radioLang;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var cubitState = context.read<TranscriptCubit>().state;
      speed.value = cubitState.speed;
      fontSize.value = cubitState.fontSize;
      selectedLang.value = cubitState.selectedLang;
      radioLang = cubitState.radioLang;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          // constraints: BoxConstraints(
          //   maxWidth: 350
          // ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16)

                )
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Text("Settings",style: Theme.of(context).textTheme.headlineLarge,)),
                  CloseButton()
                ],
              ),
              const SizedBox(height: 32,),
              _translateSettings(context),
              const SizedBox(height: 32,),
              _playerSpeedSettings(context),
              const SizedBox(height: 32,),
              _fontSizeSettings(context),
              const SizedBox(height: 32,),
              _saveButton(context),

            ],
          ),
        ),
      ],
    );
  }

  _translateSettings(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        _settingsTitle(textTheme, "assets/icons/ic_translate.svg", "Transcription"),
        const SizedBox(height: 12,),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 125,
              height: 46,
              child: AppButtonSwitch(
                  isSelect: false,
                  onSelect: (box) {},
                  child: Opacity(
                    opacity: 0.5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(radioLang?.title ?? "",
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500
                          )),
                        Text("Detected",style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500
                        )),
                      ],
                    ),
                  )
              ),
            ),

            Icon(Icons.arrow_forward,size: 24),

            Container(
              width: 125,
              height: 46,
              margin: EdgeInsets.only(right: 4),
              child: AppButtonSwitch(
                  isSelect: false,
                  onSelect: _showSelectLang,
                  child: Center(child: ValueListenableBuilder(
                    valueListenable: selectedLang,
                    builder: (context,lang,child) {
                      return Text(lang?.title.capitalize() ?? "",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500
                      ),);
                    }
                  ))
              ),
            ),
          ],
        )
      ],
    );
  }

  _playerSpeedSettings(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return ValueListenableBuilder(
      valueListenable: speed,
  builder: (context, value,child) {
    return Column(
      children: [
        _settingsTitle(textTheme, "assets/icons/ic_speed.svg", "Speed"),
        const SizedBox(height: 12,),
        Row(
          children: [
            Container(
              width: 99,
              height: 46,
              margin: const EdgeInsets.only(right: 4),
              child: AppButtonSwitch(
                  isSelect: value == TranscriptSpeed.speed05,
                  onSelect: (box) {
                    speed.value = TranscriptSpeed.speed05;
                  },
                  child: const Center(child: Text("0,5 x"))
              ),
            ),

            Container(
              width: 99,
              height: 46,
              margin: const EdgeInsets.only(right: 4),
              child: AppButtonSwitch(
                  isSelect: value == TranscriptSpeed.speed075,
                  onSelect: (box) {
                    speed.value = (TranscriptSpeed.speed075);
                  },
                  child: const Center(child: Text("0,75 x"))
              ),
            ),

            Container(
              width: 99,
              height: 46,
              child: AppButtonSwitch(
                  isSelect: value == TranscriptSpeed.speedNormal,
                  onSelect: (box) {
                    speed.value = (TranscriptSpeed.speedNormal);
                  },
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("1 x"),
                      Text("Normal speed"),
                    ],
                  )
              ),
            ),
          ],
        )
      ],
    );
  },
);
  }

  _fontSizeSettings(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return ValueListenableBuilder(
      valueListenable: fontSize,
  builder: (context, fontSizeValue,child) {
    return Column(
      children: [
        _settingsTitle(textTheme, "assets/icons/ic_font.svg", "Font Size"),
        const SizedBox(height: 12,),
        Row(
          children: [
            Container(
              width: 99,
              height: 46,
              margin: EdgeInsets.only(right: 4),
              child: AppButtonSwitch(
                  isSelect: fontSizeValue == TranscriptFontSize.small,
                  onSelect: (box) {
                    fontSize.value = (TranscriptFontSize.small);
                  },
                  child: Center(child: Text("Small"))
              ),
            ),

            Container(
              width: 99,
              height: 46,
              margin: EdgeInsets.only(right: 4),
              child: AppButtonSwitch(
                  isSelect: fontSizeValue == TranscriptFontSize.medium,
                  onSelect: (box) {
                    fontSize.value = (TranscriptFontSize.medium);
                  },
                  child: Center(child: Text("Medium"))
              ),
            ),

            Container(
              width: 99,
              height: 46,
              child: AppButtonSwitch(
                  isSelect: fontSizeValue == TranscriptFontSize.big,
                  onSelect: (box) {
                    fontSize.value = (TranscriptFontSize.big);
                  },
                  child: Center(child: Text("Big"))
              ),
            ),
          ],
        )
      ],
    );
  },
);
  }

  _settingsTitle(TextTheme theme,String icon,String text) {
    return Row(
      children: [
        SvgPicture.asset(icon,color: theme.displaySmall?.color,),
        const SizedBox(width: 8,),
        Text(text,style: theme.displaySmall?.copyWith(fontWeight: FontWeight.w700),)
      ],
    );
  }

  _applySettings(BuildContext context) {
    var cubit = context.read<TranscriptCubit>();
    cubit.setFontSize(fontSize.value);
    cubit.setSpeed(speed.value);
    cubit.selectLang(selectedLang.value);
    Navigator.of(context).pop();
  }

  _saveButton(BuildContext context) {
    ThemeData theme = Theme.of(context);
    TextTheme textTheme = theme.textTheme;
    bool isDark = theme.brightness == Brightness.dark;
    return SizedBox(
        width: double.infinity,
      child: FilledButton(
        onPressed: () => _applySettings(context),
        child: Text("Save",style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700,color:!isDark ? Colors.white : Colors.black),),
        style: ButtonStyle(
          padding: MaterialStatePropertyAll(EdgeInsets.all(12)),
          shape: MaterialStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)
          )),
            backgroundColor: MaterialStatePropertyAll(isDark ? Colors.white : Colors.black)
        ),
      ),
    );
  }


  _showSelectLang(RenderBox box) {
    var langs = context.read<TranscriptCubit>().state.langs;
    var position = box.localToGlobal(Offset.zero);
    showMenu(context: context,
        position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + box.size.width, 300),
        items: langs.map((e) => PopupMenuItem(child: Text(e.title.capitalize()),value: e,)).toList(),
    ).then((value) {
      selectedLang.value = value;
    });
  }
}
