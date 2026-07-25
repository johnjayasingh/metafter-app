import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metafter/core/domain/models.dart';
import 'package:metafter/features/home/presentation/pages/all_messages_screen.dart';

import '../services/fakes.dart' show card;
import 'messaging_fakes.dart';

void main() {
  late MessagingHarness harness;

  ProfileCard seedTwoThreads() {
    final candice = card('peer-candice', name: 'Candice Wue');
    final zahir = card('peer-zahir', name: 'Zahir Mays');
    harness.messages.seedThread(candice, messages: [
      msg('c1', 'peer-candice', "Okay, Let's Go.",
          fromMe: true,
          sentAt: DateTime.now().subtract(const Duration(hours: 3))),
    ]);
    harness.messages.seedThread(zahir, messages: [
      msg('z1', 'peer-zahir', 'Whats the plan',
          fromMe: false,
          status: MessageStatus.delivered,
          sentAt: DateTime.now().subtract(const Duration(hours: 6))),
    ]);
    return candice;
  }

  setUp(() {
    harness = MessagingHarness.install();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: AllMessagesScreen()));
    await tester.pump(); // flush the initial stream emission
  }

  testWidgets('renders live threads with preview, age and unread dot',
      (tester) async {
    seedTwoThreads();
    await pumpScreen(tester);

    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Candice Wue'), findsOneWidget);
    expect(find.text("You: Okay, Let's Go."), findsOneWidget);
    expect(find.textContaining('3h'), findsOneWidget);
    // Zahir has an undelivered-read inbound → unread row, no "You:" prefix.
    expect(find.text('Zahir Mays'), findsOneWidget);
    expect(find.text('Whats the plan'), findsOneWidget);
    // No archived section when nothing is archived.
    expect(find.textContaining('Archived'), findsNothing);
  });

  testWidgets('swipe-left archives a row and moves it to Archived',
      (tester) async {
    seedTwoThreads();
    await pumpScreen(tester);

    await tester.drag(find.text('Candice Wue'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    // Archived via the repository — not via the dismissal itself.
    expect(harness.messages.threads['peer-candice']!.archived, isTrue);
    expect(find.text('Candice Wue'), findsNothing);
    expect(find.text('Archived (1)'), findsOneWidget);
    // The other chat stays put.
    expect(find.text('Zahir Mays'), findsOneWidget);
  });

  testWidgets('expanding Archived shows the row; swipe unarchives it',
      (tester) async {
    final candice = card('peer-candice', name: 'Candice Wue');
    harness.messages.seedThread(candice, archived: true, messages: [
      msg('c1', 'peer-candice', 'See you!', fromMe: true),
    ]);
    await pumpScreen(tester);

    expect(find.text('Candice Wue'), findsNothing);
    await tester.tap(find.text('Archived (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Candice Wue'), findsOneWidget);

    await tester.drag(find.text('Candice Wue'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(harness.messages.threads['peer-candice']!.archived, isFalse);
    expect(find.text('Archived (1)'), findsNothing);
    expect(find.text('Candice Wue'), findsOneWidget);
  });

  testWidgets('search filters by name and last message', (tester) async {
    seedTwoThreads();
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'zah');
    await tester.pump();
    expect(find.text('Zahir Mays'), findsOneWidget);
    expect(find.text('Candice Wue'), findsNothing);

    await tester.enterText(find.byType(TextField), "let's go");
    await tester.pump();
    expect(find.text('Candice Wue'), findsOneWidget);
    expect(find.text('Zahir Mays'), findsNothing);

    await tester.enterText(find.byType(TextField), 'nobody');
    await tester.pump();
    expect(find.text('No results for "nobody"'), findsOneWidget);
  });
}
