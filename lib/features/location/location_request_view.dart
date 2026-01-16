import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:radiozeit/app/widgets/buttons/color_button.dart';
import 'package:radiozeit/features/location/location_cubit.dart';
import 'package:radiozeit/utils/colors.dart';
import 'package:radiozeit/utils/settings.dart';
import 'package:radiozeit/l10n/app_localizations.dart';

class LocationRequestView extends StatefulWidget {
  const LocationRequestView({super.key});

  @override
  State<LocationRequestView> createState() => _LocationRequestViewState();
}

class _LocationRequestViewState extends State<LocationRequestView> {
  bool _showWelcome = false;

  @override
  void initState() {
    super.initState();
    _showWelcome = AppSettings.getInstance().isFirstStart;
  }

  void _onStart() {
    AppSettings.getInstance().isFirstStart = false;
    setState(() {
      _showWelcome = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
          children: [
            const Expanded(child: SizedBox()),
            Image.asset("assets/images/logo_freies_radio.png", width: 140),
            const SizedBox(height: 24),
            Text(
              _showWelcome
                  ? AppLocalizations.of(context)!.splash_text_description
                  : AppLocalizations.of(context)!.location_page_title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (!_showWelcome) ...[
              const SizedBox(height: 12),
              Opacity(
                opacity: 0.6,
                child: Text(
                  AppLocalizations.of(context)!.location_page_desc,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w400),
                ),
              ),
            ],
            const Expanded(child: SizedBox()),
            if (_showWelcome)
              ColorButton(
                onPressed: _onStart,
                color: AppColors.orange,
                text: AppLocalizations.of(context)!.splash_button_start,
              )
            else
              Builder(
                builder: (context) {
                  bool isLoading = context.select((LocationCubit cubit) => cubit.state.isLoading);
                  return ColorButton(
                    isLoading: isLoading,
                    onPressed: () {
                      context.read<LocationCubit>().enableLocation();
                    },
                    color: AppColors.orange,
                    text: AppLocalizations.of(context)!.location_button_allow,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
