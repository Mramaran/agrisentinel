import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/disease.dart';
import '../core/scoring.dart';
import '../main.dart';
import '../state/demo_state.dart';
import '../state/models.dart';
import '../widgets/reliability_chip.dart';
import '../widgets/speak_button.dart';

class ResultScreen extends StatelessWidget {
  final ScanResult result;
  final Uint8List imageBytes;
  const ResultScreen({super.key, required this.result, required this.imageBytes});

  @override
  Widget build(BuildContext context) {
    final p = result.prediction;
    final state = context.read<DemoState>();
    final sevText = p.anomaly ? 'n/a' : '${result.analysis.severityPct.toStringAsFixed(1)}%';
    final bandText = switch (result.band) { SeverityBand.monitor => 'monitor', SeverityBand.treat => 'treat', SeverityBand.remove => 'remove' };
    final english = '${p.label}. Severity $sevText. ${actionText(result.action)}';
    final tamil = '${p.tamil}. ${actionTextTamil(result.action)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Scan result')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (imageBytes.isNotEmpty)
            Row(children: [
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(imageBytes, height: 180, fit: BoxFit.cover))),
              const SizedBox(width: 8),
              Expanded(
                child: result.analysis.maskPng.isNotEmpty
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(result.analysis.maskPng, height: 180, fit: BoxFit.cover))
                    : const SizedBox(height: 180),
              ),
            ]),
          if (imageBytes.isNotEmpty) const Padding(padding: EdgeInsets.only(top: 4), child: Text('Left: photo.  Right: lesion map (red = affected).', style: TextStyle(color: Colors.grey, fontSize: 12))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Text(p.disease.label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kNavy))),
            ReliabilityChip(reliability: result.reliability, anomaly: p.anomaly),
          ]),
          Text(p.disease.tamil, style: const TextStyle(fontSize: 16, color: kGreen)),
          const SizedBox(height: 12),
          _kv('Confidence', '${(p.confidence * 100).round()}%'),
          _kv('Top-3', p.top3.map((e) => '${e.$1.label} ${(e.$2 * 100).round()}%').join('  ·  ')),
          _kv('Severity', '$sevText  ($bandText band)'),
          _kv('Weather risk', '${(weatherRisk(p.disease, state.weather) * 100).round()}%'),
          _kv('Spread risk 24 / 48 / 72 h', '${(result.forecast.h24 * 100).round()}% / ${(result.forecast.h48 * 100).round()}% / ${(result.forecast.h72 * 100).round()}%'),
          const SizedBox(height: 12),
          Card(
            color: kMoss.withValues(alpha: 0.25),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Action: ${result.action.name.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, color: kNavy)),
                const SizedBox(height: 4),
                Text(actionText(result.action)),
                const SizedBox(height: 4),
                Text(actionTextTamil(result.action), style: const TextStyle(color: kGreen)),
              ]),
            ),
          ),
          if (p.anomaly || result.reliability == Reliability.low)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Expert verification recommended. This case has been added to the KVK console.', style: TextStyle(color: kRed)),
            ),
          const SizedBox(height: 12),
          SpeakButton(english: english, tamil: tamil),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              state.addScan(state.selectedFieldId, result);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to ${state.selectedFieldId}. Field score is now ${state.selectedField.score}.')));
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save to field'),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 170, child: Text(k, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(v)),
        ]),
      );
}
