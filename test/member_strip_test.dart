import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/features/radio_list/widget/member_strip.dart';

RadioMember member({String prefix = '', String name = 'X', String logo = ''}) {
  return RadioMember(
    prefix: prefix,
    name: name,
    logo: logo,
    logoBgColor: '#FFFFFF',
  );
}

Widget wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: 248, child: child),
    ),
  );
}

void main() {
  group('RadioMember parsing', () {
    test('reads a station member resolved by the API', () {
      final parsed = RadioMember.fromJson({
        'prefix': 'frrapo',
        'name': 'Freies Radio Potsdam',
        'imgUrl': 'https://x.test/frrapo.png',
        'logoBgColor': '#e8e8e8',
      });

      expect(parsed.prefix, 'frrapo');
      expect(parsed.name, 'Freies Radio Potsdam');
      expect(parsed.logo, 'https://x.test/frrapo.png');
      expect(parsed.logoBgColor, '#e8e8e8');
    });

    test('a guest arrives without a prefix and may have no logo', () {
      final parsed = RadioMember.fromJson({'name': 'Sender Freies Ruppin'});

      expect(parsed.prefix, '');
      expect(parsed.logo, '');
      expect(parsed.name, 'Sender Freies Ruppin');
    });
  });

  group('AppRadio.members', () {
    test('is empty for a station that broadcasts on its own', () {
      final radio = AppRadio.fromJson({'prefix': 'cashmere'});

      expect(radio.members, isEmpty);
    });

    test('keeps API order', () {
      final radio = AppRadio.fromJson({
        'prefix': 'rkb',
        'members': [
          {'prefix': 'frrapo', 'name': 'frrapó'},
          {'prefix': 'ginseng', 'name': 'Radio Ginseng'},
        ],
      });

      expect(radio.members.map((m) => m.prefix), ['frrapo', 'ginseng']);
    });

    test('drops a nameless member rather than rendering a blank chip', () {
      final radio = AppRadio.fromJson({
        'members': [
          {'prefix': 'frrapo', 'name': 'frrapó'},
          {'prefix': 'broken'},
        ],
      });

      expect(radio.members.length, 1);
    });

    test('survives members arriving as something other than a list', () {
      final radio = AppRadio.fromJson({'members': 'nonsense'});

      expect(radio.members, isEmpty);
    });
  });

  group('MemberStrip', () {
    testWidgets('takes no space when there are no members', (tester) async {
      await tester.pumpWidget(wrap(const MemberStrip(members: [])));

      expect(find.byType(Wrap), findsNothing);
      expect(tester.getSize(find.byType(MemberStrip)).height, 0);
    });

    testWidgets('a member without a logo shows its name', (tester) async {
      await tester.pumpWidget(wrap(MemberStrip(
        members: [member(name: 'Radio PAX')],
      )));

      expect(find.text('Radio PAX'), findsOneWidget);
    });

    testWidgets('wraps rather than overflowing when six members do not fit',
        (tester) async {
      // Six chips exceed the ~248 px a list row leaves on a 390 pt phone, so
      // the strip must run onto a second line instead of clipping.
      await tester.pumpWidget(wrap(MemberStrip(
        members: List.generate(6, (i) => member(name: 'Mitglied $i')),
      )));

      expect(tester.takeException(), isNull);
      final strip = tester.getSize(find.byType(MemberStrip));
      expect(strip.height, greaterThan(MemberStrip.logoHeight + 12));
    });

    testWidgets('a single row stays one line tall', (tester) async {
      await tester.pumpWidget(wrap(MemberStrip(members: [member(name: 'A')])));

      expect(
        tester.getSize(find.byType(MemberStrip)).height,
        MemberStrip.logoHeight + 12 + 5,
      );
    });
  });
}
