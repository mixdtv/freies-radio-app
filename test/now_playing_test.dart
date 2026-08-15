import 'package:flutter_test/flutter_test.dart';
import 'package:radiozeit/data/model/now_playing.dart';
import 'package:radiozeit/data/model/radio.dart';

/// Production shapes: Colaboradio's prefix and epgPrefix differ, which is the
/// case a name-based or slug-identity lookup gets wrong.
AppRadio colaboradio() => AppRadio.fromJson({
      'prefix': 'colaboradio',
      'epgPrefix': 'colabo',
      'provider': 'Colaboradio',
    });

AppRadio piradio() => AppRadio.fromJson({
      'prefix': 'piradio',
      'epgPrefix': 'piradio',
      'provider': 'Pi Radio',
    });

AppRadio frbbBerlin() => AppRadio.fromJson({
      'prefix': 'frbb-berlin',
      'epgPrefix': 'frbb-berlin',
      'provider': 'FRBB Berlin',
      'members': [
        {'prefix': 'colaboradio', 'name': 'Colaboradio', 'imgUrl': 'https://x.test/c.png'},
        {'prefix': 'piradio', 'name': 'Pi Radio', 'imgUrl': 'https://x.test/p.png'},
      ],
    });

NowPlaying? parse(Map<String, dynamic> json) => NowPlaying.fromJson(json);

void main() {
  group('parsing what is on air', () {
    test('reads the studio, the title and when it ends', () {
      final now = parse({
        'subheadline': 'Pi Radio',
        'sourceStation': 'piradio',
        'title': 'Taxi Berlin',
        'epgBroadcastEndTime': '2026-08-13T20:00:00',
      })!;

      expect(now.studioName, 'Pi Radio');
      expect(now.sourceStation, 'piradio');
      expect(now.title, 'Taxi Berlin');
      expect(now.until, DateTime(2026, 8, 13, 20));
    });

    test('an entry with neither studio nor title is not on air', () {
      expect(parse({}), isNull);
    });

    test('survives a missing end time', () {
      expect(parse({'subheadline': 'Pi Radio'})!.until, isNull);
    });

    test('survives an unparseable end time', () {
      final now = parse({'subheadline': 'Pi Radio', 'epgBroadcastEndTime': 'soon'});

      expect(now!.until, isNull);
    });
  });

  group('finding the member it belongs to', () {
    final index = NowPlaying.byEpgPrefix([colaboradio(), piradio(), frbbBerlin()]);

    test('matches a member whose prefix equals the EPG slug', () {
      final now = parse({'subheadline': 'Pi Radio', 'sourceStation': 'piradio'})!;

      expect(now.studioOf(frbbBerlin(), index)!.prefix, 'piradio');
    });

    test('matches a member whose prefix differs from the EPG slug', () {
      // The EPG says "colabo"; the member is "colaboradio". Joining on the
      // slug directly would silently find nothing.
      final now = parse({'subheadline': 'CoLaboRadio', 'sourceStation': 'colabo'})!;

      final studio = now.studioOf(frbbBerlin(), index);

      expect(studio, isNotNull);
      expect(studio!.prefix, 'colaboradio');
      expect(studio.logo, 'https://x.test/c.png');
    });

    test('is not fooled by the display name differing from the station name', () {
      // The EPG calls frrapó "Frrapo" while the station is
      // "Freies Radio Potsdam - frrapó" — a name match would fail here, so
      // the lookup must not fall back to one.
      final frrapo = AppRadio.fromJson({
        'prefix': 'frrapo',
        'epgPrefix': 'frrapo',
        'provider': 'Freies Radio Potsdam - frrapó',
      });
      final station = AppRadio.fromJson({
        'prefix': 'frbb-berlin',
        'members': [
          {'prefix': 'frrapo', 'name': 'Freies Radio Potsdam - frrapó'},
        ],
      });
      final now = parse({'subheadline': 'Frrapo', 'sourceStation': 'frrapo'})!;

      final studio = now.studioOf(station, NowPlaying.byEpgPrefix([frrapo]));

      expect(studio!.name, 'Freies Radio Potsdam - frrapó');
    });

    test('a station broadcasting its own programme has no studio', () {
      final now = parse({'subheadline': 'Cashmere Radio', 'sourceStation': ''})!;

      expect(now.studioOf(frbbBerlin(), index), isNull);
    });

    test('a source that is not a member of this station yields nothing', () {
      final now = parse({'subheadline': 'Radio Ginseng', 'sourceStation': 'ginseng'})!;

      expect(now.studioOf(frbbBerlin(), index), isNull);
    });

    test('a source with no station of its own yields nothing', () {
      final now = parse({'subheadline': 'Weg', 'sourceStation': 'entfernt'})!;

      expect(now.studioOf(frbbBerlin(), index), isNull);
    });
  });

  group('indexing the station list', () {
    test('keys stations by their EPG slug', () {
      final index = NowPlaying.byEpgPrefix([colaboradio(), piradio()]);

      expect(index['colabo']!.prefix, 'colaboradio');
      expect(index['piradio']!.prefix, 'piradio');
    });

    test('skips stations without an EPG slug', () {
      final index = NowPlaying.byEpgPrefix([
        AppRadio.fromJson({'prefix': 'x', 'provider': 'X'}),
      ]);

      expect(index, isEmpty);
    });
  });
}
