import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/disease.dart';
import '../core/scoring.dart';
import '../main.dart';
import '../state/demo_state.dart';
import '../widgets/score_gauge.dart';

class FieldScreen extends StatelessWidget {
  final String fieldId;
  const FieldScreen({super.key, required this.fieldId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DemoState>();
    final f = state.fields.firstWhere((x) => x.id == fieldId);
    final scores = f.scoreHistory;
    final last = f.scans.last;
    final prev = f.scans.length > 1 ? f.scans[f.scans.length - 2] : null;
    final banner = switch (f.trend) {
      Trend.worsening => ('Progression detected: affected area ${prev?.severityPct.toStringAsFixed(0) ?? '0'}% to ${last.severityPct.toStringAsFixed(0)}%', kRed),
      Trend.improving => ('Recovery: affected area ${prev?.severityPct.toStringAsFixed(0) ?? '0'}% to ${last.severityPct.toStringAsFixed(0)}%', kGreen),
      Trend.stable => ('Stable', kNavy),
    };
    final wr = weatherRisk(last.disease, state.weather);
    final diseaseRisk = last.disease == Disease.healthy ? 0.05 : 0.8;

    return Scaffold(
      appBar: AppBar(title: Text('${f.name}  ·  ${f.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Crop Digital Twin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kNavy)),
          const SizedBox(height: 8),
          Row(children: [
            ScoreGauge(score: f.score, size: 96),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _bar('Plant health', (100 - last.severityPct) / 100),
                _bar('Disease risk', diseaseRisk),
                _bar('Weather risk', wr),
                _bar('Severity', last.severityPct / 100),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: banner.$2.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Text(banner.$1, style: TextStyle(color: banner.$2, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          const Text('Health score over scans', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(
            height: 180,
            child: LineChart(LineChartData(
              minY: 0, maxY: 100,
              titlesData: const FlTitlesData(rightTitles: AxisTitles(), topTitles: AxisTitles()),
              lineBarsData: [
                LineChartBarData(
                  spots: [for (var i = 0; i < scores.length; i++) FlSpot(i.toDouble(), scores[i].toDouble())],
                  color: kGreen, barWidth: 3, isCurved: false, dotData: const FlDotData(show: true),
                ),
              ],
            )),
          ),
          const SizedBox(height: 12),
          const Text('Scan history', style: TextStyle(fontWeight: FontWeight.bold)),
          for (final s in f.scans.reversed)
            ListTile(
              dense: true,
              leading: Text('${s.score}', style: TextStyle(fontWeight: FontWeight.bold, color: scoreColor(s.score))),
              title: Text(s.disease.label),
              subtitle: Text('${s.at.day}/${s.at.month}  ·  severity ${s.severityPct.toStringAsFixed(1)}%  ·  ${s.reliability.name.toUpperCase()}'),
            ),
        ],
      ),
    );
  }

  Widget _bar(String label, double v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(child: LinearProgressIndicator(value: v.clamp(0, 1), minHeight: 8, color: kGreen, backgroundColor: kGreen.withValues(alpha: 0.15))),
          const SizedBox(width: 8),
          SizedBox(width: 36, child: Text('${(v * 100).round()}', style: const TextStyle(fontSize: 12))),
        ]),
      );
}
