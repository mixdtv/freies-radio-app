import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppInputRadio extends StatelessWidget {
  final String value;
  final String groupValue;
  const AppInputRadio({super.key, required this.value, required this.groupValue});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: value == groupValue
        ? SvgPicture.asset("assets/icons/ic_radio_active.svg")
        : SvgPicture.asset("assets/icons/ic_radio.svg",color: Theme.of(context).colorScheme.onBackground,)
    );
  }
}
