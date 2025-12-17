import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:radiozeit/app/style.dart';
import 'package:radiozeit/app/theme_cubit.dart';
import 'package:radiozeit/app/widgets/input/input_radio.dart';
import 'package:radiozeit/l10n/app_localizations.dart';

class AppearancePage extends StatefulWidget {
  static const String path = "/AppearancePage";
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  @override
  Widget build(BuildContext context) {
    String themeType = context.select((ThemeCubit bloc) => bloc.state.themeType);
    return Scaffold(
      appBar: AppBar(
        title: Text( AppLocalizations.of(context)!.title_appearance,style: Theme.of(context).textTheme.displayLarge,),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 14,),
          _row(
            title: AppLocalizations.of(context)!.color_shame_light,
            groupValue: themeType,
            onChanged: (value) {
              context.read<ThemeCubit>().setTheme(AppStyle.themeLight);
            },
            value: AppStyle.themeLight
          ),
          _row(
              title: AppLocalizations.of(context)!.color_shame_dark,
              groupValue: themeType,
              onChanged: (value) {
                context.read<ThemeCubit>().setTheme(AppStyle.themeDark);
              },
              value: AppStyle.themeDark
          ),
          _row(
              title: AppLocalizations.of(context)!.color_shame_auto,
              groupValue: themeType,
              onChanged: (value) {
                context.read<ThemeCubit>().setTheme(AppStyle.themeAuto);
              },
              value: AppStyle.themeAuto,
            desc: AppLocalizations.of(context)!.color_shame_desc_auto
          )
        ],
      ),

    );
  }

  _row({
    required String title,
    required String groupValue,
    required String value,
    required Function(String? value) onChanged,
    String desc = ""
}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(value),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 14),
          padding: EdgeInsets.only(bottom: 14,top: 16),
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2)))
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w500),),
                  ),
                  AppInputRadio(value: value, groupValue: groupValue)
                ],
              ),
              if(desc.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(desc,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
                        fontWeight: FontWeight.w300)),
              ),
            ],
          ),
        ),
      ),
    );
}
}
