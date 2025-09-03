import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kai/services/macros_service.dart';
import 'package:kai/services/users_service.dart';
import 'package:kai/widgets/calorie_tank.dart';
import 'package:kai/widgets/macro_ring.dart';
import 'package:kai/widgets/week_progress.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime selectedDate = DateTime.now();
  late Future<Map<String, dynamic>?> dashboardData;

  @override
  void initState() {
    super.initState();
    dashboardData = UsersService().getDashboardData(selectedDate);
  }

  void _onDaySelected(DateTime date) {
    setState(() {
      selectedDate = date;
      dashboardData = UsersService().getDashboardData(selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: dashboardData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("No macros found."),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Trigger macro generation
                    },
                    child: const Text("Generate Macros"),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final progress = data['progress'];
        final mealsMap = data['meals'] as Map<String, dynamic>;

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  WeekProgressBar(
                    selectedDate: selectedDate,
                    onDateSelected: _onDaySelected,
                  ),
                  const SizedBox(height: 24),

                  // Macros progress card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Macros Progress',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Ring size capped by width and screen height
                          LayoutBuilder(
                            builder: (context, c) {
                              final screen = MediaQuery.sizeOf(context);
                              final maxByWidth = c.maxWidth * 0.55;
                              final maxByHeight = screen.height * 0.25;
                              final ringSize = math
                                  .min(maxByWidth, maxByHeight)
                                  .clamp(140.0, 220.0);
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

                          const SizedBox(height: 12),
                          _MacroLegend(progress: progress),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bottom area: two columns side-by-side
                  Expanded(
                    child: Row(
                      children: [
                        // Left: Calories (single Card inside the widget)
                        Expanded(child: _CaloriesCard(progress: progress)),
                        const SizedBox(width: 16),
                        // Right: Meals (single Card inside the widget)
                        Expanded(child: _MealsCard(mealsMap: mealsMap)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- Helpers below ---

class _MacroLegend extends StatelessWidget {
  const _MacroLegend({required this.progress});
  final Map<String, dynamic> progress;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Colors.redAccent, "Fat", progress['fats']),
      (Colors.blueAccent, "Protein", progress['proteins']),
      (Colors.orangeAccent, "Carbs", progress['carbs']),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: items.map((item) {
        final (color, label, value) = item;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, color: color),
            const SizedBox(width: 6),
            Text("$label: ${(value * 100).toStringAsFixed(0)}%"),
          ],
        );
      }).toList(),
    );
  }
}

class _CaloriesCard extends StatelessWidget {
  const _CaloriesCard({required this.progress});
  final Map<String, dynamic> progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        // Independent scroll so this column never overflows
        child: SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, c) {
              // Estimate vertical budget inside the card if it had constraints,
              // but since we scroll, we mainly need a sensible size cap.
              final side = math.min(c.maxWidth, 220.0).clamp(140.0, 220.0);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Calories Consumed",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: side,
                      height: side,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: side,
                          height: side,
                          child: CalorieTankWidget(
                            progress: progress['calories'],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MealsCard extends StatelessWidget {
  const _MealsCard({required this.mealsMap});
  final Map<String, dynamic> mealsMap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's Meals",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: mealsMap.entries.map((entry) {
                  final category = entry.key; // breakfast/lunch/dinner/snack
                  final meal = entry.value as Map<String, dynamic>?;
                  final name = meal?['name'] as String? ?? 'Not selected';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          category[0].toUpperCase() + category.substring(1),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
