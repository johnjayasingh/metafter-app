import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metafter/core/domain/models.dart';
import 'package:metafter/features/home/presentation/pages/chat_screen.dart';

import '../services/fakes.dart' show card;
import 'messaging_fakes.dart';

void main() {
  const peerSub = 'peer-luna';
  late MessagingHarness harness;
  late ProfileCard luna;

  setUp(() {
    harness = MessagingHarness.install();
    luna = card(peerSub, name: 'Luna Ray');
    harness.connections.rows[peerSub] = Connection(
      peerSub: peerSub,
      card: luna,
      connectedAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    harness.messages.seedThread(luna, messages: [
      msg('m1', peerSub, 'Hi Asif',
          fromMe: false,
          sentAt: DateTime.now().subtract(const Duration(minutes: 30))),
      msg('m2', peerSub, 'Amazing... How are you?',
          fromMe: false,
          sentAt: DateTime.now().subtract(const Duration(minutes: 29))),
      msg('m3', peerSub, 'Doing great!',
          fromMe: true,
          status: MessageStatus.delivered,
          sentAt: DateTime.now().subtract(const Duration(minutes: 28))),
    ]);
  });

  Future<void> pumpChat(WidgetTester tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: ChatScreen(peerSub: peerSub)));
    await tester.pump(); // initial stream emissions + card resolution
    await tester.pump();
  }

  /// ChatScreen owns a periodic presence timer — unmount it so no timer is
  /// pending when the test ends.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('renders header and bubbles; marks thread read on open',
      (tester) async {
    await pumpChat(tester);

    expect(find.text('Luna Ray'), findsOneWidget);
    expect(find.text('Hi Asif'), findsOneWidget);
    expect(find.text('Amazing... How are you?'), findsOneWidget);
    expect(find.text('Doing great!'), findsOneWidget);
    expect(harness.messaging.readCalls, contains(peerSub));

    await unmount(tester);
  });

  testWidgets('send button appears with text; sending appends a bubble',
      (tester) async {
    await pumpChat(tester);

    // No send button while the field is empty.
    expect(find.byIcon(Icons.send_rounded), findsNothing);

    await tester.enterText(find.byType(TextField), 'See you at the expo');
    await tester.pump();
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(harness.messaging.sent, contains((peerSub, 'See you at the expo')));
    expect(find.text('See you at the expo'), findsOneWidget);
    // Field cleared → send button gone again.
    expect(find.byIcon(Icons.send_rounded), findsNothing);

    await unmount(tester);
  });

  testWidgets('long-press opens reaction picker and react() is called',
      (tester) async {
    await pumpChat(tester);

    await tester.longPress(find.text('Hi Asif'));
    await tester.pumpAndSettle();
    expect(find.text('❤️'), findsOneWidget);

    await tester.tap(find.text('❤️'));
    await tester.pumpAndSettle();

    expect(harness.messaging.reactions, contains((peerSub, 'm1', '❤️')));
    // Reaction chip now renders on the bubble (repo re-emitted the thread).
    expect(find.text('❤️'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('tapping the same reaction again clears it', (tester) async {
    await harness.messages.setReaction('m1', '👍');
    await pumpChat(tester);
    expect(find.text('👍'), findsOneWidget); // the chip

    await tester.longPress(find.text('Hi Asif'));
    await tester.pumpAndSettle();
    // Picker row + existing chip.
    expect(find.text('👍'), findsNWidgets(2));

    await tester.tap(find.text('👍').last);
    await tester.pumpAndSettle();

    expect(harness.messaging.reactions, contains((peerSub, 'm1', null)));
    expect(find.text('👍'), findsNothing);

    await unmount(tester);
  });

  testWidgets('nearby presence chip shows when the peer is in range',
      (tester) async {
    harness.messaging.nearbySubs.add(peerSub);
    await pumpChat(tester);
    expect(find.text('nearby'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('call icons hide when audio/video calls are disabled',
      (tester) async {
    harness.settings.allowVideoCall.value = false;
    harness.settings.allowAudioCall.value = false;
    await pumpChat(tester);
    expect(find.byIcon(Icons.videocam_outlined), findsNothing);
    expect(find.byIcon(Icons.phone_outlined), findsNothing);
    await unmount(tester);
  });
}
