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

  testWidgets('tapping a field opens the digital twin with a progression banner', (tester) async {
    await tester.pumpWidget(const AgriSentinelApp());
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Annur North'));
    await tester.pumpAndSettle();
    expect(find.text('Crop Digital Twin'), findsOneWidget);
    expect(find.textContaining('Progression detected'), findsOneWidget);
  });

  testWidgets('simulating a neighbour detection adds an alert', (tester) async {
    await tester.pumpWidget(const AgriSentinelApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alerts'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1.6 km away'), findsOneWidget);
    await tester.tap(find.text('Simulate neighbour detection'));
    await tester.pumpAndSettle();
    // the caption under the button also says "800 m away", so match the alert title
    expect(find.textContaining('Late blight confirmed 800 m away'), findsOneWidget);
    expect(find.textContaining('Spread risk'), findsWidgets);
  });

  testWidgets('expert can verify a case and the counter increments', (tester) async {
    await tester.pumpWidget(const AgriSentinelApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expert'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Verified labels: 0'), findsOneWidget);
    await tester.tap(find.text('Verify').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Verified labels: 1'), findsOneWidget);
    expect(find.textContaining('Verified as'), findsOneWidget);
  });
}
