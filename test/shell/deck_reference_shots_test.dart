@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metafter/core/domain/models.dart';
import 'package:metafter/core/services/app_services.dart';
import 'package:metafter/features/home/presentation/pages/home_shell.dart';

import '../services/fakes.dart';
import 'shell_fakes.dart';

/// Renders the Home-shell card deck at the settled and mid-drag positions
/// that correspond to the reference frames extracted from MetAfterDemo.mov
/// (demo-frames/README.md maps positions → frame ranges).
///
/// Run with real typography for visual comparison against the demo:
///
///   DECK_FONT_DIR=`<dir with InstrumentSans-{400,500,600,700}.ttf>` \
///     flutter test --tags golden --update-goldens test/shell/deck_reference_shots_test.dart
///
/// Without DECK_FONT_DIR the goldens render in the test-default block font —
/// still valid for layout regressions, useless for typography comparison.

const double _logicalW = 393;
const double _logicalH = 852;

class _SeededEncounterRepository extends FakeEncounterRepository {
  _SeededEncounterRepository(this.encounters);

  final List<Encounter> encounters;

  @override
  Stream<List<Encounter>> watchDay(DateTime day) => Stream.value(encounters);

  @override
  Future<List<DateTime>> daysWithEncounters() async =>
      [DateTime.now()];
}

Encounter _encounter(String id, String name, String designation,
    String company, DateTime seenAt) {
  return Encounter(
    id: id,
    peerEid: 'eid-$id',
    card: ProfileCard(
      sub: 'sub-$id',
      name: name,
      designation: designation,
      company: company,
    ),
    firstSeen: seenAt,
    lastSeen: seenAt,
    meters: 2,
  );
}

void _seedThread(FakeMessageRepository repo, String sub, String name,
    String body, Duration ago, {required bool fromMe}) {
  final at = DateTime.now().subtract(ago);
  repo.rows.add(ChatMessage(
    id: 'msg-$sub',
    peerSub: sub,
    fromMe: fromMe,
    body: body,
    sentAt: at,
    status: MessageStatus.delivered,
  ));
  repo.threadCards[sub] = ProfileCard(sub: sub, name: name);
}

