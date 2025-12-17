import 'package:flutter/material.dart';
import 'package:radiozeit/l10n/app_localizations.dart';

class RadioDescription extends StatefulWidget {
  final String text;

  const RadioDescription({super.key, required this.text});
  @override
  _RadioDescriptionState createState() => _RadioDescriptionState();
}

class _RadioDescriptionState extends State<RadioDescription> {
  bool isLongText = false;
  bool showAll = false;

  @override
  void initState() {
    isLongText = widget.text.length > 357;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String text;
    if(isLongText && !showAll) {
      text = "${widget.text.substring(0,357)}...";
    } else {
      text = widget.text;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(text,style: Theme.of(context).textTheme.displayMedium,)
        ),
        if(isLongText)
          _button()
      ],
    );
  }

  _button() {
    return Container(
      width: 76,
      padding: const EdgeInsets.only(top: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            showAll = !showAll;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10,bottom: 6),
              child: Text(showAll ? AppLocalizations.of(context)!.button_read_less : AppLocalizations.of(context)!.button_read_more,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)
                ,),
            ),
            const Divider(height: 1,thickness: 1,)
          ],
        ),
      ),
    );
  }

}
