import 'dart:math';

class VisualChunk {
  List<double> bands;
  int id;
  double endTime;
  double startTime;

  VisualChunk({
    required this.id,
    required this.bands,
    required this.endTime,
    required this.startTime,
  });



  factory VisualChunk.fromJson(Map<String, dynamic> json) {
    return VisualChunk(
        id : 0,
      bands: json['bands'].cast<double>(),
      endTime: json['end_time'] ,
      startTime: json['start_time'],
    );
  }

  bool isCurrent(double duration) {
    return duration >= startTime && duration < endTime ;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisualChunk &&
          runtimeType == other.runtimeType &&
          endTime == other.endTime &&
          startTime == other.startTime;

  @override
  int get hashCode => endTime.hashCode ^ startTime.hashCode;
}