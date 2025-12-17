import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:radiozeit/data/model/transcript_chunk.dart';
import 'package:radiozeit/features/transcript/bloc/transcript_cubit.dart';

class TranscriptWord extends StatefulWidget {
  final String text;
  final bool isDark;
  final bool isOld;
  final bool isCurrent;
  final Function(double) updateScroll;
  final TranscriptFontSize fontSize;

  const TranscriptWord({super.key, required this.text,   required this.isDark, required this.isOld, required this.updateScroll, required this.isCurrent, required this.fontSize});

  @override
  State<TranscriptWord> createState() => _TranscriptWordState();
}

class _TranscriptWordState extends State<TranscriptWord> {


  @override
  void didUpdateWidget(covariant TranscriptWord oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(!oldWidget.isCurrent && widget.isCurrent) {
      final renderBox = context.findRenderObject() as RenderBox;
      //print("renderBox ${widget.text} ${renderBox.semanticBounds.top} ${renderBox.paintBounds.top} ${renderBox.localToGlobal(Offset.zero)}");
      widget.updateScroll(renderBox.localToGlobal(Offset.zero).dy);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(widget.text,
      style: TextStyle(
          fontFamily:"inter",
          fontSize: widget.fontSize.size,
          fontWeight: FontWeight.w500,
          height: 1.2,
          color:  widget.isOld
                      ? widget.isDark ? Colors.white : const Color(0xff0A0A0A)
                      : widget.isDark ? const Color(0xff4C5053) : const Color(0xffB1B8BE)
      ),
    );
  }

}
