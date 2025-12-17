
class VisualHelper {
  static const int MAX_LINE_HEIGHT = 50;
  static const int ADDED_DELAY = 20 ;  // sec
  static const int VISUAL_CHUNK_DURATION = 5; // sec

  static int getChunkId(double progress) {
    return (progress / VISUAL_CHUNK_DURATION).floor() - ((ADDED_DELAY / VISUAL_CHUNK_DURATION).round()+1);
  }

  static int getNextChunkId(double progress) {
    return ((progress + VISUAL_CHUNK_DURATION/2) / VISUAL_CHUNK_DURATION).floor() - ((ADDED_DELAY / VISUAL_CHUNK_DURATION).round()+1);
  }

  static double getTimeById(int chunkId) {
    return chunkId * VisualHelper.VISUAL_CHUNK_DURATION.toDouble() + VisualHelper.VISUAL_CHUNK_DURATION;
  }

  static double getPlayerProgress(double progress) {
    return progress - VisualHelper.ADDED_DELAY;
  }
}