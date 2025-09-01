import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:visiting_card_app/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VisitingCardApp());

    // Verify that the app shows the title
    expect(find.text('Visiting Card OCR'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsWidgets);
  });
}
