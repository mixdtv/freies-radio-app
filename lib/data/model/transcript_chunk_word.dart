import 'package:radiozeit/data/model/transcript_chunk.dart';

class TranscriptChunkWord {

  List<TranscriptChunk> chunks;
  bool isBrakeLine;
  TranscriptChunkWord({
    required this.chunks,
    required this.isBrakeLine,
  });
}