import 'package:flutter/foundation.dart';
import '../core/classifier.dart';
import '../core/disease.dart';
import '../core/leaf_analysis.dart';
import '../core/scoring.dart';
import 'models.dart';
import 'seed.dart';

class DemoState extends ChangeNotifier {
  final Classifier classifier;
  late List<Field> fields;
  late Weather weather;
  late List<Alert> alerts;
  late List<ExpertCase> cases;
  int verifiedLabels = 0;
  int neighbourDetections = 0;
  String selectedFieldId = 'TN-042';
  int _caseSeq = 0;

  DemoState({Classifier? classifier}) : classifier = classifier ?? HeuristicClassifier() {
    reset();
  }

  Field get selectedField => fields.firstWhere((f) => f.id == selectedFieldId);

  void reset() {
    fields = seedFields();
    weather = seedWeather();
    alerts = seedAlerts();
    cases = seedCases();
    verifiedLabels = 0;
    neighbourDetections = 0;
    selectedFieldId = 'TN-042';
    for (final f in fields) {
      _recomputeZonePriorities(f);
    }
    notifyListeners();
  }

  void selectField(String id) {
    selectedFieldId = id;
    notifyListeners();
  }

  ScanResult evaluate(LeafAnalysis a, {String? sampleId}) {
    final p = classifier.classify(a, sampleId: sampleId);
    final sev = p.anomaly ? 0.0 : a.severityPct;
    final wr = weatherRisk(p.disease, weather);
    final rel = p.anomaly
        ? Reliability.low
        : reliabilityLabel(
            confidence: p.confidence,
            margin: p.margin,
            quality: sampleId != null ? 0.9 : a.quality,
            weatherAgrees: weatherAgrees(p.disease, weather),
          );
    final fc = spreadForecast(severityPct: sev, weatherRisk: wr, neighbourDetections: neighbourDetections);
    final band = severityBand(sev);
    final action = actionFor(band: band, reliability: rel, anomaly: p.anomaly, spreadRisk72: fc.h72);
    if (action == ActionCategory.expert) {
      _caseSeq++;
      cases.insert(0, ExpertCase(id: 'case-$_caseSeq', prediction: p, severityPct: sev, reliability: rel, sampleId: sampleId));
      notifyListeners();
    }
    return ScanResult(prediction: p, analysis: a, reliability: rel, forecast: fc, action: action, band: band, sampleId: sampleId);
  }

  void addScan(String fieldId, ScanResult r) {
    final f = fields.firstWhere((x) => x.id == fieldId);
    final trendVal = switch (f.trend) { Trend.worsening => -0.5, Trend.stable => 0.0, Trend.improving => 0.5 };
    final score = healthScore(
      severityPct: r.prediction.anomaly ? 0 : r.analysis.severityPct,
      diseaseRisk: r.prediction.anomaly ? 0.3 : (r.prediction.disease == Disease.healthy ? 0.05 : r.prediction.confidence),
      weatherRisk: weatherRisk(r.prediction.disease, weather),
      trend: trendVal,
    );
    f.scans.add(Scan(
      at: DateTime.now(),
      disease: r.prediction.disease,
      severityPct: r.prediction.anomaly ? 0 : r.analysis.severityPct,
      score: score,
      reliability: r.reliability,
      anomaly: r.prediction.anomaly,
    ));
    _recomputeZonePriorities(f);
    notifyListeners();
  }

  void simulateNeighbourDetection() {
    neighbourDetections++;
    final wr = weatherRisk(Disease.lateBlight, weather);
    final fc = spreadForecast(severityPct: 14, weatherRisk: wr, neighbourDetections: neighbourDetections);
    final pct = (fc.h72 * 100).round();
    alerts.insert(
      0,
      Alert(
        at: DateTime.now(),
        title: 'Late blight confirmed 800 m away',
        body: 'A neighbour\'s scan confirmed late blight. Humidity ${weather.humidity.round()}%, ${weather.tempC.round()} C. Spread risk in 72 h: $pct%. Scout your field today.',
        bodyTamil: '800 மீ தொலைவில் பின் கருகல் நோய் உறுதி. 72 மணி நேரத்தில் பரவும் அபாயம் $pct%. இன்றே உங்கள் வயலை பரிசோதிக்கவும்.',
        forecast: fc,
      ),
    );
    for (final f in fields) {
      _recomputeZonePriorities(f);
    }
    notifyListeners();
  }

  void verifyCase(String caseId, Disease as) {
    final c = cases.firstWhere((x) => x.id == caseId);
    if (c.verifiedAs == null) verifiedLabels++;
    c.verifiedAs = as;
    notifyListeners();
  }

  List<Zone> scoutRoute(Field f) {
    final zs = f.zones.where((z) => z.priority > 60).toList()..sort((a, b) => b.priority.compareTo(a.priority));
    return zs;
  }

  void _recomputeZonePriorities(Field f) {
    final trendVal = switch (f.trend) { Trend.worsening => -0.5, Trend.stable => 0.0, Trend.improving => 0.5 };
    for (final z in f.zones) {
      final wr = weatherRisk(z.disease, weather);
      final fc = spreadForecast(severityPct: z.severityPct, weatherRisk: wr, neighbourDetections: neighbourDetections);
      final prob = z.disease == Disease.healthy ? 0.05 : 0.9;
      z.priority = priorityScore(probability: prob, severityPct: z.severityPct, spreadRisk: fc.h72, weatherRisk: wr, trend: trendVal);
    }
  }
}
