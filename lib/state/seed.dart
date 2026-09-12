import '../core/classifier.dart';
import '../core/disease.dart';
import '../core/scoring.dart';
import 'models.dart';

final _now = DateTime(2026, 9, 12);

Scan _scan(int daysAgo, int score, Disease d, double sev) => Scan(
      at: _now.subtract(Duration(days: daysAgo)),
      disease: d,
      severityPct: sev,
      score: score,
      reliability: Reliability.high,
      anomaly: false,
    );

List<Zone> _zonesTn042() {
  const ids = 'ABCDEFGHIJKLMNOPQRST';
  // Severities are chosen so the computed priority lands in the band the spec
  // names for each zone: C immediate, H inspect, D monitor, the rest normal.
  const special = {'C': (43, 38.0, Disease.lateBlight), 'D': (71, 7.0, Disease.lateBlight), 'H': (58, 16.0, Disease.earlyBlight)};
  return [
    for (var i = 0; i < 20; i++)
      () {
        final id = ids[i];
        if (special.containsKey(id)) {
          final (h, s, d) = special[id]!;
          return Zone(id: id, health: h, severityPct: s, disease: d);
        }
        return Zone(id: id, health: 85 + (i * 7) % 11, severityPct: 0, disease: Disease.healthy);
      }(),
  ];
}

List<Zone> _zonesTn043() {
  const ids = 'ABCDEFGHIJKLMNOPQRST';
  return [for (var i = 0; i < 20; i++) Zone(id: ids[i], health: 80 + (i * 5) % 15, severityPct: i == 6 ? 4 : 0, disease: i == 6 ? Disease.earlyBlight : Disease.healthy)];
}

List<Field> seedFields() => [
      Field(
        id: 'TN-042', name: 'Annur North', crop: 'Tomato', acres: 12, stage: 'Flowering',
        scans: [_scan(11, 91, Disease.healthy, 0), _scan(8, 87, Disease.earlyBlight, 4), _scan(5, 78, Disease.earlyBlight, 11)],
        zones: _zonesTn042(),
      ),
      Field(
        id: 'TN-043', name: 'Thondamuthur', crop: 'Tomato', acres: 6, stage: 'Fruiting',
        scans: [_scan(12, 62, Disease.lateBlight, 22), _scan(7, 71, Disease.lateBlight, 12), _scan(2, 84, Disease.lateBlight, 4)],
        zones: _zonesTn043(),
      ),
    ];

Weather seedWeather() => const Weather(humidity: 88, tempC: 22, rainMm: 12);

List<Alert> seedAlerts() => [
      Alert(
        at: _now.subtract(const Duration(days: 1)),
        title: 'Early blight confirmed 1.6 km away',
        body: 'Confirmed early blight at a neighbouring farm. Weather favourable for 3 days. Scout your lower leaves today.',
        bodyTamil: '1.6 கி.மீ தொலைவில் முன் கருகல் நோய் உறுதி. வானிலை நோய்க்கு சாதகம். இன்று கீழ் இலைகளை பரிசோதிக்கவும்.',
        forecast: const SpreadForecast(0.38, 0.52, 0.66),
      ),
    ];

List<ExpertCase> seedCases() => [
      ExpertCase(
        id: 'case-seed-1',
        prediction: const Prediction(
          disease: Disease.lateBlight, confidence: 0.54, margin: 0.11,
          top3: [(Disease.lateBlight, 0.54), (Disease.earlyBlight, 0.43), (Disease.healthy, 0.03)],
          anomaly: false,
        ),
        severityPct: 9,
        reliability: Reliability.low,
        sampleId: 'ambiguous',
      ),
    ];
