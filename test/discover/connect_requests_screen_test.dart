import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metafter/core/domain/models.dart';
import 'package:metafter/features/home/presentation/pages/connect_requests_screen.dart';

import 'discover_fakes.dart';

void main() {
  ConnectionRequest incoming(String id, String name) => ConnectionRequest(
        id: id,
        direction: RequestDirection.incoming,
        peerSub: 'peer-$id',
        card: ProfileCard(
          sub: 'peer-$id',
          name: name,
          designation: 'CTO',
          company: 'TechCorp',
        ),
        createdAt: DateTime.now(),
      );

  testWidgets('accepting a request removes its row', (tester) async {
    final fakes = installFakeServices();
    final request = incoming('r1', 'Liam Smith');
    fakes.requests.rows[request.id] = request;

    await tester.pumpWidget(
      const MaterialApp(home: ConnectRequestsScreen()),
    );
    await tester.pump(); // watchIncomingPending emits its first value

    expect(find.text('Liam Smith'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    // ConnectionService.accept was called and the row disappeared.
    expect(fakes.connection.accepted.single.id, 'r1');
    expect(find.text('Liam Smith'), findsNothing);
    expect(find.text('No new friend request'), findsOneWidget);

    // Let the "connected" SnackBar timer expire.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('declining a request removes its row silently',
      (tester) async {
    final fakes = installFakeServices();
    final request = incoming('r2', 'Olivia Rhye');
    fakes.requests.rows[request.id] = request;

    await tester.pumpWidget(
      const MaterialApp(home: ConnectRequestsScreen()),
    );
    await tester.pump();

    expect(find.text('Olivia Rhye'), findsOneWidget);
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();

    expect(fakes.connection.declined.single.id, 'r2');
    expect(find.text('Olivia Rhye'), findsNothing);
    expect(find.text('No new friend request'), findsOneWidget);
  });
}
