import '../core/classifier.dart';
import '../core/disease.dart';
import '../core/leaf_analysis.dart';
import '../core/scoring.dart';

class Scan {
  final DateTime at;
  final Disease disease;
  final double severityPct;
  final int score;
  final Reliability reliability;
  final bool anomaly;
  const Scan({
    required this.at,
    required this.disease,
    required this.severityPct,
    required this.score,
    required this.reliability,
    required this.anomaly,
  });
}

class Zone {
  final String id;
  final int health;
  final double severityPct;
  final Disease disease;
  int priority;
  Zone({required this.id, required this.health, required this.severityPct, required this.disease, this.priority = 0});
}

class Field {
  final String id;
  final String name;
  final String crop;
  final double acres;
  final String stage;
  final List<Scan> scans;
  final List<Zone> zones;
  Field({
    required this.id,
    required this.name,
    required this.crop,
    required this.acres,
    required this.stage,
    required this.scans,
    required this.zones,
  });

  int get score => scans.isEmpty ? 100 : scans.last.score;
  Trend get trend => trendOf(scans.map((s) => s.score).toList());
  List<int> get scoreHistory => scans.map((s) => s.score).toList();
}

class Alert {
  final DateTime at;
  final String title;
  final String body;
  final String bodyTamil;
  final SpreadForecast forecast;
  const Alert({required this.at, required this.title, required this.body, required this.bodyTamil, required this.forecast});
}

class ExpertCase {
  final String id;
  final Prediction prediction;
  final double severityPct;
  final Reliability reliability;
  final String? sampleId;
  Disease? verifiedAs;
  ExpertCase({
    required this.id,
    required this.prediction,
    required this.severityPct,
    required this.reliability,
    this.sampleId,
    this.verifiedAs,
  });
}

class ScanResult {
  final Prediction prediction;
  final LeafAnalysis analysis;
  final Reliability reliability;
  final SpreadForecast forecast;
  final ActionCategory action;
  final SeverityBand band;
  final String? sampleId;
  const ScanResult({
    required this.prediction,
    required this.analysis,
    required this.reliability,
    required this.forecast,
    required this.action,
    required this.band,
    this.sampleId,
  });
}
