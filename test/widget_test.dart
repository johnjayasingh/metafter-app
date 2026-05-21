import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:metafter/main.dart';

void main() {
  testWidgets('App initializes correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MetafterApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
