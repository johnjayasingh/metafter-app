import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metafter/core/domain/models.dart';
import 'package:metafter/features/home/presentation/pages/discover_history_screen.dart';

import 'discover_fakes.dart';

void main() {
  Encounter encounter(DateTime now) => Encounter(
        id: 'e1',
        peerEid: 'eid-1',
        card: const ProfileCard(
          sub: 'sim-koby-stone',
          name: 'Koby Stone',
          designation: 'SVP Engineering',
          company: 'InnoVision',
          intro: 'Engineering leader scaling platform teams.',
          verified: true,
        ),
        firstSeen: now.subtract(const Duration(minutes: 5)),
        lastSeen: now,
        meters: 1.4,
      );

  testWidgets(
      'shows an encounter row and flips to Requested after connecting',
      (tester) async {
    final fakes = installFakeServices();
    fakes.encounters.rows.add(encounter(DateTime.now()));

    await tester.pumpWidget(
      const MaterialApp(home: DiscoverHistoryScreen()),
    );
    await tester.pump(); // watchDay emits its first value

    // The encounter row is rendered from the repository stream.
    expect(find.text('Koby Stone'), findsOneWidget);
    expect(find.text('SVP Engineering'), findsOneWidget);
    expect(find.text('InnoVision'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
    expect(find.text('Requested'), findsNothing);

    // Connect → invite-note dialog → Skip sends without a note.
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    expect(find.text('Add a note to your invitation'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // The request went through the ConnectionService with the ledger link…
    final call = fakes.connection.sendCalls.single;
    expect(call.toCard.sub, 'sim-koby-stone');
    expect(call.note, isNull);
    expect(call.encounterId, 'e1');

    // …and the row now shows the PERSISTED Requested state.
    expect(find.text('Requested'), findsOneWidget);
    expect(find.text('Connect'), findsNothing);

    // Let the "Request sent" SnackBar timer expire.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('shows the empty state when the day has no encounters',
      (tester) async {
    installFakeServices();

    await tester.pumpWidget(
      const MaterialApp(home: DiscoverHistoryScreen()),
    );
    await tester.pump();

    expect(find.text('No crossed paths yet'), findsOneWidget);
  });
}
