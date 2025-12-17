import 'package:bloc_presentation/bloc_presentation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:radiozeit/app/widgets/buttons/color_button.dart';
import 'package:radiozeit/features/location/location_cubit.dart';
import 'package:radiozeit/features/location/location_request_view.dart';
import 'package:radiozeit/features/location/location_service.dart';
import 'package:radiozeit/features/radio_list/cubit/radio_list_cubit.dart';
import 'package:radiozeit/features/radio_list/radio_list_page.dart';
import 'package:radiozeit/utils/colors.dart';
import 'package:radiozeit/utils/settings.dart';
import 'package:radiozeit/l10n/app_localizations.dart';

class LocationRequestPage extends StatelessWidget {
  static const path = "/LocationRequestPage";

  const LocationRequestPage({super.key});


  static showAsDialog(BuildContext appContext) {

    showGeneralDialog(
      context: appContext,
      pageBuilder: (context, animation, secondaryAnimation) {
        return BlocProvider.value(
         value: appContext.read<RadioListCubit>(),
          child: BlocPresentationListener<LocationCubit, LocationEvents>(
            listener: (context, event) {
              if (event is LocationEnabledEvent) {
                Navigator.of(context).pop();
                context.read<RadioListCubit>().startLoadRadio();
              }
              if (event is LocationLaterEvent) {
                Navigator.of(context).pop();
              }

              if (event is LocationErrorEvent) {
                if(event.status == LocationPermissionStatus.FORBIDDEN_FOREVER) {
                  _showSettingsDialog(context);
                } else if(event.status == LocationPermissionStatus.FORBIDDEN) {
                  _onError(context, "Location permissions are denied");
                } else if(event.status == LocationPermissionStatus.DISABLED) {
                  _onError(context, "Location services are disabled.");
                }

              }
            },
            child: const LocationRequestView(),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return BlocPresentationListener<LocationCubit, LocationEvents>(
      listener: (context, event) {
        if (event is LocationEnabledEvent || event is LocationLaterEvent) {
          context.go(RadioListPage.path);
        }

        if (event is LocationErrorEvent) {
          context.go(RadioListPage.path);

        }
      },
      child: const LocationRequestView(),
    );
  }

  static _onError(BuildContext context, String error) {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.title_error),
        content: Text(error),
        actions: [
          TextButton(onPressed: () {
            Navigator.of(context).pop();
          }, child: Text(AppLocalizations.of(context)!.title_ok))
        ],
      );
    },);
  }
  static _showSettingsDialog(BuildContext context) {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.title_error),
        content: Text(AppLocalizations.of(context)!.location_disable_forever),
        actions: [
          TextButton(onPressed: () {
            Navigator.of(context).pop();
          }, child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(onPressed: () {
            Navigator.of(context).pop();
            Geolocator.openLocationSettings();
          }, child: Text(AppLocalizations.of(context)!.settings))
        ],
      );
    },);
  }
}
