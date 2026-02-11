import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kai/widgets/calorie_tank.dart';
import 'package:kai/widgets/macro_ring.dart';

class MacrosProgressCard extends StatelessWidget {
  const MacrosProgressCard({
    super.key,
    required this.progress,
    required this.totals,
    required this.targets,
  });

  final Map<String, dynamic> progress;
  final Map<String, dynamic> totals;
  final Map<String, dynamic> targets;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            const Text('Macros Progress'),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, c) {
                final screen = MediaQuery.sizeOf(context);
                final maxByWidth = c.maxWidth * 0.50;
                final maxByHeight = screen.height * 0.22;
                final ringSize = math
                    .min(maxByWidth, maxByHeight)
                    .clamp(100.0, 180.0);
                return Center(
                  child: SizedBox(
                    width: ringSize,
                    height: ringSize,
                    child: MacroRingWidget(
                      fatProgress: progress['fats'],
                      proteinProgress: progress['proteins'],
                      carbProgress: progress['carbs'],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _MacroLegend(totals: totals, targets: targets),
          ],
        ),
      ),
    );
  }
}

class CaloriesCard extends StatelessWidget {
  const CaloriesCard({
    super.key,
    required this.progress,
    required this.consumedKcal,
    required this.targetKcal,
  });

  final Map<String, dynamic> progress;
  final double consumedKcal;
  final double targetKcal;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            const Text(
              "Calories",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Target: ${targetKcal.toStringAsFixed(0)} kcal",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final side = math.min(c.maxWidth, c.maxHeight);
                  return Center(
                    child: SizedBox(
                      width: side,
                      height: side,
                      child: CalorieTankWidget(
                        consumedKcal: consumedKcal,
                        progress: progress['calories'],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroLegend extends StatelessWidget {
  const _MacroLegend({required this.totals, required this.targets});

  final Map<String, dynamic> totals;
  final Map<String, dynamic> targets;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    final items = [
      (Colors.redAccent, "Fat", totals['fats'], targets['fats']),
      (Colors.blueAccent, "Protein", totals['proteins'], targets['proteins']),
      (Colors.orangeAccent, "Carbs", totals['carbs'], targets['carbs']),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: items.map((item) {
        final (color, label, consumed, target) = item;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, color: color),
            const SizedBox(width: 6),
            Text(
              "$label: ${consumed.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} g",
              style: textStyle,
            ),
          ],
        );
      }).toList(),
    );
  }
}

class MacroRingTile extends StatelessWidget {
  const MacroRingTile({
    super.key,
    required this.label,
    required this.progress,
    required this.color,
    required this.consumed,
    required this.target,
  });

  final String label;
  final double progress;
  final Color color;
  final double consumed;
  final double target;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 12,
                      color: color,
                      backgroundColor: color.withOpacity(0.15),
                    ),
                  ),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class CaloriesTankTile extends StatelessWidget {
  const CaloriesTankTile({
    super.key,
    required this.progress,
    required this.consumedKcal,
    required this.targetKcal,
  });

  final double progress;
  final double consumedKcal;
  final double targetKcal;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Calories',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 120,
              height: 120,
              child: CalorieTankWidget(
                consumedKcal: consumedKcal,
                progress: progress,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
