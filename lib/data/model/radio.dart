import 'dart:convert';

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
  bool archiveDisabled;
  /// Stations sharing this station's programme, empty for a station that
  /// broadcasts on its own. Resolved server-side, so a member always arrives
  /// with a name and, where one exists, a logo.
  List<RadioMember> members;

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
    this.archiveDisabled = false,
    this.members = const [],
  });

  /// Parse a whole station list from the JSON held in the on-device cache.
  ///
  /// Anything unusable yields an empty list — a payload written by an older
  /// build, or a half-written string — because a broken cache has to degrade
  /// to "no cache" rather than take the app down on launch.
  static List<AppRadio> listFromJsonString(String? cached) {
    if (cached == null || cached.isEmpty) return const [];
    try {
      final decoded = jsonDecode(cached);
      if (decoded is! List) return const [];
      return decoded
          .map((e) => AppRadio.fromJson(JsonMap.toMap(e)))
          .where((r) => r.prefix.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

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
        podcasts: podcasts,
        archiveDisabled: json["archiveDisabled"] == true,
        members: JsonMap.toList(json["members"])
            .map((e) => RadioMember.fromJson(JsonMap.toMap(e)))
            .where((m) => m.name.isNotEmpty)
            .toList(),
    );
  }
}

/// One station in an aggregated station's member list.
///
/// [prefix] is empty for a guest that has no station of its own, and [logo] is
/// empty for a member with no logo — the strip falls back to the name in both
/// cases, so neither is a reason to drop the member.
class RadioMember {
  final String prefix;
  final String name;
  final String logo;
  final String logoBgColor;

  /// The slug the EPG names this member by, resolved server-side from the
  /// member's own station. Empty for a member with no EPG of its own, and for
  /// a backend deployed before this field existed.
  final String epgPrefix;

  const RadioMember({
    required this.prefix,
    required this.name,
    required this.logo,
    required this.logoBgColor,
    this.epgPrefix = "",
  });

  factory RadioMember.fromJson(Map<String, dynamic> json) {
    return RadioMember(
      prefix: JsonMap.toStr(json["prefix"]) ?? "",
      name: JsonMap.toStr(json["name"]) ?? "",
      logo: JsonMap.toStr(json["imgUrl"]) ?? "",
      logoBgColor: JsonMap.toStr(json["logoBgColor"]) ?? "",
      epgPrefix: JsonMap.toStr(json["epgPrefix"]) ?? "",
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

  String getPlatformStream({String? stationPrefix}) {
    if (stationPrefix != null && AppConfig.forceHlsStations.contains(stationPrefix)) {
      return hls;
    }
    if (AppConfig.useSourceStream && source.isNotEmpty) {
      return source;
    }
    return hls;
  }
}