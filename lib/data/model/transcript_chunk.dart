import 'package:radiozeit/utils/json_map.dart';

class TranscriptChunk {
  double start;
  double to;
  String content;
  bool isBrakeLine;

  TranscriptChunk({
      required this.start,
      required this.to,
      required this.content,
      this.isBrakeLine = false
  });

  TranscriptChunk.breakLine() : start = 0,
        to = 0,
        content = "",
        isBrakeLine = true;

  factory TranscriptChunk.fromJson(dynamic json) {
    return TranscriptChunk(
        start: JsonMap.toDouble(json['start']) ?? 0,
        to:JsonMap.toDouble(json['to']) ?? 0,
        content:JsonMap.toStr(json['content']) ?? "",
    );
  }

}