Future<void> _loadFonts() async {
  final dir = Platform.environment['DECK_FONT_DIR'];
  if (dir == null || dir.isEmpty) return;
  // The app styles resolve to the 'InstrumentSans' family (google_fonts);
  // register the same bytes under the test-default family too so raw
  // TextStyles without an explicit family also render with real glyphs.
  for (final family in ['InstrumentSans', 'Roboto']) {
    final loader = FontLoader(family);
    for (final weight in [400, 500, 600, 700]) {
      final file = File('$dir/InstrumentSans-$weight.ttf');
      if (!file.existsSync()) continue;
      final bytes = await file.readAsBytes();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }
  // Material icon glyphs don't ship with the flutter_tester font set — copy
  // MaterialIcons-Regular.otf from the Flutter SDK cache into DECK_FONT_DIR.
  final icons = File('$dir/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons');
    final bytes = await icons.readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadFonts);

  testWidgets('deck reference shots', (tester) async {
    tester.view.physicalSize =
        const Size(_logicalW * 3, _logicalH * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final today = DateTime.now();
    DateTime at(int hour, int minute) =>
        DateTime(today.year, today.month, today.day, hour, minute);

    final encounters = _SeededEncounterRepository([
      _encounter('e1', 'Koby Stone', 'SVP Engineering', 'InnoVision',
          at(16, 28)),
      _encounter('e2', 'Luna Ray', 'Head of Marketing', 'MarketVerse',
          at(16, 24)),
      _encounter('e3', 'Owen Hill', 'VP, Sales', 'SaleSail', at(16, 22)),
      _encounter('e4', 'Koby Stone', 'SVP Engineering', 'InnoVision',
          at(16, 18)),
      _encounter('e5', 'Luna Ray', 'Head of Marketing', 'MarketVerse',
          at(16, 12)),
      _encounter('e6', 'Owen Hill', 'VP, Sales', 'SaleSail', at(16, 10)),
    ]);

    final messages = FakeMessageRepository();
    _seedThread(messages, 'p1', 'Candice Wue', "Okay, Let's Go.",
        const Duration(hours: 3), fromMe: true);
    _seedThread(messages, 'p2', 'Zahir Mays', 'Whats the plan',
        const Duration(hours: 6), fromMe: true);
    _seedThread(messages, 'p3', 'Rane Wells', 'Meet you there at 7?',
        const Duration(hours: 12), fromMe: false);
    _seedThread(messages, 'p4', 'Sophia Ramirez', "Don't forget the keys",
        const Duration(hours: 18), fromMe: false);
    _seedThread(messages, 'p5', 'Jasmine', 'How are you?',
        const Duration(hours: 22), fromMe: false);
    _seedThread(messages, 'p6', 'Candice Wue', "Okay, Let's Go.",
        const Duration(hours: 3), fromMe: true);
    _seedThread(messages, 'p7', 'Zahir Mays', 'Whats the plan',
        const Duration(hours: 6), fromMe: true);
    _seedThread(messages, 'p8', 'Rane Wells', 'Meet you there at 7?',
        const Duration(hours: 12), fromMe: false);

    AppServices.install(AppServices(
      profile: FakeProfileRepository(),
      encounters: encounters,
      requests: FakeRequestRepository(),
      connections: FakeConnectionRepository(),
      messages: messages,
      settings: FakeSettingsRepository(),
      engine: FakeProximityEngine(),
      transport: FakeTransportClient(),
      session: FakeSessionService(),
      connection: FakeConnectionService(),
      messaging: FakeMessageService(),
    ));

    // Plain ThemeData (not AppTheme.lightTheme): the shell screens style
    // themselves with raw TextStyles, and going through google_fonts here
    // would throw on the test HTTP client. The FontLoader in _loadFonts
    // registered 'InstrumentSans' directly.
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'InstrumentSans'),
      home: const HomeShell(),
    ));
    // Asset images decode on a real event loop — precache the header wordmark
    // so the shots show it instead of a first-frame placeholder.
    await tester.runAsync(() async {
      final context = tester.element(find.byType(HomeShell));
      await precacheImage(
          const AssetImage('assets/logos/wordmark_red.png'), context);
    });
    await tester.pump(const Duration(milliseconds: 400));

    Future<void> shot(String name) => expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/$name.png'),
        );

    // Deck axis: p = startPos - dx/width (drag right → toward Discover).
    Future<void> dragHold(TestGesture gesture, double dxLogical) async {
      await gesture.moveBy(Offset(dxLogical, 0));
      await tester.pump();
    }

    // ── Rest: Home (demo f0001) ──
    await shot('p2.0-home');

    // ── Home → Discover (demo f0002–f0023) ──
    var gesture = await tester.startGesture(const Offset(196, 500));
    await dragHold(gesture, 24); // consume touch slop
    await dragHold(gesture, _logicalW * 0.5);
    await shot('p1.5-mid-home-discover'); // demo f0012
    await dragHold(gesture, _logicalW * 0.5);
    await gesture.up();
    await tester.pumpAndSettle();
    await shot('p1.0-discover-parked'); // demo f0023 / resting Discover

    // Tap the parked Home peek to return home.
    await tester.tapAt(const Offset(_logicalW * 0.92, 500));
    await tester.pumpAndSettle();

    // ── Home → Messages, phase 1: drag to parked (demo f0048–f0070) ──
    gesture = await tester.startGesture(const Offset(196, 500));
    await dragHold(gesture, -24);
    await dragHold(gesture, -_logicalW * 0.5);
    await shot('p2.5-mid-home-messages'); // demo f0058
    await dragHold(gesture, -_logicalW * 0.5);
    await gesture.up();
    await tester.pumpAndSettle();
    await shot('p3.0-messages-parked'); // demo hold state f0070–f0096

    // ── Messages, phase 2: expand to full screen (demo f0071–f0097) ──
    gesture = await tester.startGesture(const Offset(196, 500));
    await dragHold(gesture, -24);
    await dragHold(gesture, -_logicalW * 0.5);
    await shot('p3.5-mid-messages-expand'); // demo f0083
    await dragHold(gesture, -_logicalW * 0.5);
    await gesture.up();
    await tester.pumpAndSettle();
    await shot('p4.0-messages-full'); // demo f0097

    // ── Back home, then Discover expanded to full (design's full Discover:
    // compact `‹ Discover` header with view toggle + calendar + pills) ──
    await tester.tapAt(const Offset(28, 24)); // back chevron
    await tester.pumpAndSettle();
    gesture = await tester.startGesture(const Offset(196, 500));
    await dragHold(gesture, 24);
    await dragHold(gesture, _logicalW);
    await gesture.up();
    await tester.pumpAndSettle(); // parked Discover
    gesture = await tester.startGesture(const Offset(150, 500));
    await dragHold(gesture, 24);
    await dragHold(gesture, _logicalW);
    await gesture.up();
    await tester.pumpAndSettle();
    await shot('p0.0-discover-full');
  });
}
