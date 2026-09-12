import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/classifier.dart';
import '../core/disease.dart';
import '../main.dart';
import '../state/demo_state.dart';
import '../widgets/reliability_chip.dart';

class ExpertScreen extends StatelessWidget {
  const ExpertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DemoState>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: kMoss.withValues(alpha: 0.25),
          child: ListTile(
            leading: const Icon(Icons.school_outlined, color: kNavy),
            title: const Text('KVK expert console'),
            subtitle: Text('Verified labels: ${state.verifiedLabels}  ·  open cases: ${state.cases.where((c) => c.verifiedAs == null).length}'),
          ),
        ),
        const SizedBox(height: 8),
        for (final c in state.cases)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (c.sampleId != null)
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset(sampleAsset(c.sampleId!), width: 64, height: 64, fit: BoxFit.cover))
                  else
                    const Icon(Icons.image_outlined, size: 48, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.id, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(c.prediction.top3.map((e) => '${e.$1.label} ${(e.$2 * 100).round()}%').join('  ·  ')),
                      Text('Severity ${c.severityPct.toStringAsFixed(0)}%'),
                    ]),
                  ),
                  ReliabilityChip(reliability: c.reliability, anomaly: c.prediction.anomaly),
                ]),
                const SizedBox(height: 8),
                if (c.verifiedAs != null)
                  Text('Verified as ${c.verifiedAs!.label}. Added to training set.', style: const TextStyle(color: kGreen, fontWeight: FontWeight.bold))
                else
                  Row(children: [
                    FilledButton(
                      onPressed: () => state.verifyCase(c.id, c.prediction.disease == Disease.unknown ? Disease.lateBlight : c.prediction.disease),
                      child: const Text('Verify'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final d = await showDialog<Disease>(
                          context: context,
                          builder: (_) => SimpleDialog(
                            title: const Text('Correct label'),
                            children: [
                              for (final d in Disease.values.where((d) => d != Disease.unknown))
                                SimpleDialogOption(onPressed: () => Navigator.pop(context, d), child: Text(d.label)),
                            ],
                          ),
                        );
                        if (d != null) state.verifyCase(c.id, d);
                      },
                      child: const Text('Correct'),
                    ),
                  ]),
              ]),
            ),
          ),
      ],
    );
  }
}
