import 'package:flutter/material.dart';
import 'package:radiozeit/data/model/visual_chunk.dart';
import 'package:radiozeit/features/visual/linear_visual_line.dart';
import 'package:radiozeit/features/visual/visual_helper.dart';

class LinearVisual extends StatefulWidget {
  final VisualChunk? chunk;

  const LinearVisual({super.key, required this.chunk});

  @override
  _LinearVisualState createState() => _LinearVisualState();
}

class _LinearVisualState extends State<LinearVisual> {




  double padding = 4;

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color color = isDark ? Colors.white : Color(0xff0A0A0A);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: (widget.chunk?.bands ?? List.generate(16, (index) => 0)).map((e) {

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: LinearVisualLine(
                  color:color,
                  width: constraints.maxWidth / 16 - padding * 2,
                  top: e/VisualHelper.MAX_LINE_HEIGHT),
            );
          }).toList(),
        );
      },
    );
  }



}



