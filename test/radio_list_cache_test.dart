import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:radiozeit/data/model/radio.dart';

Map<String, dynamic> station(String prefix, {String name = 'Sender'}) => {
      'prefix': prefix,
      'provider': name,
      'genres': ['Community'],
      'streamUrl': {'source': 'https://example.test/$prefix'},
    };

void main() {
  group('reading the cached station list', () {
    test('parses what the API sent', () {
      final cached = jsonEncode([station('frbb-berlin', name: 'FRBB Berlin')]);

      final radios = AppRadio.listFromJsonString(cached);

      expect(radios.single.prefix, 'frbb-berlin');
      expect(radios.single.name, 'FRBB Berlin');
      expect(radios.single.stream.source, 'https://example.test/frbb-berlin');
    });

    test('keeps the order the API returned', () {
      final cached = jsonEncode([station('a'), station('b'), station('c')]);

      expect(
        AppRadio.listFromJsonString(cached).map((r) => r.prefix),
        ['a', 'b', 'c'],
      );
    });

    test('members survive the round trip', () {
      final cached = jsonEncode([
        {
          ...station('frbb-berlin'),
          'members': [
            {'prefix': 'piradio', 'name': 'Pi Radio', 'imgUrl': 'https://x.test/p.png'},
          ],
        }
      ]);

      final members = AppRadio.listFromJsonString(cached).single.members;

      expect(members.single.prefix, 'piradio');
      expect(members.single.logo, 'https://x.test/p.png');
    });

    test('no cache yet means no stations', () {
      expect(AppRadio.listFromJsonString(null), isEmpty);
      expect(AppRadio.listFromJsonString(''), isEmpty);
    });

    group('a broken cache degrades to no cache', () {
      // Whatever is in there, launching must not throw.
      test('half-written string', () {
        expect(AppRadio.listFromJsonString('[{"prefix":"frbb'), isEmpty);
      });

      test('not JSON at all', () {
        expect(AppRadio.listFromJsonString('nonsense'), isEmpty);
      });

      test('an object where a list was expected', () {
        expect(AppRadio.listFromJsonString('{"prefix":"a"}'), isEmpty);
      });

      test('entries that are not objects', () {
        expect(AppRadio.listFromJsonString('["a", 3, null]'), isEmpty);
      });

      test('a station with no prefix is dropped, the rest survive', () {
        final cached = jsonEncode([{'provider': 'Namenlos'}, station('rkb')]);

        expect(
          AppRadio.listFromJsonString(cached).map((r) => r.prefix),
          ['rkb'],
        );
      });
    });
  });
}
