import 'package:flutter/material.dart';
import 'package:kai/models/recipe.dart';
import 'package:kai/widgets/recipes/recipe_card.dart';
import 'package:kai/widgets/recipes/week_day_picker.dart';

class WeekPlannerCatalogScreen extends StatelessWidget {
  const WeekPlannerCatalogScreen({
    super.key,
    required this.days,
    required this.currentDay,
    required this.isDayComplete,
    required this.onDateSelected,
    required this.filledCount,
    required this.totalSlots,
    required this.missingSlots,
    required this.slotLabel,
    required this.filters,
    required this.activeFilter,
    required this.onFilterSelected,
    required this.recipes,
    required this.slotForMealType,
    required this.filledSlots,
    required this.selectedRecipeIdBySlot,
    required this.onOpenDetails,
    required this.onAddForCurrentDay,
    required this.onReviewPlan,
  });

  final List<DateTime> days;
  final DateTime currentDay;
  final bool Function(DateTime) isDayComplete;
  final void Function(DateTime) onDateSelected;
  final int filledCount;
  final int totalSlots;
  final Iterable<String> missingSlots;
  final String Function(String) slotLabel;
  final List<String> filters;
  final String activeFilter;
  final void Function(String) onFilterSelected;
  final List<Recipe> recipes;
  final String Function(String) slotForMealType;
  final Set<String> filledSlots;
  final Map<String, String> selectedRecipeIdBySlot;
  final void Function(Recipe) onOpenDetails;
  final Future<void> Function(Recipe) onAddForCurrentDay;
  final VoidCallback onReviewPlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = totalSlots == 0
        ? 0.0
        : (filledCount / totalSlots).clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WeekDayPicker(
                        days: days,
                        selectedDate: currentDay,
                        isFilled: isDayComplete,
                        onDateSelected: onDateSelected,
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '$filledCount/$totalSlots slots filled',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (missingSlots.isNotEmpty)
                                Text(
                                  'Missing: ${missingSlots.map(slotLabel).join(', ')}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.black54,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: const Color(0xFFE2E8F0),
                              color: Colors.greenAccent,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 52,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    itemCount: filters.length,
                    itemBuilder: (context, index) {
                      final filter = filters[index];
                      final selected = activeFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(filter),
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          selected: selected,
                          onSelected: (_) => onFilterSelected(filter),
                          selectedColor: Colors.greenAccent,
                          labelStyle: TextStyle(
                            color: selected ? Colors.black : Colors.black87,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All recipes',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${recipes.length} total',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (recipes.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Text(
                      'No recipes available in catalog yet.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 700
                          ? 3
                          : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.6,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final recipe = recipes[index];
                      final slot = slotForMealType(recipe.mealType);
                      final selectedRecipeId = selectedRecipeIdBySlot[slot];
                      final isSelected = selectedRecipeId == recipe.recipeId;
                      final isSlotLocked =
                          filledSlots.contains(slot) && !isSelected;

                      return RecipeCard(
                        recipe: recipe,
                        onTap: () => onOpenDetails(recipe),
                        onAdd: () => onAddForCurrentDay(recipe),
                        isSelected: isSelected,
                        isLocked: isSlotLocked,
                      );
                    }, childCount: recipes.length),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onReviewPlan,
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.black,
        label: const Text('Review plan'),
        icon: const Icon(Icons.view_list),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
