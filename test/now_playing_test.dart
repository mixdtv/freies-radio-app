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

  group('reading a /radio/epg/now response', () {
    // Verbatim from the EPG, envelope included: the entries live under "msg",
    // and reading the body itself finds "msg" and "success" where slugs should
    // be — which is how this shipped to a phone showing nothing on air.
    final body = {
      'msg': {
        'frbb-berlin': {
          'broadcaster_id': 'frbb-berlin',
          'sourceStation': 'piradio',
          'subheadline': 'Pi Radio',
          'title': 'Taxi Berlin - Hier spricht Tiffany Taxi',
          'epgBroadcastEndTime': '2026-08-17T11:15:16',
        },
        'rkb': {
          'broadcaster_id': 'rkb',
          'sourceStation': 'ginseng',
          'subheadline': 'Radio Ginseng',
          'title': 'Bluestime',
          'epgBroadcastEndTime': '2026-08-17T11:15:16',
        },
      },
      'success': true,
    };

    test('keys every station by its EPG slug', () {
      final onAir = NowPlaying.mapFromResponse(body);

      expect(onAir.keys, unorderedEquals(['frbb-berlin', 'rkb']));
      expect(onAir['frbb-berlin']!.studioName, 'Pi Radio');
      expect(onAir['frbb-berlin']!.sourceStation, 'piradio');
      expect(onAir['rkb']!.title, 'Bluestime');
    });

    test('a station with nothing on air is left out', () {
      final onAir = NowPlaying.mapFromResponse({
        'msg': {'frbb-berlin': {}},
        'success': true,
      });

      expect(onAir, isEmpty);
    });

    test('an EPG too old to know the endpoint yields nothing on air', () {
      expect(NowPlaying.mapFromResponse({'msg': [], 'success': true}), isEmpty);
      expect(NowPlaying.mapFromResponse(null), isEmpty);
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

  group("matching on the member's own EPG slug", () {
    // What the API sends once resolve_members fills epgPrefix in: no station
    // list is needed to read this, which is the point of the field.
    AppRadio resolved() => AppRadio.fromJson({
          'prefix': 'frbb-berlin',
          'epgPrefix': 'frbb-berlin',
          'provider': 'FRBB Berlin',
          'members': [
            {
              'prefix': 'colaboradio',
              'epgPrefix': 'colabo',
              'name': 'Colaboradio',
              'imgUrl': 'https://x.test/c.png',
            },
            {
              'prefix': 'piradio',
              'epgPrefix': 'piradio',
              'name': 'Pi Radio',
              'imgUrl': 'https://x.test/p.png',
            },
            {'name': 'Radio Connection', 'epgPrefix': 'radio-connection'},
          ],
        });

    test('matches with no station list at all', () {
      final now = parse({'subheadline': 'CoLaboRadio', 'sourceStation': 'colabo'})!;

      final studio = now.studioOf(resolved(), const {});

      expect(studio!.name, 'Colaboradio');
      expect(studio.logo, 'https://x.test/c.png');
    });

    // showInApp: false keeps a station out of the broadcaster list, so the
    // older route — find its station, read its slug — had nothing to find.
    test('a member hidden from the station list keeps its logo', () {
      final visibleOnly = NowPlaying.byEpgPrefix([colaboradio()]);
      final now = parse({'subheadline': 'Pi Radio', 'sourceStation': 'piradio'})!;

      final studio = now.studioOf(resolved(), visibleOnly);

      expect(studio!.name, 'Pi Radio');
      expect(studio.logo, 'https://x.test/p.png');
    });

    test('a guest with no station of its own can be matched', () {
      final now = parse({
        'subheadline': 'Radio Connection',
        'sourceStation': 'radio-connection',
      })!;

      expect(now.studioOf(resolved(), const {})!.name, 'Radio Connection');
    });

    test('a member carrying no slug is not matched by an empty source', () {
      // sourceStation is never empty here — a station's own programme returns
      // earlier — but a member without a slug must not swallow anything else.
      final now = parse({'subheadline': 'Weg', 'sourceStation': 'entfernt'})!;

      expect(now.studioOf(frbbBerlin(), const {}), isNull);
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
