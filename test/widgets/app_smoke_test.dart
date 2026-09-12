import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrisentinel_demo/main.dart';

void main() {
  testWidgets('app shows five navigation tabs', (tester) async {
    await tester.pumpWidget(const AgriSentinelApp());
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    for (final label in ['Home', 'Scan', 'Map', 'Alerts', 'Expert']) {
      expect(find.text(label), findsWidgets);
    }
  });
}
