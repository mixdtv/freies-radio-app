import 'package:flutter/material.dart';
import 'package:radiozeit/data/model/transcript_chunk.dart';
import 'package:radiozeit/features/transcript/bloc/transcript_cubit.dart';

class TranscriptWordNew extends StatefulWidget {

  final double progress;
  final List<TranscriptChunk> chunks;
  final TranscriptFontSize fontSize;
  final Function(double) updateScroll;
  const TranscriptWordNew({super.key,required this.chunks, required this.progress, required this.fontSize, required this.updateScroll});

  @override
  State<TranscriptWordNew> createState() => _TranscriptWordNewState();
}

class _TranscriptWordNewState extends State<TranscriptWordNew> {
  late double end;
  late double start;
  late bool isDark;
  late String word;

  @override
  void initState() {
    var text = "";
    for (var element in widget.chunks) {
      text+=element.content;
    }
    word = text;
    end = widget.chunks.last.to;
    start = widget.chunks.first.start;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    isDark = Theme.of(context).brightness == Brightness.dark;
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant TranscriptWordNew oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool isOldWidgetWasActive = oldWidget.progress > oldWidget.chunks.first.start && oldWidget.progress > oldWidget.chunks.last.to;
    bool isNewWidgetActive = widget.progress > widget.chunks.first.start && widget.progress > widget.chunks.last.to;
    if(!isOldWidgetWasActive && isNewWidgetActive) {
      final renderBox = context.findRenderObject() as RenderBox;
     // print("renderBox ${word} ${renderBox.semanticBounds.top} ${renderBox.paintBounds.top} ${renderBox.localToGlobal(Offset.zero)}");
      widget.updateScroll(renderBox.localToGlobal(Offset.zero).dy);
    }


  }

  @override
  Widget build(BuildContext context) {

    if(widget.progress > end) {
      return Text(word,style: getStyle(isDark: isDark,isOld: true));
    }

    if(widget.progress < start) {
      return Text(word,style: getStyle(isDark: isDark,isOld: false));
    }

    var filtered = widget.chunks.where((e) => widget.progress > e.start).toList();
    var activeText = "";
    for (var element in filtered) {
      activeText+=element.content;
    }
    return Stack(
      children: [
        Text(word,
        softWrap: true,
        style: getStyle(isDark: isDark,isOld: false)),
        Text(activeText,style: getStyle(isDark: isDark,isOld: true))
      ],
    );
  }

  TextStyle getStyle({
    required bool isOld,
    required bool isDark
  }) {
    return TextStyle(
        fontFamily:"inter",
        fontSize: widget.fontSize.size,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color:  isOld
            ? isDark ? Colors.white : const Color(0xff0A0A0A)
            : isDark ? const Color(0xff4C5053) : const Color(0xffB1B8BE)
    );
  }
}
