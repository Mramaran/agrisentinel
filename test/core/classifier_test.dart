import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrisentinel_demo/core/classifier.dart';
import 'package:agrisentinel_demo/core/disease.dart';
import 'package:agrisentinel_demo/core/leaf_analysis.dart';

LeafAnalysis _fake({bool isLeaf = true, double yellow = 0, double brown = 0, double dark = 0, double quality = 0.9}) {
  return LeafAnalysis(
    isLeaf: isLeaf, leafFraction: 0.7, lesionFraction: yellow + brown + dark,
    yellowFraction: yellow, brownFraction: brown, darkFraction: dark,
    quality: quality, maskPng: Uint8List(0),
  );
}

void main() {
  final c = HeuristicClassifier();

  test('sample ids map to known labels', () {
    expect(c.classify(_fake(brown: 0.1), sampleId: 'early_blight').disease, Disease.earlyBlight);
    expect(c.classify(_fake(dark: 0.1), sampleId: 'late_blight').disease, Disease.lateBlight);
    expect(c.classify(_fake(), sampleId: 'healthy').disease, Disease.healthy);
    expect(c.classify(_fake(yellow: 0.2), sampleId: 'yellow_leaf_curl').disease, Disease.yellowLeafCurl);
  });

  test('ambiguous sample has a small margin', () {
    final p = c.classify(_fake(brown: 0.1), sampleId: 'ambiguous');
    expect(p.margin, lessThan(0.15));
    expect(p.top3.length, 3);
  });

  test('not a leaf is an anomaly', () {
    final p = c.classify(_fake(isLeaf: false), sampleId: 'not_a_leaf');
    expect(p.anomaly, true);
    expect(p.disease, Disease.unknown);
  });

  test('gallery image without leaf is an anomaly', () {
    expect(c.classify(_fake(isLeaf: false)).anomaly, true);
  });

  test('gallery image colour rules', () {
    expect(c.classify(_fake()).disease, Disease.healthy);
    expect(c.classify(_fake(yellow: 0.2, brown: 0.02)).disease, Disease.yellowLeafCurl);
    expect(c.classify(_fake(brown: 0.15, dark: 0.02)).disease, Disease.earlyBlight);
    expect(c.classify(_fake(dark: 0.15, brown: 0.02)).disease, Disease.lateBlight);
  });

  test('confidence is between 0.5 and 0.98 and top3 sums to about 1', () {
    final p = c.classify(_fake(brown: 0.15));
    expect(p.confidence, inInclusiveRange(0.5, 0.98));
    final sum = p.top3.fold<double>(0, (s, e) => s + e.$2);
    expect(sum, closeTo(1.0, 0.05));
  });
}
