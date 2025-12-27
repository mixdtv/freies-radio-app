import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:radiozeit/app/widgets/buttons/color_button.dart';
import 'package:radiozeit/features/location/location_request_page.dart';
import 'package:radiozeit/utils/colors.dart';
import 'package:radiozeit/utils/settings.dart';
import 'package:radiozeit/l10n/app_localizations.dart';

class SplashPage extends StatelessWidget {
  static const path = "/SplashPage";
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Expanded(child: SizedBox(width: double.infinity)),
              Theme.of(context).brightness == Brightness.dark
                  ? Image.asset("assets/images/splash_app.png", width: 200)
                  : Image.asset("assets/images/splash_app_black.png", width: 200),
              const SizedBox(height: 42),
              Text(
                AppLocalizations.of(context)!.splash_text_description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const Expanded(child: SizedBox()),
              ColorButton(
                onPressed: () => _onNext(context),
                color: AppColors.orange,
                text: AppLocalizations.of(context)!.splash_button_start,
              ),
            ],
          ),
        ),
    );
  }

  _onNext(BuildContext context) {
    AppSettings.getInstance().isFirstStart = false;
    context.go(LocationRequestPage.path);
  }
}
