import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:radiozeit/app/widgets/buttons/color_button.dart';
import 'package:radiozeit/features/location/location_cubit.dart';
import 'package:radiozeit/utils/colors.dart';
import 'package:radiozeit/l10n/app_localizations.dart';

class LocationRequestView extends StatelessWidget {


  const LocationRequestView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Expanded(child: SizedBox()),
            SvgPicture.asset("assets/images/location_logo.svg",width: 68,),
            const SizedBox(height: 24,),
            Text(AppLocalizations.of(context)!.location_page_title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,),
            const SizedBox(height: 12,),
            Opacity(
              opacity: 0.6,
              child: Text(AppLocalizations.of(context)!.location_page_desc,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w400),),
            ),
            const Expanded(child: SizedBox()),
            Builder(
              builder: (context) {
                bool isLoading = context.select((LocationCubit cubit) => cubit.state.isLoading);
                return ColorButton(
                    isLoading: isLoading,
                    onPressed: () {
                      context.read<LocationCubit>().enableLocation();
                    },
                    color: AppColors.orange,
                    text: AppLocalizations.of(context)!.location_button_allow
                );
              }
            ),
            // const SizedBox(height: 16,),
            // ColorButton(
            //     onPressed: () {
            //       context.read<LocationCubit>().askLocationLater();
            //     },
            //     color: AppColors.buttonGray,
            //     text: AppLocalizations.of(context)!.location_button_later
            // ),
          ],
        ),
      ),
    );
  }
}
