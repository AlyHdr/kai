import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kai/services/users_service.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  late final String _uid;
  late final String _dateId; // yyyy-MM-dd
  bool _generationTriggered = false;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user == null) {
      // In a real app, route to login or show an error.
      throw Exception('User must be signed in');
    }
    _uid = user.uid;
    final selectedDate = DateTime.now();
    _dateId =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
  }

  DocumentReference<Map<String, dynamic>> get _planDoc =>
      _firestore.collection('users').doc(_uid).collection('plans').doc(_dateId);

  DocumentReference<Map<String, dynamic>> get _intakeDoc => _firestore
      .collection('users')
      .doc(_uid)
      .collection('intake')
      .doc(_dateId);

  Future<void> _ensurePlanExistsOnce() async {
    if (_generationTriggered) return; // prevent multiple calls
    _generationTriggered = true;
    try {
      final snap = await _planDoc.get();
      if (!snap.exists) {
        FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);

        var userData = await UsersService().getUserData();

        final result = await FirebaseFunctions.instance
            .httpsCallable('generate_meal_plan')
            .call(userData);

        // Save the generated plan to Firestore
        if (result.data != null && result.data is Map<String, dynamic>) {
          await _planDoc.set(result.data as Map<String, dynamic>);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to generate plan: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _planDoc.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Also proactively ensure the plan exists.
            _ensurePlanExistsOnce();
            return const _CenteredProgress('Loading your plan...');
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: 'Could not load plan',
              onRetry: () => setState(() {}),
            );
          }

          final doc = snapshot.data;

          if (doc == null || !doc.exists) {
            // Trigger generation once; show a generating state.
            _ensurePlanExistsOnce();
            return const _CenteredProgress('Generating your plan...');
          }

          final data = doc.data()!;
          final meals = (data as Map<String, dynamic>?) ?? {};
          final selected = (data['selected'] as Map<String, dynamic>?) ?? {};

          return RefreshIndicator(
            onRefresh: () async {
              await _planDoc.get(GetOptions(source: Source.server));
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TotalsCard(intakeDoc: _intakeDoc),
                const SizedBox(height: 16),
                _MealSection(
                  title: 'Breakfast',
                  keyName: 'breakfast',
                  options: (meals['breakfast'] as List<dynamic>? ?? [])
                      .map((e) => e as Map<String, dynamic>)
                      .toList(),
                  selected: selected['breakfast'],
                  onPick: (meal) => _selectMeal('breakfast', meal),
                ),
                const SizedBox(height: 16),
                _MealSection(
                  title: 'Lunch',
                  keyName: 'lunch',
                  options: (meals['lunch'] as List<dynamic>? ?? [])
                      .map((e) => e as Map<String, dynamic>)
                      .toList(),
                  selected: selected['lunch'],
                  onPick: (meal) => _selectMeal('lunch', meal),
                ),
                const SizedBox(height: 16),
                _MealSection(
                  title: 'Dinner',
                  keyName: 'dinner',
                  options: (meals['dinner'] as List<dynamic>? ?? [])
                      .map((e) => e as Map<String, dynamic>)
                      .toList(),
                  selected: selected['dinner'],
                  onPick: (meal) => _selectMeal('dinner', meal),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectMeal(String mealKey, Map<String, dynamic> meal) async {
    try {
      await _firestore.runTransaction((tx) async {
        // ---- READS first ----
        final planSnap = await tx.get(_planDoc);
        final intakeSnap = await tx.get(_intakeDoc);

        if (!planSnap.exists) throw Exception('Plan document missing');

        // ---- Process selected ----
        final plan = planSnap.data()!;
        final selected = Map<String, dynamic>.from(plan['selected'] ?? {});
        selected[mealKey] = meal;

        // ---- Process intake ----
        Map<String, dynamic> mealsMap = intakeSnap.exists
            ? Map<String, dynamic>.from(intakeSnap.data()!['meals'] ?? {})
            : {};
        mealsMap[mealKey] = meal;
        final totals = _computeTotals(mealsMap);

        // ---- WRITES after all reads ----
        tx.update(_planDoc, {'selected': selected});
        if (intakeSnap.exists) {
          tx.update(_intakeDoc, {'meals': mealsMap, 'totals': totals});
        } else {
          tx.set(_intakeDoc, {
            'meals': mealsMap,
            'totals': totals,
            'date': _dateId,
          });
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selected ${meal['name'] ?? 'meal'} for ${_titleFor(mealKey)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to select meal: $e')));
      }
    }
  }

  String _titleFor(String mealKey) {
    switch (mealKey) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      default:
        return mealKey;
    }
  }

  Map<String, num> _computeTotals(Map<String, dynamic> mealsMap) {
    num calories = 0, fats = 0, carbs = 0, protein = 0;
    for (final v in mealsMap.values) {
      if (v is Map<String, dynamic>) {
        final macros = (v['macros'] as Map<String, dynamic>?) ?? {};
        calories += (macros['calories'] ?? v['calories'] ?? 0) as num;
        fats += (macros['fats'] ?? 0) as num;
        carbs += (macros['carbs'] ?? 0) as num;
        protein += (macros['protein'] ?? 0) as num;
      }
    }
    return {
      'calories': calories,
      'fats': fats,
      'carbs': carbs,
      'protein': protein,
    };
  }
}

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.title,
    required this.keyName,
    required this.options,
    required this.selected,
    required this.onPick,
  });

  final String title;
  final String keyName;
  final List<Map<String, dynamic>> options;
  final dynamic selected; // Map or null
  final void Function(Map<String, dynamic> meal) onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedMap = selected is Map<String, dynamic>
        ? selected as Map<String, dynamic>
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                if (selectedMap != null)
                  Chip(
                    label: Text(
                      '${(selectedMap['macros']?['calories'] ?? selectedMap['calories'] ?? '-')} kcal',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Show current selection
            if (selectedMap != null)
              _SelectedMealTile(meal: selectedMap)
            else
              Text('No meal selected', style: theme.textTheme.bodySmall),

            const SizedBox(height: 8),

            // Expandable for options
            if (options.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  selectedMap != null ? "Change selection" : "Pick one",
                  style: theme.textTheme.labelLarge,
                ),
                children: options
                    .map((m) => _OptionTile(meal: m, onPick: onPick))
                    .toList(),
              )
            else
              const Text('No options available yet.'),
          ],
        ),
      ),
    );
  }
}

