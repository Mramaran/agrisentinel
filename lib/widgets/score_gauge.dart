import 'package:flutter/material.dart';
import '../core/scoring.dart';
import '../main.dart';

Color scoreColor(int score) {
  if (score >= 80) return kGreen;
  if (score >= 60) return kYellow;
  if (score >= 40) return kOrange;
  return kRed;
}

Color bandColor(PriorityBand b) => switch (b) {
      PriorityBand.normal => kGreen,
      PriorityBand.monitor => kYellow,
      PriorityBand.inspect => kOrange,
      PriorityBand.immediate => kRed,
    };

class ScoreGauge extends StatelessWidget {
  final int score;
  final double size;
  const ScoreGauge({super.key, required this.score, this.size = 72});

  @override
  Widget build(BuildContext context) {
    final c = scoreColor(score);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(value: score / 100, strokeWidth: 7, color: c, backgroundColor: c.withValues(alpha: 0.15)),
          Text('$score', style: TextStyle(fontSize: size * 0.32, fontWeight: FontWeight.bold, color: kNavy)),
        ],
      ),
    );
  }
}
