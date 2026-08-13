import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/features/radio_list/radio_list_item.dart';

AppRadio radioWith({List<String> genres = const [], List<Object> members = const []}) {
  return AppRadio.fromJson({
    'prefix': 'frbb-berlin',
    'provider': 'FRBB Berlin',
    'genres': genres,
    'members': members,
    'logoBgColor': '#FFFFFF',
  });
}

Widget wrap(AppRadio radio) {
  return MaterialApp(
    home: Scaffold(
      // mainAxisSize.min so the row takes its intrinsic height instead of
      // stretching to the viewport, which would hide any height difference.
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 390,
            child: RadioListItem(
              radio: radio,
              isFavorite: false,
              toggleFavorite: () {},
              openRadio: () {},
            ),
          ),
        ],
      ),
    ),
  );
}

Future<double> rowHeight(WidgetTester tester, AppRadio radio) async {
  await tester.pumpWidget(wrap(radio));
  return tester.getSize(find.byType(RadioListItem)).height;
}

void main() {
  group('genre line', () {
    testWidgets('is shown when the station has genres', (tester) async {
      await tester.pumpWidget(wrap(radioWith(genres: ['Community', 'Local'])));

      expect(find.text('Community, Local'), findsOneWidget);
    });

    testWidgets('claims no space when there are no genres', (tester) async {
      final withGenres = await rowHeight(tester, radioWith(genres: ['Community']));
      final without = await rowHeight(tester, radioWith());

      expect(without, lessThan(withGenres));
    });

    testWidgets('blank genres count as none rather than rendering a separator',
        (tester) async {
      await tester.pumpWidget(wrap(radioWith(genres: ['', '  '])));

      expect(find.text(', '), findsNothing);
      expect(find.text(''), findsNothing);
    });

    testWidgets('members sit directly under the name when genres are empty',
        (tester) async {
      final radio = radioWith(members: [
        {'prefix': 'frrapo', 'name': 'frrapó'},
      ]);

      await tester.pumpWidget(wrap(radio));

      final name = tester.getRect(find.text('FRBB Berlin'));
      final strip = tester.getRect(find.byType(Wrap));
      // Only the strip's own 5 px top padding separates them.
      expect(strip.top - name.bottom, lessThan(10));
    });
  });
}
