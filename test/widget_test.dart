// This is a basic Flutter widget test.

//import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unscroll/app.dart';

void main() {
  testWidgets('App should build without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const UnscrollApp());

    // Verify that the app title is present
    expect(find.text('Unscroll'), findsOneWidget);
  });
}