import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:radiozeit/l10n/app_localizations.dart';


class LocationToggleButton extends StatelessWidget {
  final bool isEnable;
  final bool isLoading;
  final Function() onClick;

  const LocationToggleButton({super.key, this.isEnable = false, this.isLoading= false, required this.onClick});

  @override
  Widget build(BuildContext context) {

    return Material(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
            onTap: onClick,
            borderRadius: BorderRadius.circular(40),
            child: Opacity(
              opacity: isEnable ?  1.0 : 0.3,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12,vertical: 10),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: isEnable ? Colors.white : Colors.transparent)
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(isEnable ? "assets/icons/ic_location.svg" : "assets/icons/ic_location_disabled.svg",
                      width: 16,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                    const SizedBox(width: 10,),
                    Text(isEnable ? AppLocalizations.of(context)!.button_location_on : AppLocalizations.of(context)!.button_location_off,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                    )
                  ],
                ),
              ),
            )));
  }
}
