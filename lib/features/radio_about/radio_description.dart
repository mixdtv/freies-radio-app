import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class RadioDescription extends StatelessWidget {
  final String text;

  const RadioDescription({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Html(
      data: text,
      onLinkTap: (url, attributes, element) {
        if (url != null) {
          launchUrl(Uri.parse(url));
        }
      },
      style: {
        "body": Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(16),
          fontFamily: "inter",
          fontWeight: FontWeight.w400,
          lineHeight: LineHeight(1.46),
          color: Theme.of(context).textTheme.displayMedium?.color,
        ),
        "h1": Style(
          fontSize: FontSize(17),
          fontWeight: FontWeight.w700,
        ),
        "h2": Style(
          fontSize: FontSize(18),
          fontWeight: FontWeight.w700,
        ),
        "h3": Style(
          fontSize: FontSize(16),
          fontWeight: FontWeight.bold,
        ),
        "a": Style(
          color: Theme.of(context).colorScheme.primary,
        ),
      },
    );
  }
}
