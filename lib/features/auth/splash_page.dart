import 'package:bloc_presentation/bloc_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:radiozeit/app/widgets/buttons/color_button.dart';
import 'package:radiozeit/features/auth/session_cubit.dart';
import 'package:radiozeit/features/location/location_request_page.dart';
import 'package:radiozeit/features/radio_list/radio_list_page.dart';
import 'package:radiozeit/utils/colors.dart';
import 'package:radiozeit/utils/settings.dart';
import 'package:radiozeit/l10n/app_localizations.dart';

class SplashPage extends StatefulWidget {
  static const path = "/SplashPage";
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool isFirstStart = AppSettings.getInstance().isFirstStart;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionCubit>().initializeSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocPresentationListener<SessionCubit, SessionEvents>(
      listener: (context, event) {
        if (event is SessionStartEvent && !AppSettings.getInstance().isFirstStart) {
          context.go(RadioListPage.path);
        }
      },
      child: Scaffold(
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
              if (isFirstStart)
                ColorButton(
                  onPressed: () => _onNext(context),
                  color: AppColors.orange,
                  text: AppLocalizations.of(context)!.splash_button_start,
                ),
            ],
          ),
        ),
      ),
    );
  }

  _onNext(BuildContext context) {
    AppSettings.getInstance().isFirstStart = false;
    context.go(LocationRequestPage.path);
  }
}
