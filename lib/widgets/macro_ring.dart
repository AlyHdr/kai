import 'dart:math' as math;

import 'package:flutter/material.dart';

class MacroRingWidget extends StatelessWidget {
  final double fatProgress;
  final double proteinProgress;
  final double carbProgress;

  const MacroRingWidget({
    super.key,
    required this.fatProgress,
    required this.proteinProgress,
    required this.carbProgress,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(170, 170),
      painter: MacroRingPainter(
        fatProgress: fatProgress,
        proteinProgress: proteinProgress,
        carbProgress: carbProgress,
      ),
    );
  }
}

class MacroRingPainter extends CustomPainter {
  final double fatProgress;
  final double proteinProgress;
  final double carbProgress;

  MacroRingPainter({
    required this.fatProgress,
    required this.proteinProgress,
    required this.carbProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final thickness = 20.0;
    final sweepSpan = math.pi * 1.5; // 270 degrees
    final baseStartAngle = -5 * math.pi / 4; // -30 degrees for bottom gap

    final List<Color> colors = [
      Colors.orangeAccent, // Carbs
      Colors.blueAccent, // Protein
      Colors.redAccent, // Fat
    ];

    final List<double> progresses = [
      carbProgress,
      proteinProgress,
      fatProgress,
    ];

    for (int i = 0; i < 3; i++) {
      final radius = size.width / 2 - i * (thickness + 10);
      final rect = Rect.fromCircle(center: center, radius: radius);
      final startAngle = baseStartAngle;
      final sweepAngle = progresses[i] * sweepSpan;

      final backgroundPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..color = colors[i].withOpacity(0.15)
        ..strokeCap = StrokeCap.round;

      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..color = colors[i]
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepSpan, false, backgroundPaint);
      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
