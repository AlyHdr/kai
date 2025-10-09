import 'package:flutter/material.dart';

class CalorieTankWidget extends StatelessWidget {
  final double progress; // value from 0.0 to 1.0
  final double consumedKcal;

  const CalorieTankWidget({
    super.key,
    required this.consumedKcal,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    // Scale the tank to fit available space while preserving aspect ratio.
    return LayoutBuilder(
      builder: (context, c) {
        const aspect = 130 / 70; // original painter aspect (h / w)
        final maxW = c.maxWidth.isFinite ? c.maxWidth : 70.0;
        final maxH = c.maxHeight.isFinite ? c.maxHeight : 130.0;

        // Fit the tank inside the available box while keeping aspect.
        double width = maxW;
        double height = width * aspect;
        if (height > maxH) {
          height = maxH;
          width = height / aspect;
        }

        return SizedBox(
          width: maxW,
          height: maxH,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: width,
                height: height,
                child: CustomPaint(
                  size: Size(width, height),
                  painter: CalorieTankPainter(progress: progress),
                ),
              ),
              Positioned(
                bottom: 8,
                child: Text(
                  '${consumedKcal.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
