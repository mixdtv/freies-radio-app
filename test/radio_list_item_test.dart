import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radiozeit/data/model/now_playing.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/features/radio_list/radio_list_item.dart';
import 'package:radiozeit/features/radio_list/widget/member_strip.dart';
import 'package:radiozeit/features/radio_list/widget/now_playing_line.dart';
import 'package:radiozeit/l10n/app_localizations.dart';

AppRadio radioWith({List<String> genres = const [], List<Object> members = const []}) {
  return AppRadio.fromJson({
    'prefix': 'frbb-berlin',
    'provider': 'FRBB Berlin',
    'genres': genres,
    'members': members,
    'logoBgColor': '#FFFFFF',
  });
}

NowPlaying onAir() => NowPlaying.fromJson({
      'subheadline': 'Pi Radio',
      'sourceStation': 'piradio',
      'title': 'Taxi Berlin',
      'epgBroadcastEndTime': '2026-08-17T11:15:00',
    })!;

Widget wrap(AppRadio radio, {NowPlaying? onAir, Locale locale = const Locale('de')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
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
              nowPlaying: onAir,
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

    testWidgets('what is on air sits directly under the name when genres are empty',
        (tester) async {
      await tester.pumpWidget(wrap(radioWith(), onAir: onAir()));

      final name = tester.getRect(find.text('FRBB Berlin'));
      final line = tester.getRect(find.byType(NowPlayingLine));
      // Only the line's own top padding separates them.
      expect(line.top - name.bottom, lessThan(10));
    });
  });

  group('what is on air', () {
    testWidgets('is shown once the EPG has answered', (tester) async {
      await tester.pumpWidget(wrap(radioWith(), onAir: onAir()));

      expect(find.byType(NowPlayingLine), findsOneWidget);
      expect(find.textContaining('Pi Radio'), findsOneWidget);
    });

    // The member strip used to stand in until the EPG answered. It no longer
    // does: a row that swaps logos for text mid-load reads as a glitch.
    testWidgets('a station with members shows nothing until then',
        (tester) async {
      await tester.pumpWidget(wrap(radioWith(members: [
        {'prefix': 'frrapo', 'name': 'frrapó', 'imgUrl': 'https://x.test/f.png'},
        {'prefix': 'piradio', 'name': 'Pi Radio', 'imgUrl': 'https://x.test/p.png'},
      ])));

      expect(find.byType(MemberStrip), findsNothing);
      expect(find.text('frrapó'), findsNothing);
    });

    // "Radio Ginseng" arrived as "Radio Gins…" on a 360dp phone, cut short so
    // that "bis 16:56" could say when a programme it had not finished naming
    // would end. The name gets the room instead.
    testWidgets('the studio name is not cut short for an end time',
        (tester) async {
      await tester.pumpWidget(wrap(radioWith(), onAir: NowPlaying.fromJson({
        'subheadline': 'Radio Ginseng',
        'sourceStation': 'ginseng',
        'title': 'Bluestime',
        'epgBroadcastEndTime': '2026-08-17T16:56:00',
      })!));

      expect(find.textContaining('bis'), findsNothing);
      // Nothing sits between the name and the end of the line, so all the
      // spare width is the name's. (Not didExceedMaxLines: the test font is
      // Ahem, under which every string of this length overflows anyway.)
      final labels = find.descendant(
        of: find.byType(NowPlayingLine),
        matching: find.byType(Text),
      );
      expect(tester.widgetList<Text>(labels).map((t) => t.data),
          ['JETZT', 'Radio Ginseng']);
      expect(tester.getRect(find.text('Radio Ginseng')).right,
          tester.getRect(find.byType(NowPlayingLine)).right);
    });

    testWidgets('the label is translated', (tester) async {
      await tester.pumpWidget(wrap(radioWith(), onAir: onAir()));
      expect(find.text('JETZT'), findsOneWidget);

      await tester.pumpWidget(
          wrap(radioWith(), onAir: onAir(), locale: const Locale('en')));
      expect(find.text('NOW'), findsOneWidget);
      expect(find.text('JETZT'), findsNothing);
    });

    // An entry can name a source station that matches no member, leaving
    // nothing to print next to the dot.
    testWidgets('nothing is drawn when there is no name to show', (tester) async {
      final unnamed = NowPlaying.fromJson({'sourceStation': 'unknown-studio'})!;

      await tester.pumpWidget(wrap(radioWith(), onAir: unnamed));

      expect(find.text('JETZT'), findsNothing);
      expect(tester.getSize(find.byType(NowPlayingLine)), Size.zero);
    });

    testWidgets('members claim no height of their own', (tester) async {
      final bare = await rowHeight(tester, radioWith());
      final withMembers = await rowHeight(tester, radioWith(members: [
        {'prefix': 'frrapo', 'name': 'frrapó'},
      ]));

      expect(withMembers, bare);
    });
  });
}
