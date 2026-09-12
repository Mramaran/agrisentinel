import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/scoring.dart';
import '../main.dart';
import '../state/demo_state.dart';
import '../widgets/score_gauge.dart';
import 'field_screen.dart';

class HomeScreen extends StatelessWidget {
  final void Function(String fieldId) onScan;
  const HomeScreen({super.key, required this.onScan});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DemoState>();
    final w = state.weather;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: kMoss.withValues(alpha: 0.25),
          child: ListTile(
            leading: const Icon(Icons.cloud_outlined, color: kNavy),
            title: Text('Coimbatore  ·  ${w.humidity.round()}% humidity  ·  ${w.tempC.round()} °C  ·  ${w.rainMm.round()} mm rain'),
            subtitle: const Text('Late blight favourable for the next 3 days'),
          ),
        ),
        const SizedBox(height: 8),
        for (final f in state.fields)
          Card(
            child: InkWell(
              onTap: () {
                state.selectField(f.id);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => FieldScreen(fieldId: f.id)));
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ScoreGauge(score: f.score),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${f.name}  ·  ${f.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('${f.crop}, ${f.acres.toStringAsFixed(0)} acres, ${f.stage}'),
                          const SizedBox(height: 4),
                          Row(children: [
                            Icon(
                              switch (f.trend) { Trend.worsening => Icons.trending_down, Trend.improving => Icons.trending_up, Trend.stable => Icons.trending_flat },
                              color: switch (f.trend) { Trend.worsening => kRed, Trend.improving => kGreen, Trend.stable => kNavy },
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                switch (f.trend) { Trend.worsening => 'Worsening', Trend.improving => 'Improving', Trend.stable => 'Stable' },
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text('${f.scans.length} scans',
                                  style: const TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis, textAlign: TextAlign.end),
                            ),
                          ]),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => onScan(f.id),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Scan'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
