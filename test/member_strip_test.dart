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

    testWidgets('a chip is only as wide as it needs to be', (tester) async {
      // Regression: a chip that fills the width it is offered pushes every
      // other member onto its own line, so the strip becomes a vertical stack.
      await tester.pumpWidget(wrap(MemberStrip(members: [member(name: 'A')])));

      final chip = tester.getSize(
        find.ancestor(of: find.text('A'), matching: find.byType(Container)).first,
      );

      expect(chip.width, lessThan(120));
    });

    testWidgets('several short members share one line', (tester) async {
      await tester.pumpWidget(wrap(MemberStrip(members: [member(name: 'A')])));
      final oneMember = tester.getSize(find.byType(MemberStrip)).height;

      await tester.pumpWidget(wrap(MemberStrip(
        members: [member(name: 'A'), member(name: 'B'), member(name: 'C')],
      )));

      expect(tester.getSize(find.byType(MemberStrip)).height, oneMember);
    });

    testWidgets('wraps rather than overflowing when six members do not fit',
        (tester) async {
      // Six chips exceed the 232 px a list row leaves on a 390 pt phone, so
      // the strip must run onto a second line instead of clipping.
      await tester.pumpWidget(wrap(MemberStrip(members: [member(name: 'A')])));
      final oneLine = tester.getSize(find.byType(MemberStrip)).height;

      await tester.pumpWidget(wrap(MemberStrip(
        members: List.generate(6, (i) => member(name: 'Mitglied $i')),
      )));

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(MemberStrip)).height,
        greaterThan(oneLine),
      );
    });

    testWidgets('one member is no taller than a single logo plus padding',
        (tester) async {
      await tester.pumpWidget(wrap(MemberStrip(members: [member(name: 'A')])));

      expect(
        tester.getSize(find.byType(MemberStrip)).height,
        lessThanOrEqualTo(MemberStrip.logoHeight + 12 + 5),
      );
    });
  });
}
