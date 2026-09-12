import 'package:flutter/material.dart';
import '../core/scoring.dart';
import '../main.dart';

class ReliabilityChip extends StatelessWidget {
  final Reliability reliability;
  final bool anomaly;
  const ReliabilityChip({super.key, required this.reliability, this.anomaly = false});

  @override
  Widget build(BuildContext context) {
    final (label, color) = anomaly
        ? ('UNKNOWN ANOMALY', kRed)
        : switch (reliability) {
            Reliability.high => ('RELIABILITY HIGH', kGreen),
            Reliability.medium => ('RELIABILITY MEDIUM', kOrange),
            Reliability.low => ('RELIABILITY LOW', kRed),
          };
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      backgroundColor: color,
      side: BorderSide.none,
    );
  }
}
