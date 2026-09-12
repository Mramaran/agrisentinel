import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrisentinel_demo/core/disease.dart';
import 'package:agrisentinel_demo/core/leaf_analysis.dart';
import 'package:agrisentinel_demo/core/scoring.dart';
import 'package:agrisentinel_demo/state/demo_state.dart';

LeafAnalysis _fake({bool isLeaf = true, double brown = 0, double quality = 0.9}) => LeafAnalysis(
      isLeaf: isLeaf, leafFraction: 0.7, lesionFraction: brown, yellowFraction: 0,
      brownFraction: brown, darkFraction: 0, quality: quality, maskPng: Uint8List(0),
    );

void main() {
  test('seed has two fields with expected trends', () {
    final s = DemoState();
    expect(s.fields.length, 2);
    expect(s.fields[0].trend, Trend.worsening);
    expect(s.fields[1].trend, Trend.improving);
    expect(s.fields[0].zones.length, 20);
    expect(s.alerts.isNotEmpty, true);
    expect(s.cases.isNotEmpty, true);
  });

  test('evaluate early blight sample gives treat and HIGH', () {
    final s = DemoState();
    final r = s.evaluate(_fake(brown: 0.12), sampleId: 'early_blight');
    expect(r.prediction.disease, Disease.earlyBlight);
    expect(r.band, SeverityBand.treat);
    expect(r.reliability, Reliability.high);
    expect(r.action, ActionCategory.treat);
  });

  test('evaluate ambiguous creates an expert case', () {
    final s = DemoState();
    final before = s.cases.length;
    final r = s.evaluate(_fake(brown: 0.1), sampleId: 'ambiguous');
    expect(r.reliability, Reliability.low);
    expect(r.action, ActionCategory.expert);
    expect(s.cases.length, before + 1);
  });

  test('addScan lowers score and flags progression', () {
    final s = DemoState();
    final f = s.fields[0];
    final before = f.score;
    final r = s.evaluate(_fake(brown: 0.3), sampleId: 'early_blight');
    s.addScan(f.id, r);
    expect(f.scans.last.severityPct, closeTo(30, 0.01));
    expect(f.score, lessThan(before));
    expect(f.trend, Trend.worsening);
  });

  test('simulateNeighbourDetection adds an alert with rising forecast', () {
    final s = DemoState();
    final before = s.alerts.length;
    s.simulateNeighbourDetection();
    expect(s.alerts.length, before + 1);
    final a = s.alerts.first;
    expect(a.forecast.h72, greaterThan(a.forecast.h24));
    expect(a.bodyTamil.isNotEmpty, true);
    expect(s.neighbourDetections, 1);
  });

  test('verifyCase increments the label counter', () {
    final s = DemoState();
    final id = s.cases.first.id;
    s.verifyCase(id, Disease.lateBlight);
    expect(s.cases.first.verifiedAs, Disease.lateBlight);
    expect(s.verifiedLabels, 1);
  });

  test('scoutRoute returns zones above inspect threshold in priority order', () {
    final s = DemoState();
    final route = s.scoutRoute(s.fields[0]);
    expect(route.isNotEmpty, true);
    expect(route.first.id, 'C');
    for (var i = 1; i < route.length; i++) {
      expect(route[i - 1].priority >= route[i].priority, true);
    }
  });

  test('seeded zones sit in the bands the spec calls for', () {
    final s = DemoState();
    final z = {for (final x in s.fields[0].zones) x.id: x};
    expect(priorityBand(z['C']!.priority), PriorityBand.immediate);
    expect(priorityBand(z['H']!.priority), PriorityBand.inspect);
    expect(priorityBand(z['D']!.priority), PriorityBand.monitor);
    expect(priorityBand(z['A']!.priority), PriorityBand.normal);
  });

  test('reset restores the seed', () {
    final s = DemoState();
    s.simulateNeighbourDetection();
    s.reset();
    expect(s.neighbourDetections, 0);
    expect(s.alerts.length, 1);
  });
}
