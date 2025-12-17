import 'package:radiozeit/data/model/transcript_chunk.dart';

class TranscriptChunkLine {
  double start;
  double end;
  String content;
  List<TranscriptChunk> words;

  TranscriptChunkLine({
    required this.content,
    required this.start,
    required this.end,
    required this.words,
  });
}