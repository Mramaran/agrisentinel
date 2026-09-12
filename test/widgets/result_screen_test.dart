import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:agrisentinel_demo/core/leaf_analysis.dart';
import 'package:agrisentinel_demo/screens/result_screen.dart';
import 'package:agrisentinel_demo/state/demo_state.dart';

LeafAnalysis _fake({bool isLeaf = true, double brown = 0.12}) => LeafAnalysis(
      isLeaf: isLeaf, leafFraction: 0.7, lesionFraction: brown, yellowFraction: 0,
      brownFraction: brown, darkFraction: 0, quality: 0.9, maskPng: Uint8List(0),
    );

void main() {
  testWidgets('result shows disease, severity, reliability and action', (tester) async {
    final state = DemoState();
    final r = state.evaluate(_fake(), sampleId: 'early_blight');
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(home: ResultScreen(result: r, imageBytes: Uint8List(0))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Early blight'), findsOneWidget);
    expect(find.textContaining('12.0%'), findsOneWidget);
    expect(find.text('RELIABILITY HIGH'), findsOneWidget);
    expect(find.textContaining('Treat'), findsWidgets);
    // The save button sits below the fold on a phone-sized viewport.
    await tester.scrollUntilVisible(find.text('Save to field'), 200);
    expect(find.text('Save to field'), findsOneWidget);
  });

  testWidgets('ambiguous result shows LOW and expert line', (tester) async {
    final state = DemoState();
    final r = state.evaluate(_fake(), sampleId: 'ambiguous');
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(home: ResultScreen(result: r, imageBytes: Uint8List(0))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('RELIABILITY LOW'), findsOneWidget);
    expect(find.textContaining('Expert verification'), findsWidgets);
  });

  testWidgets('not a leaf shows anomaly chip', (tester) async {
    final state = DemoState();
    final r = state.evaluate(_fake(isLeaf: false), sampleId: 'not_a_leaf');
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(home: ResultScreen(result: r, imageBytes: Uint8List(0))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('UNKNOWN ANOMALY'), findsOneWidget);
  });
}
