import 'package:flutter/material.dart';

import 'package:radiozeit/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class RadioNotFoundInfo extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Opacity(
            opacity: 0.6,
            child: Text(AppLocalizations.of(context)!.search_not_found_info, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center,)),
        const SizedBox(height: 19,),
        TextButton(onPressed: () {
          final Uri emailLaunchUri = Uri(
              scheme: 'mailto',
              path: 'station-request@radiozeit.de',
          );
          launchUrl(emailLaunchUri);

        }, child: Text(AppLocalizations.of(context)!.search_not_found_button,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700,decoration: TextDecoration.underline)
          )
        ),
      ],
    );
  }

}
