import 'package:flutter/material.dart';
import 'package:kai/models/recipe.dart';
import 'package:kai/widgets/recipes/review_recipe_tile.dart';

class ConfirmedPlanView extends StatelessWidget {
  const ConfirmedPlanView({
    super.key,
    required this.days,
    required this.weeklySelections,
    required this.weekdayLabel,
    required this.slotLabel,
    required this.slots,
    required this.groceryList,
    required this.groceryStatus,
    required this.onShowGrocery,
    required this.onEditPlan,
    required this.onOpenRecipe,
    required this.recipeFromSelection,
    required this.dateId,
  });

  final List<DateTime> days;
  final Map<String, Map<String, Map<String, dynamic>>> weeklySelections;
  final String Function(DateTime date) weekdayLabel;
  final String Function(String slot) slotLabel;
  final List<String> slots;
  final Map<String, dynamic>? groceryList;
  final String? groceryStatus;
  final Future<void> Function() onShowGrocery;
  final VoidCallback onEditPlan;
  final void Function(Recipe recipe, DateTime day) onOpenRecipe;
  final Recipe Function(Map<String, dynamic> data) recipeFromSelection;
  final String Function(DateTime date) dateId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your weekly plan',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onEditPlan,
                    icon: const Icon(Icons.edit, color: Colors.black54),
                    tooltip: 'Edit week',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'All selected meals for this week.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  if (groceryStatus == 'generating')
                    const Text(
                      'Generating list…',
                      style: TextStyle(color: Colors.black54),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: days.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final dateKey = dateId(day);
                    final meals = weeklySelections[dateKey] ?? {};
                    final orderedMeals = slots
                        .where(meals.containsKey)
                        .map((slot) => MapEntry(slot, meals[slot]!))
                        .toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weekdayLabel(day),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        if (orderedMeals.isEmpty)
                          const Text(
                            'No recipes yet.',
                            style: TextStyle(color: Colors.black54),
                          )
                        else
                          Column(
                            children: orderedMeals.map((entry) {
                              final recipe = recipeFromSelection(entry.value);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ReviewRecipeTile(
                                  recipe: recipe,
                                  slotLabel: slotLabel(entry.key),
                                  onTap: () => onOpenRecipe(recipe, day),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onShowGrocery,
        backgroundColor: Colors.greenAccent,
        // label: const Text('Grocery list'),
        child: const Icon(Icons.shopping_bag),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
