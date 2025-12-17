
class TranscriptHelper {
  static const int ADDED_DELAY = 20 ;  // sec
  static const int CHUNK_DURATION = 30; // sec

  static int getChunkId(double progress) {
    return ((progress-TranscriptHelper.ADDED_DELAY) / CHUNK_DURATION).floor();
   // return (progress / CHUNK_DURATION).floor() - ((ADDED_DELAY / CHUNK_DURATION).round());
  }

  static int getNextChunkId(double progress) {
    return ((progress + CHUNK_DURATION*0.3 - ADDED_DELAY) / CHUNK_DURATION).floor();
    return ((progress + CHUNK_DURATION*0.6) / CHUNK_DURATION).floor() - ((ADDED_DELAY / CHUNK_DURATION).round());
  }

  static double getTimeById(int chunkId) {
    return chunkId * CHUNK_DURATION.toDouble() + CHUNK_DURATION;
  }

  static double getPlayerProgress(double progress) {
    return progress - ADDED_DELAY;
  }
}