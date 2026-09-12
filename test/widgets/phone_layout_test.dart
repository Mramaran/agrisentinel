import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:agrisentinel_demo/core/leaf_analysis.dart';
import 'package:agrisentinel_demo/main.dart';
import 'package:agrisentinel_demo/screens/field_screen.dart';
import 'package:agrisentinel_demo/screens/result_screen.dart';
import 'package:agrisentinel_demo/state/demo_state.dart';

/// Pixel-class phone: 411 x 891 logical pixels. Narrow enough to expose any
/// Row that cannot fit, which the default 800x600 test surface hides.
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(411, 891);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

LeafAnalysis _fake() => LeafAnalysis(
      isLeaf: true, leafFraction: 0.7, lesionFraction: 0.12, yellowFraction: 0,
      brownFraction: 0.12, darkFraction: 0, quality: 0.9, maskPng: Uint8List(0),
    );

void main() {
  testWidgets('every tab lays out on a phone without overflow', (tester) async {
    _phone(tester);
    await tester.pumpWidget(const AgriSentinelApp());
    await tester.pumpAndSettle();
    for (final tab in ['Home', 'Scan', 'Map', 'Alerts', 'Expert']) {
      // "Scan" also labels the card buttons, so target the nav bar itself.
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(tab)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$tab tab overflowed');
    }
  });

  testWidgets('field and result screens lay out on a phone', (tester) async {
    _phone(tester);
    final state = DemoState();
    final r = state.evaluate(_fake(), sampleId: 'early_blight');
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: state,
      child: const MaterialApp(home: FieldScreen(fieldId: 'TN-042')),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'FieldScreen overflowed');

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(home: ResultScreen(result: r, imageBytes: Uint8List(0))),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'ResultScreen overflowed');
  });
}
