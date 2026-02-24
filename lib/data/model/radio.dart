import 'package:radiozeit/config/app_config.dart';
import 'package:radiozeit/data/model/song_info.dart';
import 'package:radiozeit/utils/json_map.dart';

class AppRadio {


  String id;
  RadioStream stream;
  String lang;
  String icon;
  String iconColor;
  String thumbnail;
  String name;
  String desc;
  String epgKey;
  String epgUrl;
  String epgPrefix;
  String prefix;
  List<String> tags;
  List<SongInfo> topSongs;
  List<String>? podcasts;

  AppRadio({
    required this.id,
    required this.stream,
    required this.lang,
    required this.icon,
    required this.thumbnail,
    required this.name,
    required this.desc,
    required this.epgKey,
    required this.epgUrl,
    required this.epgPrefix,
    required this.prefix,
    required this.tags,
    required this.topSongs,
    required this.iconColor,
    this.podcasts,
  });

  factory AppRadio.fromJson(Map<String,dynamic> json) {
    List<String>? podcasts;
    if (json["podcasts"] != null) {
      podcasts = JsonMap.toList(json["podcasts"]).map((e) => e.toString()).toList();
    }

    return AppRadio(
        id: JsonMap.toStr(json["id"]) ?? "",
        stream: RadioStream.fromJson(JsonMap.toMap(json["streamUrl"])) ,
        lang: JsonMap.toStr(json["language"]) ?? "",
        icon: JsonMap.toStr(json["imgUrl"]) ?? "",
        thumbnail: JsonMap.toStr(json["thumbnailUrl"]) ?? "",
        name: JsonMap.toStr(json["provider"]) ?? "",
        desc: JsonMap.toStr(json["description"]) ?? "",
        epgKey: JsonMap.toStr(json["epgApiKey"]) ?? "",
        epgUrl: JsonMap.toStr(json["epgEndpoint"]) ?? "",
        epgPrefix: JsonMap.toStr(json["epgPrefix"]) ?? "",
        prefix: JsonMap.toStr(json["prefix"]) ?? "",
        iconColor: JsonMap.toStr(json["logoBgColor"]) ?? "",
        tags: JsonMap.toList(json["genres"]).map((e) => e.toString()).toList(),
        topSongs: const [],
        podcasts: podcasts
    );
  }
}

class RadioStream {
  String dash;
  String hls;
  String source;

  RadioStream({
    required this.dash,
    required this.hls,
    required this.source,
  });

  factory RadioStream.fromJson(Map<String,dynamic> json) {
    return RadioStream(
      dash: json["dash"] ?? "",
      hls: json["hls"] ?? "",
      source: json["source"] ?? "",
    );
  }

  String getPlatformStream() {
    if (AppConfig.useSourceStream && source.isNotEmpty) {
      return source;
    }
    return hls;
    // if(Platform.isIOS) return hls;
    // return dash;
  }
}