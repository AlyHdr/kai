import 'package:flutter/material.dart';

class CalorieTankWidget extends StatelessWidget {
  final double progress; // value from 0.0 to 1.0

  const CalorieTankWidget({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(60, 150),
          painter: CalorieTankPainter(progress: progress),
        ),
        Positioned(
          bottom: 8,
          child: Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class CalorieTankPainter extends CustomPainter {
  final double progress;

  CalorieTankPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final tankPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final fillPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final fillHeight = size.height * progress;
    final fillRect = Rect.fromLTWH(
      0,
      size.height - fillHeight,
      size.width,
      fillHeight,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      tankPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(fillRect, const Radius.circular(12)),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
