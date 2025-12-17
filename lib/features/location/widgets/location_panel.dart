import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:radiozeit/app/widgets/input/input_search.dart';
import 'package:radiozeit/features/location/widgets/location_toggle_button.dart';
import 'package:radiozeit/l10n/app_localizations.dart';

class LocationPanel extends StatelessWidget {
  final bool isEnableLocation;
  final Function() onSearch;
  final Function() onToggleLocation;

  const LocationPanel({super.key, required this.isEnableLocation, required this.onSearch, required this.onToggleLocation});
  
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: InputSearch(isActive: false,hint: AppLocalizations.of(context)!.input_placeholder_search_city, onTap: onSearch)),
        const SizedBox(width: 16,),
        LocationToggleButton(
          isEnable: isEnableLocation,
          onClick: onToggleLocation,
        )
      ],
    );
  }
}
