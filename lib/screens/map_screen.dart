import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/disease.dart';
import '../core/scoring.dart';
import '../main.dart';
import '../state/demo_state.dart';
import '../state/models.dart';
import '../widgets/score_gauge.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _showRoute = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DemoState>();
    final f = state.selectedField;
    final route = state.scoutRoute(f);
    final order = {for (var i = 0; i < route.length; i++) route[i].id: i + 1};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Expanded(child: DropdownButton<String>(
            value: state.selectedFieldId,
            isExpanded: true,
            items: [for (final x in state.fields) DropdownMenuItem(value: x.id, child: Text('${x.name}  ·  ${x.id}  ·  ${x.acres.toStringAsFixed(0)} acres'))],
            onChanged: (v) => v == null ? null : state.selectField(v),
          )),
          const SizedBox(width: 8),
          FilterChip(label: const Text('AI Scout route'), selected: _showRoute, onSelected: (v) => setState(() => _showRoute = v)),
        ]),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 5 / 4,
          child: GridView.count(
            crossAxisCount: 5,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: [
              for (final z in f.zones)
                InkWell(
                  key: ValueKey('zone-${z.id}'),
                  onTap: () => _showZone(context, z, state),
                  child: Container(
                    decoration: BoxDecoration(color: bandColor(priorityBand(z.priority)), borderRadius: BorderRadius.circular(8)),
                    child: Stack(children: [
                      Center(child: Text(z.id, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                      Positioned(bottom: 4, right: 6, child: Text('${z.health}', style: const TextStyle(color: Colors.white, fontSize: 11))),
                      if (_showRoute && order.containsKey(z.id))
                        Positioned(
                          top: 4, left: 4,
                          child: CircleAvatar(radius: 11, backgroundColor: Colors.white, child: Text('${order[z.id]}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kNavy))),
                        ),
                    ]),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 12, children: [
          for (final b in PriorityBand.values)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: bandColor(b), shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(b.name),
            ]),
        ]),
        const SizedBox(height: 12),
        if (_showRoute)
          Card(
            color: kMoss.withValues(alpha: 0.25),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AI Scout: inspect ${route.length} of 20 zones', style: const TextStyle(fontWeight: FontWeight.bold, color: kNavy)),
                Text('Route: ${route.map((z) => 'Zone ${z.id}').join(' → ')}'),
                Text('Estimated walking area: ${(route.length / 20 * f.acres).toStringAsFixed(1)} of ${f.acres.toStringAsFixed(0)} acres (simulated)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            ),
          ),
      ],
    );
  }

  void _showZone(BuildContext context, Zone z, DemoState state) {
    final band = priorityBand(z.priority);
    final wr = weatherRisk(z.disease, state.weather);
    final fc = spreadForecast(severityPct: z.severityPct, weatherRisk: wr, neighbourDetections: state.neighbourDetections);
    final action = actionFor(band: severityBand(z.severityPct), reliability: Reliability.high, anomaly: false, spreadRisk72: fc.h72);
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ScoreGauge(score: z.health, size: 64),
            const SizedBox(width: 12),
            Expanded(child: Text('Zone ${z.id}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kNavy))),
            Chip(label: Text(band.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: bandColor(band), side: BorderSide.none),
          ]),
          const SizedBox(height: 12),
          Text('Disease: ${z.disease.label}'),
          Text('Severity: ${z.severityPct.toStringAsFixed(0)}%'),
          Text('Spread risk 72 h: ${(fc.h72 * 100).round()}%'),
          Text('Priority score: ${z.priority}/100'),
          const SizedBox(height: 8),
          Text(actionText(action), style: const TextStyle(fontWeight: FontWeight.bold)),
          if (band == PriorityBand.immediate) const Text('Inspect within 24 hours.', style: TextStyle(color: kRed)),
        ]),
      ),
    );
  }
}
