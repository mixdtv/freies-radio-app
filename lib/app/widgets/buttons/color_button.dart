import 'package:flutter/material.dart';
import 'package:radiozeit/utils/colors.dart';

class ColorButton extends StatelessWidget {
  final String text;
  final Color color;
  final bool isLoading;
  final bool isDisabled;
  final Function() onPressed;

  const ColorButton({super.key, required this.text,required this.color, required this.onPressed
    , this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {

    return Opacity(
      opacity: isLoading || isDisabled ? 0.8 : 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: double.infinity,
        ),
        child: Material(
          color: color,
            borderRadius: BorderRadius.circular(8),

          child: InkWell(
            onTap: isLoading || isDisabled ? null : onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(text,style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white
                      ),),
                    ),
                  ),
                  if(isLoading) Container(
                      width: 14,
                      height: 14,
                      margin: EdgeInsets.only(left: 8),
                      child: CircularProgressIndicator(color: Colors.white,strokeWidth: 2,))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
