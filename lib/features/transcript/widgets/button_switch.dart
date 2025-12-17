import 'package:flutter/material.dart';

class AppButtonSwitch extends StatelessWidget {
  final bool isSelect;
  final Function(RenderBox) onSelect;
  final Widget child;
  const AppButtonSwitch({super.key, required this.isSelect, required this.onSelect, required this.child});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
          onTap: () {
            final RenderBox bar = context.findRenderObject() as RenderBox;
            onSelect(bar);
          },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.primary,
            border: Border.all(
                color: isSelect ? Theme.of(context).colorScheme.onBackground : Colors.transparent)
          ),
          child: child,
        ),
      ),
    );
  }
}
