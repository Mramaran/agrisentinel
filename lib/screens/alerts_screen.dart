import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../state/demo_state.dart';
import '../widgets/speak_button.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DemoState>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: kOrange),
          onPressed: () => state.simulateNeighbourDetection(),
          icon: const Icon(Icons.sensors),
          label: const Text('Simulate neighbour detection'),
        ),
        const SizedBox(height: 4),
        Text('Demo: a farm 800 m away confirms late blight under ${state.weather.humidity.round()}% humidity.', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 12),
        for (final a in state.alerts)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: kOrange),
                  const SizedBox(width: 8),
                  Expanded(child: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold, color: kNavy))),
                  Text('${a.at.day}/${a.at.month} ${a.at.hour.toString().padLeft(2, '0')}:${a.at.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ]),
                const SizedBox(height: 6),
                Text(a.body),
                const SizedBox(height: 4),
                Text(a.bodyTamil, style: const TextStyle(color: kGreen)),
                const SizedBox(height: 8),
                Row(children: [
                  _risk('24 h', a.forecast.h24),
                  _risk('48 h', a.forecast.h48),
                  _risk('72 h', a.forecast.h72),
                ]),
                const SizedBox(height: 8),
                SpeakButton(english: '${a.title}. ${a.body}', tamil: a.bodyTamil),
              ]),
            ),
          ),
      ],
    );
  }

  Widget _risk(String label, double v) {
    final c = v >= 0.6 ? kRed : (v >= 0.4 ? kOrange : kGreen);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(children: [
        Text('${(v * 100).round()}%', style: TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 16)),
        Text('Spread risk $label', style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
    );
  }
}
