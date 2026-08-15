import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/utils/json_map.dart';

/// Who currently has an aggregated station's stream.
///
/// FRBB Berlin and Radiokombinat broadcast on one line each; their members are
/// not places to tune to but studios that take turns filling it. This is the
/// one that has it at the moment.
class NowPlaying {
  /// EPG slug of the station whose programme this is — `piradio`, `colabo`.
  /// Empty when the entry is the station's own rather than a copy.
  final String sourceStation;

  /// The studio as the EPG names it, e.g. "Pi Radio". A display name, so it
  /// cannot be joined on — see [studioOf].
  final String studioName;

  final String title;
  final DateTime? until;

  const NowPlaying({
    required this.sourceStation,
    required this.studioName,
    required this.title,
    this.until,
  });

  static NowPlaying? fromJson(Map<String, dynamic> json) {
    final name = JsonMap.toStr(json["subheadline"]) ?? "";
    final title = JsonMap.toStr(json["title"]) ?? "";
    if (name.isEmpty && title.isEmpty) return null;

    return NowPlaying(
      sourceStation: JsonMap.toStr(json["sourceStation"]) ?? "",
      studioName: name,
      title: title,
      until: DateTime.tryParse(
        JsonMap.toStr(json["epgBroadcastEndTime"]) ?? "",
      ),
    );
  }

  /// The member this belongs to, so its logo and proper name can be shown.
  ///
  /// Matched on the EPG slug against each station's `epgPrefix`, never on the
  /// display name: the EPG says "Frrapo" where the station is called
  /// "Freies Radio Potsdam - frrapó". The two differ for Colaboradio as well,
  /// whose prefix is `colaboradio` while its epgPrefix is `colabo` — which is
  /// why the lookup goes through [stationsByEpgPrefix] rather than assuming
  /// the slugs are the same.
  RadioMember? studioOf(
    AppRadio station,
    Map<String, AppRadio> stationsByEpgPrefix,
  ) {
    if (sourceStation.isEmpty) return null;

    final owner = stationsByEpgPrefix[sourceStation];
    if (owner == null) return null;

    for (final member in station.members) {
      if (member.prefix == owner.prefix) return member;
    }
    return null;
  }

  /// Index of the station list by EPG slug, for [studioOf].
  static Map<String, AppRadio> byEpgPrefix(List<AppRadio> stations) {
    final map = <String, AppRadio>{};
    for (final station in stations) {
      if (station.epgPrefix.isNotEmpty) map[station.epgPrefix] = station;
    }
    return map;
  }
}