class _SelectedMealTile extends StatelessWidget {
  const _SelectedMealTile({required this.meal});
  final Map<String, dynamic> meal;

  @override
  Widget build(BuildContext context) {
    final name = meal['name'] ?? 'Meal';
    final macros = (meal['macros'] as Map<String, dynamic>?) ?? {};
    final calories = macros['calories'] ?? meal['calories'] ?? '-';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text('$calories kcal'),
      trailing: _DetailsButton(meal: meal),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.meal, required this.onPick});
  final Map<String, dynamic> meal;
  final void Function(Map<String, dynamic>) onPick;

  @override
  Widget build(BuildContext context) {
    final name = meal['name'] ?? 'Meal';
    final macros = (meal['macros'] as Map<String, dynamic>?) ?? {};
    final calories = macros['calories'] ?? meal['calories'] ?? '-';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text('$calories kcal'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DetailsButton(meal: meal),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => onPick(meal),
            child: const Text('Pick'),
          ),
        ],
      ),
    );
  }
}

class _DetailsButton extends StatelessWidget {
  const _DetailsButton({required this.meal});
  final Map<String, dynamic> meal;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (context) {
            final macros = (meal['macros'] as Map<String, dynamic>?) ?? {};
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal['name'] ?? 'Meal',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(meal['description'] ?? 'No description'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: [
                      Chip(
                        label: Text(
                          'Cal: ${macros['calories'] ?? meal['calories'] ?? '-'}',
                        ),
                      ),
                      Chip(label: Text('P: ${macros['protein'] ?? '-'}g')),
                      Chip(label: Text('C: ${macros['carbs'] ?? '-'}g')),
                      Chip(label: Text('F: ${macros['fats'] ?? '-'}g')),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
      child: const Text('Details'),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.intakeDoc});
  final DocumentReference<Map<String, dynamic>> intakeDoc;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: intakeDoc.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data!.data()!;
        final totals = (data['totals'] as Map<String, dynamic>?) ?? {};
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Kpi(label: 'Calories', value: '${totals['calories'] ?? 0}'),
                _Kpi(label: 'Protein', value: '${totals['protein'] ?? 0}g'),
                _Kpi(label: 'Carbs', value: '${totals['carbs'] ?? 0}g'),
                _Kpi(label: 'Fats', value: '${totals['fats'] ?? 0}g'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.labelMedium),
      ],
    );
  }
}

class _CenteredProgress extends StatelessWidget {
  const _CenteredProgress(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(message),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
