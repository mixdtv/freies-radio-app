import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:radiozeit/app/pages/appearance_page.dart';
import 'package:radiozeit/app/style.dart';
import 'package:radiozeit/app/theme_cubit.dart';
import 'package:radiozeit/app/widgets/input/input_radio.dart';
import 'package:radiozeit/features/auth/session_cubit.dart';
import 'package:radiozeit/features/transcript/widgets/button_switch.dart';
import 'package:radiozeit/utils/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:radiozeit/l10n/app_localizations.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {


  @override
  Widget build(BuildContext context) {
    String themeType = context.select((ThemeCubit bloc) => bloc.state.themeType);

    return SafeArea(
      child: Container(

        width: MediaQuery.of(context).size.width - 34,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 7,
              offset: Offset(7, 0)
            )
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CloseButton(),
            Expanded(
              child: Container(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Image.asset("assets/images/logo_freies_radio.png", width: 200),
                  )),
            ),
            _row(
              context: context,
              icon: "assets/icons/ic_mode.svg",
              title: AppLocalizations.of(context)!.title_appearance,
              status: _themeTypeName(context,themeType),
              onSelect: () => _toThemeSettings(context),
            ),
            Builder(builder: (context) {
              String lang = context.select((SessionCubit bloc) => bloc.state.lang);
              return _row(
                context: context,
                icon: "assets/icons/ic_globe.svg",
                title: AppLocalizations.of(context)!.title_language,
                status: lang == "de" ? AppLocalizations.of(context)!.lang_de : AppLocalizations.of(context)!.lang_en,
                onSelect: () {
                  _showLangMenu(context);
                },
              );
            },),
            const SizedBox(height: 22,),
            _subButton(
              context: context,
              title: AppLocalizations.of(context)!.title_legal,
              onTap: () {
                try {
                  launchUrlString("https://freies-radio.radiozeit.de/legal/");
                } catch (e) {
                  // empty
                }
              },
            ),
            // _subButton(
            //   context: context,
            //   title: "About us",
            //   onTap: () {},
            // ),
            _subButton(
              context: context,
              title: AppLocalizations.of(context)!.title_contact_us,
              onTap: () {
                // launchUrl with email inquiry@radiozeit.de
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'info@radiozeit.de',
                  // query: encodeQueryParameters(<String, String>{
                  //   'subject': 'Example Subject & Symbols are allowed!',
                  // }),
                );
                try {
                  launchUrl(emailLaunchUri);
                } catch (e) {
                  // empty
                }
              },
            ),
            const SizedBox(height: 22,),
          ],
        ),
      ),
    );
  }

  String _themeTypeName(BuildContext context,String type) {
    switch(type) {
      case AppStyle.themeDark: return AppLocalizations.of(context)!.color_shame_dark;
      case AppStyle.themeLight: return AppLocalizations.of(context)!.color_shame_light;
      default: return AppLocalizations.of(context)!.color_shame_auto;
    }
  }

  _toThemeSettings(BuildContext context) {
    context.push(AppearancePage.path);
  }

  _row({
    required BuildContext context,
    required String icon,
    required String title,
    required String status,
    required Function() onSelect,
    bool isLoading = false,
    bool showArrow = true,
}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 24),
          padding: EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2)))
          ),
          child: Row(
            children: [
              SvgPicture.asset(icon,color: Theme.of(context).colorScheme.onBackground,),
              const SizedBox(width: 14,),
              Text(title,style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w500),),
              Expanded(child: SizedBox()),
              Text(status,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
                    fontWeight: FontWeight.w300),),
              const SizedBox(width: 8,),
              if(showArrow)
                SvgPicture.asset("assets/icons/ic_arrow_right.svg",color: Theme.of(context).colorScheme.onBackground,),
              if(isLoading)
                SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(color: AppColors.orange,))
            ],
          ),
        ),
      ),
    );
  }

  _subButton({
    required BuildContext context,
    required String title,
    required Function() onTap,
    bool isLoading = false
}) {

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 10),
              child: Text(title,style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),),
            ),
            if(isLoading)
              SizedBox(

                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(color: AppColors.orange,)),
          ],
        ),
      ),
    );
  }

  _showLangMenu(BuildContext appContext) {
    showModalBottomSheet(
      context: appContext,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(12),topRight: Radius.circular(12))
      ),
      builder: (context) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: appContext.read<SessionCubit>()),
          ],
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8,bottom: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CloseButton(color: Theme.of(context).colorScheme.onBackground),
                    Text(AppLocalizations.of(context)!.title_language,style: Theme.of(context).textTheme.displayLarge,),
                    SizedBox(width: 32,),
                  ],
                ),
              ),
              Divider(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2),height: 24,thickness: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 8),
                child: Builder(
                  builder: (context) {
                    String lang = context.select((SessionCubit bloc) => bloc.state.lang);
                    return Column(
                      children: [
                        InkWell(
                          onTap: () {
                            context.read<SessionCubit>().selectLang("en");
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                AppInputRadio(value: "en", groupValue: lang),
                                const SizedBox(width: 8,),
                                Text(AppLocalizations.of(context)!.lang_en)
                              ],
                            ),
                          ),
                        ),InkWell(
                          onTap: () {
                            context.read<SessionCubit>().selectLang("de");
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                AppInputRadio(value: "de", groupValue: lang),
                                const SizedBox(width: 8,),
                                Text(AppLocalizations.of(context)!.lang_de)
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
