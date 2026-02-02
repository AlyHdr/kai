import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kai/services/users_service.dart';
import 'package:kai/services/macros_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kai/widgets/calorie_tank.dart';
import 'package:kai/widgets/macro_ring.dart';
import 'package:kai/widgets/week_progress.dart';
import 'package:kai/screens/main_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime selectedDate = DateTime.now();
  late Future<Map<String, dynamic>?> dashboardData;
  bool _mealPromptShownForDate = false;
  bool _macrosPromptShown = false;
  bool _retryScheduled = false;
  bool _firstNoDataObserved = false;
  bool _weeklyPlanPromptShown = false;

  @override
  void initState() {
    super.initState();
    dashboardData = UsersService().getDashboardData(selectedDate);
  }

  void _onDaySelected(DateTime date) {
    setState(() {
      selectedDate = date;
      dashboardData = UsersService().getDashboardData(selectedDate);
      _mealPromptShownForDate = false; // reset prompt for newly selected day
    });
  }

  void _maybePromptForWeeklyPlan() {
    if (_weeklyPlanPromptShown) return;
    _weeklyPlanPromptShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final hasPlan = await UsersService().hasWeeklyPlanForWeek(selectedDate);
      if (!mounted || hasPlan) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Plan your week'),
          content: const Text(
            "You haven't picked your meals for this week yet. Go to the Planner to build your week now?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Not now'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Go to Planner'),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const MainScreen(initialIndex: 1),
                  ),
                );
              },
            ),
          ],
        ),
      );
    });
  }

  void _maybePromptGenerateMacros() {
    if (_macrosPromptShown) return;

    // First time we detect missing macros, schedule a quick re-fetch instead of prompting.
    if (!_firstNoDataObserved) {
      _firstNoDataObserved = true;
      if (!_retryScheduled) {
        _retryScheduled = true;
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() {
            dashboardData = UsersService().getDashboardData(selectedDate);
            _retryScheduled = false;
          });
        });
      }
      return;
    }

    _macrosPromptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Generate your targets?'),
          content: const Text(
            'I could not find your daily targets. Let me generate them now to unlock your dashboard?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Not now'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  final data = await UsersService().getUserData();
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (data == null || uid == null) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Missing user data.')),
                    );
                    return;
                  }

                  await MacrosService().generateMacrosFromUserData(data, uid);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Macros generated.')),
                  );
                  setState(() {
                    dashboardData = UsersService().getDashboardData(
                      selectedDate,
                    );
                  });
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to generate macros: $e')),
                  );
                }
              },
              child: const Text('Generate now'),
            ),
          ],
        ),
      );
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
          _maybePromptGenerateMacros();
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Preparing your dashboard…'),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final progress = data['progress'];
        final mealsMap = data['meals'] as Map<String, dynamic>;
        _maybePromptForWeeklyPlan();
        final macros = data['macros'] as Map<String, dynamic>; // daily targets
        final totals = data['totals'] as Map<String, dynamic>; // consumed today

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
                  const SizedBox(height: 14),

                  // Macros progress card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      // Macros progress card
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
                          _MacroLegend(
                            totals: totals, // NEW
                            targets: macros, // NEW
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Bottom area: two columns side-by-side
                  Expanded(
                    child: Row(
                      children: [
                        // Left: Calories (single Card inside the widget)
                        // Calories card on the left
                        Expanded(
                          child: _CaloriesCard(
                            progress: progress,
                            consumedKcal: (totals['calories'] ?? 0)
                                .toDouble(), // NEW
                            targetKcal: (macros['calories'] ?? 0).toDouble(),
                          ),
                        ),

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
  const _MacroLegend({required this.totals, required this.targets});

  final Map<String, dynamic> totals; // from data['totals']
  final Map<String, dynamic> targets; // from data['macros']

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

class _CaloriesCard extends StatelessWidget {
  const _CaloriesCard({
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

class _MealsCard extends StatelessWidget {
  const _MealsCard({required this.mealsMap});
  final Map<String, dynamic> mealsMap;

  @override
  Widget build(BuildContext context) {
    if (mealsMap.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text(
                "No meals selected yet",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Planned meals for this day will appear here.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Planned meals",
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
