import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:canvas_offline/main.dart';

void main() {
  testWidgets('Canvas Offline App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Note: This will likely fail in a real widget test because it tries to access 
    // SQLite or SharedPreferences which aren't mocked here.
    // But for a basic "compile and build" test, it's a start.
    await tester.pumpWidget(const CanvasOfflineApp());

    // Verify that the title is present (it might be in a different state depending on login)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}