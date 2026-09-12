import 'disease.dart';
import 'leaf_analysis.dart';

const kSampleIds = ['healthy', 'early_blight', 'late_blight', 'yellow_leaf_curl', 'ambiguous', 'not_a_leaf'];
String sampleAsset(String id) => 'assets/samples/$id.jpg';

class Prediction {
  final Disease disease;
  final double confidence;
  final double margin;
  final List<(Disease, double)> top3;
  final bool anomaly;
  const Prediction({
    required this.disease,
    required this.confidence,
    required this.margin,
    required this.top3,
    required this.anomaly,
  });

  String get label => disease.label;
  String get tamil => disease.tamil;
}

abstract class Classifier {
  Prediction classify(LeafAnalysis a, {String? sampleId});
}

class HeuristicClassifier implements Classifier {
  static const _sampleLabels = {
    'healthy': Disease.healthy,
    'early_blight': Disease.earlyBlight,
    'late_blight': Disease.lateBlight,
    'yellow_leaf_curl': Disease.yellowLeafCurl,
  };

  @override
  Prediction classify(LeafAnalysis a, {String? sampleId}) {
    if (sampleId == 'not_a_leaf' || (sampleId == null && !a.isLeaf)) {
      return const Prediction(
        disease: Disease.unknown, confidence: 0.31, margin: 0.05,
        top3: [(Disease.unknown, 0.31), (Disease.lateBlight, 0.26), (Disease.earlyBlight, 0.22)],
        anomaly: true,
      );
    }
    if (sampleId == 'ambiguous') {
      return const Prediction(
        disease: Disease.lateBlight, confidence: 0.51, margin: 0.09,
        top3: [(Disease.lateBlight, 0.51), (Disease.earlyBlight, 0.42), (Disease.healthy, 0.07)],
        anomaly: false,
      );
    }
    if (sampleId != null && _sampleLabels.containsKey(sampleId)) {
      return _confident(_sampleLabels[sampleId]!, 0.93);
    }
    if (!a.isLeaf) {
      return classify(a, sampleId: 'not_a_leaf');
    }
    // Gallery image: colour rules.
    final y = a.yellowFraction, b = a.brownFraction, d = a.darkFraction;
    final lesion = y + b + d;
    if (lesion < 0.03) return _confident(Disease.healthy, 0.90);
    final Disease top;
    if (y >= b && y >= d) {
      top = Disease.yellowLeafCurl;
    } else if (b >= d) {
      top = Disease.earlyBlight;
    } else {
      top = Disease.lateBlight;
    }
    final sorted = [y, b, d]..sort((p, q) => q.compareTo(p));
    final dominance = sorted[0] == 0 ? 0.0 : (sorted[0] - sorted[1]) / sorted[0];
    final conf = (0.55 + 0.4 * dominance).clamp(0.5, 0.95);
    return _confident(top, conf);
  }

  Prediction _confident(Disease top, double conf) {
    final rest = 1 - conf;
    final second = _runnerUp(top);
    final third = _third(top, second);
    return Prediction(
      disease: top,
      confidence: conf,
      margin: conf - rest * 0.7,
      top3: [(top, conf), (second, rest * 0.7), (third, rest * 0.3)],
      anomaly: false,
    );
  }

  Disease _runnerUp(Disease d) => switch (d) {
        Disease.earlyBlight => Disease.lateBlight,
        Disease.lateBlight => Disease.earlyBlight,
        Disease.yellowLeafCurl => Disease.mosaicVirus,
        Disease.healthy => Disease.earlyBlight,
        _ => Disease.healthy,
      };

  Disease _third(Disease d, Disease second) {
    for (final x in [Disease.septoria, Disease.targetSpot, Disease.healthy]) {
      if (x != d && x != second) return x;
    }
    return Disease.bacterialSpot;
  }
}
