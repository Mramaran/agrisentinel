import 'dart:math';
import 'disease.dart';

enum SeverityBand { monitor, treat, remove }

SeverityBand severityBand(double pct) {
  if (pct < 5) return SeverityBand.monitor;
  if (pct <= 25) return SeverityBand.treat;
  return SeverityBand.remove;
}

enum Reliability { high, medium, low }

Reliability reliabilityLabel({
  required double confidence,
  required double margin,
  required double quality,
  required bool weatherAgrees,
}) {
  if (quality < 0.3 || margin < 0.15 || confidence < 0.6) return Reliability.low;
  if (confidence >= 0.85 && margin >= 0.4 && quality >= 0.6 && weatherAgrees) {
    return Reliability.high;
  }
  return Reliability.medium;
}

/// Favourable-weather rules per disease, each returns 0..1.
double weatherRisk(Disease d, Weather w) {
  double humid(double lo) => ((w.humidity - lo) / (100 - lo)).clamp(0.0, 1.0);
  double tempIn(double lo, double hi) => (w.tempC >= lo && w.tempC <= hi) ? 1 : 0.3;
  double rain() => (w.rainMm / 20).clamp(0.0, 1.0);
  switch (d) {
    case Disease.lateBlight:
      return (0.5 * humid(70) + 0.3 * tempIn(10, 25) + 0.2 * rain()).clamp(0.0, 1.0);
    case Disease.earlyBlight:
      return (0.5 * humid(60) + 0.3 * tempIn(24, 30) + 0.2 * rain()).clamp(0.0, 1.0);
    case Disease.septoria:
    case Disease.leafMold:
    case Disease.targetSpot:
      return (0.6 * humid(70) + 0.4 * rain()).clamp(0.0, 1.0);
    case Disease.bacterialSpot:
      return (0.5 * humid(65) + 0.5 * rain()).clamp(0.0, 1.0);
    case Disease.spiderMites:
      return (w.humidity < 50 && w.tempC > 28) ? 0.8 : 0.2;
    case Disease.yellowLeafCurl:
    case Disease.mosaicVirus:
      return (w.tempC > 26) ? 0.6 : 0.3; // whitefly and aphid vectors like warmth
    case Disease.healthy:
    case Disease.unknown:
      return 0;
  }
}

bool weatherAgrees(Disease d, Weather w) => d == Disease.healthy || d == Disease.unknown || weatherRisk(d, w) >= 0.5;

class SpreadForecast {
  final double h24, h48, h72;
  const SpreadForecast(this.h24, this.h48, this.h72);
}

SpreadForecast spreadForecast({
  required double severityPct,
  required double weatherRisk,
  required int neighbourDetections,
}) {
  final base = (0.15 + 0.5 * (severityPct / 100) + 0.4 * weatherRisk + 0.1 * min(neighbourDetections, 3)).clamp(0.0, 0.95);
  double at(double days) => (base * (0.55 + 0.45 * (days / 3))).clamp(0.0, 1.0);
  return SpreadForecast(at(1), at(2), at(3));
}

int healthScore({
  required double severityPct,
  required double diseaseRisk,
  required double weatherRisk,
  required double trend, // -1..1, negative is worsening
}) {
  final plantHealth = 100 - severityPct.clamp(0.0, 100.0);
  final score = 0.5 * plantHealth + 0.25 * (100 - 100 * diseaseRisk) + 0.15 * (100 - 100 * weatherRisk) + 0.10 * (50 + 50 * trend);
  return score.round().clamp(0, 100);
}

int priorityScore({
  required double probability,
  required double severityPct,
  required double spreadRisk,
  required double weatherRisk,
  required double trend,
}) {
  final sev = (severityPct / 40).clamp(0.0, 1.0);
  final worsening = ((-trend) + 1) / 2; // 0 improving .. 1 worsening
  final score = 100 * (0.30 * probability + 0.25 * sev + 0.25 * spreadRisk + 0.10 * weatherRisk + 0.10 * worsening);
  return score.round().clamp(0, 100);
}

enum PriorityBand { normal, monitor, inspect, immediate }

PriorityBand priorityBand(int score) {
  if (score <= 30) return PriorityBand.normal;
  if (score <= 60) return PriorityBand.monitor;
  if (score <= 80) return PriorityBand.inspect;
  return PriorityBand.immediate;
}

enum ActionCategory { monitor, inspect, prevent, treat, expert }

ActionCategory actionFor({
  required SeverityBand band,
  required Reliability reliability,
  required bool anomaly,
  required double spreadRisk72,
}) {
  if (anomaly || reliability == Reliability.low) return ActionCategory.expert;
  switch (band) {
    case SeverityBand.monitor:
      return spreadRisk72 >= 0.6 ? ActionCategory.prevent : ActionCategory.monitor;
    case SeverityBand.treat:
    case SeverityBand.remove:
      return ActionCategory.treat;
  }
}

String actionText(ActionCategory a) => switch (a) {
      ActionCategory.monitor => 'Monitor. No spray needed. Rescan in 48 hours.',
      ActionCategory.inspect => 'Inspect surrounding plants within 24 hours.',
      ActionCategory.prevent => 'Prevent: avoid leaf wetting, improve airflow, rescan in 48 hours.',
      ActionCategory.treat => 'Treat: remove affected leaves, follow KVK package of practice, rescan in 72 hours.',
      ActionCategory.expert => 'Expert verification recommended. Case sent to KVK console.',
    };

String actionTextTamil(ActionCategory a) => switch (a) {
      ActionCategory.monitor => 'கண்காணிக்கவும். தெளிப்பு தேவையில்லை. 48 மணி நேரத்தில் மீண்டும் ஸ்கேன் செய்யவும்.',
      ActionCategory.inspect => '24 மணி நேரத்திற்குள் அருகிலுள்ள செடிகளை பரிசோதிக்கவும்.',
      ActionCategory.prevent => 'தடுப்பு: இலை ஈரமாவதை தவிர்க்கவும், காற்றோட்டம் அதிகரிக்கவும்.',
      ActionCategory.treat => 'சிகிச்சை: பாதிக்கப்பட்ட இலைகளை அகற்றி, KVK பரிந்துரையை பின்பற்றவும்.',
      ActionCategory.expert => 'நிபுணர் சரிபார்ப்பு தேவை. KVK-க்கு அனுப்பப்பட்டது.',
    };

enum Trend { improving, stable, worsening }

Trend trendOf(List<int> scores) {
  if (scores.length < 2) return Trend.stable;
  final delta = scores.last - scores.first;
  if (delta <= -5) return Trend.worsening;
  if (delta >= 5) return Trend.improving;
  return Trend.stable;
}
