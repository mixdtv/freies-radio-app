import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:radiozeit/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
        const SizedBox(height: 8,),
        TextButton(onPressed: () {
          try {
            launchUrlString("https://freies-radio.radiozeit.de/legal/");
          } catch (e) {
            // empty
          }
        }, child: Text(AppLocalizations.of(context)!.title_legal,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700,decoration: TextDecoration.underline)
          )
        ),
        const SizedBox(height: 24),
        SvgPicture.asset(
          Theme.of(context).brightness == Brightness.dark
              ? 'assets/images/logo_mabb_dark.svg'
              : 'assets/images/logo_mabb.svg',
          width: 120,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

}
