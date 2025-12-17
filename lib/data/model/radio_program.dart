import 'package:radiozeit/utils/app_logger.dart';
import 'package:radiozeit/utils/extensions.dart';
import 'package:radiozeit/utils/json_map.dart';

final _log = getLogger('RadioEpg');

class RadioEpg {

  String id;
  String title;
  List<String> desc;
  List<String> hosts;

  String url;
  String icon;
  String broadcasterId;
  String subheadline;
  int duration;
  DateTime start;
  DateTime end;

  RadioEpg({

    required this.id,
    required this.title,
    required this.desc,
    required this.url,
    required this.start,
    required this.broadcasterId,
    required this.subheadline,
    required this.icon,
    required this.end,
    required this.duration,
    required this.hosts,
  });

  factory RadioEpg.fromJson(Map<String, dynamic> map) {
    return RadioEpg(
      id: JsonMap.toStr(map['_id']) ?? "",
      desc: JsonMap.toList(map['description']).cast<String>().map((e) => e.stripHtml()).toList(),
      hosts: JsonMap.toList(map['hosts']).cast<String>(),
      title:JsonMap.toStr(map['title']) ?? "",
      url: JsonMap.toStr(map['url']) ?? "",
      icon: JsonMap.toStr(map['image']) ?? "",
      broadcasterId: JsonMap.toStr(map['broadcaster_id']) ?? "",
      subheadline: JsonMap.toStr(map['subheadline']) ?? "",
      duration: JsonMap.toInt(map['duration']) ?? 0,
      start: JsonMap.toDate(map['epgBroadcastStartTime'],"yyyy-MM-dd'T'HH:mm:ss") ?? DateTime.now(),
      end: JsonMap.toDate(map['epgBroadcastEndTime'],"yyyy-MM-dd'T'HH:mm:ss")?? DateTime.now(),
    );
  }

  bool isOnAir(DateTime now) {
    final result = now.isAfter(start) && now.isBefore(end);
    _log.fine('isOnAir "$title": $result (now: $now, start: $start, end: $end)');
    return result;
  }

  int getProgress(DateTime now) {
    int realDuration = end.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
    double progress =  ((now.millisecondsSinceEpoch - start.millisecondsSinceEpoch)) / realDuration;
    if(progress > 1) progress = 1;
    if(progress < 0) progress = 0;
    return (progress * 100).toInt();
  }

  RadioEpg.empty():
        id = "",
        desc = const [],
        hosts = const [],
        title = "",
        url = "",
        icon = "",
        broadcasterId = "",
        subheadline = "",
        duration = 0,
        start = DateTime.now(),
        end = DateTime.now();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RadioEpg && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}