import 'package:flutter_test/flutter_test.dart';
import 'package:agrisentinel_demo/core/disease.dart';
import 'package:agrisentinel_demo/core/scoring.dart';

void main() {
  group('severityBand', () {
    test('under 5 is monitor', () => expect(severityBand(3.2), SeverityBand.monitor));
    test('5 to 25 is treat', () => expect(severityBand(12.0), SeverityBand.treat));
    test('over 25 is remove', () => expect(severityBand(31.0), SeverityBand.remove));
  });

  group('reliabilityLabel', () {
    test('confident, sharp, weather agrees is HIGH', () {
      expect(reliabilityLabel(confidence: 0.93, margin: 0.8, quality: 0.9, weatherAgrees: true), Reliability.high);
    });
    test('close top-2 is LOW', () {
      expect(reliabilityLabel(confidence: 0.51, margin: 0.09, quality: 0.9, weatherAgrees: true), Reliability.low);
    });
    test('blurry image is LOW', () {
      expect(reliabilityLabel(confidence: 0.9, margin: 0.7, quality: 0.1, weatherAgrees: true), Reliability.low);
    });
    test('good confidence but weather disagrees is MEDIUM', () {
      expect(reliabilityLabel(confidence: 0.9, margin: 0.7, quality: 0.9, weatherAgrees: false), Reliability.medium);
    });
  });

  group('weatherRisk', () {
    const humid = Weather(humidity: 88, tempC: 22, rainMm: 12);
    const dry = Weather(humidity: 40, tempC: 34, rainMm: 0);
    test('late blight loves humid cool weather', () => expect(weatherRisk(Disease.lateBlight, humid), greaterThan(0.7)));
    test('late blight risk is low in dry heat', () => expect(weatherRisk(Disease.lateBlight, dry), lessThan(0.3)));
    test('healthy has zero weather risk', () => expect(weatherRisk(Disease.healthy, humid), 0));
  });

  group('spreadForecast', () {
    test('rises over time and with neighbours', () {
      final f = spreadForecast(severityPct: 12, weatherRisk: 0.85, neighbourDetections: 2);
      expect(f.h24, lessThan(f.h48));
      expect(f.h48, lessThan(f.h72));
      expect(f.h72, greaterThan(0.6));
      final g = spreadForecast(severityPct: 12, weatherRisk: 0.85, neighbourDetections: 0);
      expect(g.h72, lessThan(f.h72));
    });
    test('never exceeds 1', () {
      final f = spreadForecast(severityPct: 90, weatherRisk: 1, neighbourDetections: 10);
      expect(f.h72, lessThanOrEqualTo(1.0));
    });
  });

  group('healthScore and priority', () {
    test('healthy field scores high', () {
      expect(healthScore(severityPct: 0, diseaseRisk: 0.1, weatherRisk: 0.2, trend: 0), greaterThan(85));
    });
    test('badly hit field scores low', () {
      expect(healthScore(severityPct: 40, diseaseRisk: 0.9, weatherRisk: 0.9, trend: -0.5), lessThan(40));
    });
    test('priority bands', () {
      expect(priorityBand(20), PriorityBand.normal);
      expect(priorityBand(45), PriorityBand.monitor);
      expect(priorityBand(70), PriorityBand.inspect);
      expect(priorityBand(91), PriorityBand.immediate);
    });
    test('priority score is high for severe spreading disease', () {
      expect(priorityScore(probability: 0.9, severityPct: 30, spreadRisk: 0.8, weatherRisk: 0.85, trend: -0.4), greaterThan(80));
    });
    test('priority score is low for a healthy zone', () {
      expect(priorityScore(probability: 0.05, severityPct: 0, spreadRisk: 0.1, weatherRisk: 0.3, trend: 0), lessThan(30));
    });
  });

  group('actionFor', () {
    test('anomaly goes to expert', () {
      expect(actionFor(band: SeverityBand.monitor, reliability: Reliability.high, anomaly: true, spreadRisk72: 0.2), ActionCategory.expert);
    });
    test('low reliability goes to expert', () {
      expect(actionFor(band: SeverityBand.treat, reliability: Reliability.low, anomaly: false, spreadRisk72: 0.2), ActionCategory.expert);
    });
    test('monitor band with low spread is monitor', () {
      expect(actionFor(band: SeverityBand.monitor, reliability: Reliability.high, anomaly: false, spreadRisk72: 0.2), ActionCategory.monitor);
    });
    test('monitor band with high spread is prevent', () {
      expect(actionFor(band: SeverityBand.monitor, reliability: Reliability.high, anomaly: false, spreadRisk72: 0.7), ActionCategory.prevent);
    });
    test('treat band is treat', () {
      expect(actionFor(band: SeverityBand.treat, reliability: Reliability.high, anomaly: false, spreadRisk72: 0.2), ActionCategory.treat);
    });
    test('remove band is treat', () {
      expect(actionFor(band: SeverityBand.remove, reliability: Reliability.medium, anomaly: false, spreadRisk72: 0.2), ActionCategory.treat);
    });
  });

  group('trendOf', () {
    test('falling scores are worsening', () => expect(trendOf([91, 87, 78]), Trend.worsening));
    test('rising scores are improving', () => expect(trendOf([62, 71, 84]), Trend.improving));
    test('flat scores are stable', () => expect(trendOf([80, 81, 80]), Trend.stable));
    test('single score is stable', () => expect(trendOf([80]), Trend.stable));
  });

  test('disease labels exist in English and Tamil', () {
    for (final d in Disease.values) {
      expect(d.label.isNotEmpty, true);
      expect(d.tamil.isNotEmpty, true);
    }
  });
}
