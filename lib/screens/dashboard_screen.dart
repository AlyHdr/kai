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
        print("Dashboard Data: $data");

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                WeekProgressBar(
                  selectedDate: selectedDate,
                  onDateSelected: _onDaySelected,
                ),
                const SizedBox(height: 24),

                Card(
                  // Macros progress ring
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
                        MacroRingWidget(
                          fatProgress: progress['fats'],
                          proteinProgress: progress['proteins'],
                          carbProgress: progress['carbs'],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Fat: ${(progress['fats'] * 100).toStringAsFixed(0)}%",
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  color: Colors.blueAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Protein: ${(progress['proteins'] * 100).toStringAsFixed(0)}%",
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  color: Colors.orangeAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Carbs: ${(progress['carbs'] * 100).toStringAsFixed(0)}%",
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    children: [
                      // Calories consumed
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Calories Consumed",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                CalorieTankWidget(
                                  progress: 1.0 - progress['calories'],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Today's meals
                      Expanded(
                        child: Card(
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
                                // scrollable list to prevent overflow
                                Expanded(
                                  child: ListView(
                                    children: mealsMap.entries.map((entry) {
                                      final category = entry
                                          .key; // breakfast/lunch/dinner/snack
                                      final meal =
                                          entry.value as Map<String, dynamic>?;
                                      final name =
                                          meal?['name'] as String? ??
                                          'Not selected';
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              category[0].toUpperCase() +
                                                  category.substring(1),
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
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
