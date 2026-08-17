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
    final source = JsonMap.toStr(json["sourceStation"]) ?? "";
    // Something has to end up on the line: either a studio name to print, or
    // a source slug that can find a member whose name we print instead. The
    // programme title is not one of them — it is carried but never shown, and
    // accepting an entry on its strength painted a dot with nothing after it.
    if (name.isEmpty && source.isEmpty) return null;

    return NowPlaying(
      sourceStation: source,
      studioName: name,
      title: JsonMap.toStr(json["title"]) ?? "",
      until: DateTime.tryParse(
        JsonMap.toStr(json["epgBroadcastEndTime"]) ?? "",
      ),
    );
  }

  /// The member this belongs to, so its logo and proper name can be shown.
  ///
  /// Matched on the EPG slug, never on the display name: the EPG says "Frrapo"
  /// where the station is called "Freies Radio Potsdam - frrapó".
  ///
  /// The member carries that slug itself, so the match needs nothing else.
  /// [stationsByEpgPrefix] is only the older route, kept for a backend
  /// deployed before members carried `epgPrefix`: it finds the member's own
  /// station in the list to learn the slug, which misses exactly the members
  /// that route cannot reach — one hidden with `showInApp: false` is not in
  /// the list, and a guest has no station at all.
  RadioMember? studioOf(
    AppRadio station,
    Map<String, AppRadio> stationsByEpgPrefix,
  ) {
    if (sourceStation.isEmpty) return null;

    for (final member in station.members) {
      if (member.epgPrefix == sourceStation) return member;
    }

    final owner = stationsByEpgPrefix[sourceStation];
    if (owner == null) return null;

    for (final member in station.members) {
      if (member.prefix == owner.prefix) return member;
    }
    return null;
  }

  /// Read a `/radio/epg/now` response body into a map keyed by EPG slug.
  ///
  /// The entries sit under `msg`, as everywhere else in this API — iterating
  /// the body itself yields `msg` and `success` as slugs and parses nothing.
  /// An entry that makes no sense is skipped rather than failing the rest;
  /// that station keeps its member strip.
  static Map<String, NowPlaying> mapFromResponse(dynamic data) {
    final entries = JsonMap.toMap(JsonMap.toMap(data)["msg"]);
    final out = <String, NowPlaying>{};
    entries.forEach((slug, item) {
      final parsed = fromJson(JsonMap.toMap(item));
      if (parsed != null) out[slug] = parsed;
    });
    return out;
  }

  /// The subset of [onAir] describing stations that are actually in [stations].
  ///
  /// A new station list makes entries for stations it does not contain
  /// meaningless — they describe a list that is no longer on screen. Dropping
  /// only those, rather than clearing the map, keeps the line on the rows that
  /// survive instead of blinking it off on every refresh.
  static Map<String, NowPlaying> keepListed(
    Map<String, NowPlaying> onAir,
    List<AppRadio> stations,
  ) {
    if (onAir.isEmpty) return onAir;

    final kept = <String, NowPlaying>{};
    for (final station in stations) {
      final entry = onAir[station.epgPrefix];
      if (entry != null) kept[station.epgPrefix] = entry;
    }
    return kept;
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
