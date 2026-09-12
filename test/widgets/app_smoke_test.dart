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

  testWidgets('home lists both seeded fields with scores', (tester) async {
    await tester.pumpWidget(const AgriSentinelApp());
    await tester.pumpAndSettle();
    expect(find.textContaining('Annur North'), findsOneWidget);
    expect(find.textContaining('Thondamuthur'), findsOneWidget);
    expect(find.text('78'), findsOneWidget);
    expect(find.text('84'), findsOneWidget);
    expect(find.textContaining('Worsening'), findsOneWidget);
    expect(find.textContaining('Improving'), findsOneWidget);
  });
}
