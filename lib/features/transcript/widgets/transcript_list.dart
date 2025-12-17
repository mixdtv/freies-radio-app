import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:radiozeit/data/model/transcript_chunk.dart';
import 'package:radiozeit/data/model/transcript_chunk_line.dart';
import 'package:radiozeit/data/model/transcript_chunk_word.dart';
import 'package:radiozeit/features/transcript/bloc/transcript_cubit.dart';
import 'package:radiozeit/features/transcript/widgets/transcript_word.dart';
import 'package:radiozeit/features/transcript/widgets/transcript_word2.dart';

class TranscriptList extends StatefulWidget {
  final List<TranscriptChunkLine> lines;
  final List<TranscriptChunkWord> chunks;
  final double progressMs;
  final bool isDark;
  final TranscriptFontSize fontSize;

  const TranscriptList({super.key,
    required this.lines,
    required this.chunks,
    required this.progressMs,
    required this.isDark,
    required this.fontSize
  });

  @override
  State<TranscriptList> createState() => _TranscriptListState();
}

class _TranscriptListState extends State<TranscriptList> {
  final ScrollController _sc = ScrollController();
  double lastPos = 0;
  double topOffset = 200;
  double oldValue = 0;

  @override
  void initState() {
    super.initState();
  }

  // @override
  // void didUpdateWidget(covariant TranscriptList oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   if(widget.chunks.length != oldWidget.chunks.length) {
  //     print("SIZE CHNAGE !!!!");
  //     WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
  //       print("SIZE CHNAGE !!!! UPDATE SCROLL ");
  //       print("_updateScroll $oldValue $topOffset ${oldValue - topOffset} pixel ${_sc.position.pixels}");
  //       if(oldValue - topOffset > 50) {
  //         _sc.jumpTo(_sc.position.pixels + oldValue - topOffset);
  //       } else if(oldValue < 0) {
  //         _sc.jumpTo(_sc.position.pixels + oldValue - topOffset);
  //       }
  //     });
  //
  //   }
  // }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    topOffset = MediaQuery.of(context).size.height / 2 - 50;
    print("didChangeDependencies");
  }

  _updateScroll(double value) {
    oldValue = value;
   // print("_updateScroll $value $topOffset ${value - topOffset} pixel ${_sc.position.pixels}");
    if(value - topOffset > 50) {
      _sc.animateTo(_sc.position.pixels + value - topOffset, duration: Duration(milliseconds: 400), curve: Curves.linear);
    } else if(value < 0) {
      _sc.animateTo(_sc.position.pixels + value - topOffset, duration: Duration(milliseconds: 400), curve: Curves.linear);
    }


  }

  @override
  Widget build(BuildContext context) {




    //print("last chunk ${chunks.last.to} ${chunks.last.to - widget.progressMs}");

    return SingleChildScrollView(
      controller: _sc,
      padding: EdgeInsets.symmetric(horizontal: 8),
      physics: const ClampingScrollPhysics(),
      child: Wrap(
        children: widget.chunks.map((e) {
          if(e.isBrakeLine) {
            return Container(
           // color: Colors.red,
            height: 18,
            width: MediaQuery.of(context).size.width,);
          }
          return TranscriptWordNew(
            progress: widget.progressMs,
            chunks: e.chunks,
            fontSize:widget.fontSize,
            updateScroll: _updateScroll,
          );
        }).toList(),

      ),
    );
  }
}
