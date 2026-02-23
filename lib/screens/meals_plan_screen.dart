import 'package:flutter/material.dart';
import 'package:kai/models/recipe.dart';
import 'package:kai/screens/main_screen.dart';
import 'package:kai/screens/recipe_detail_screen.dart';
import 'package:kai/screens/week_planner_catalog_screen.dart';
import 'package:kai/services/recipe_catalog_service.dart';
import 'package:kai/services/weekly_plan_service.dart';
import 'package:kai/widgets/recipes/confirmed_plan_view.dart';
import 'package:kai/widgets/recipes/grocery_list_sheet.dart';
import 'package:kai/widgets/recipes/review_recipe_tile.dart';

enum MealPlanViewMode { planner, myWeek }

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key, this.mode = MealPlanViewMode.planner});

  final MealPlanViewMode mode;

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final _weeklyPlanService = WeeklyPlanService();
  final _recipeCatalogService = RecipeCatalogService();
  String _activeFilter = 'All';
  late final List<DateTime> _days;
  int _currentDayIndex = 0;
  final Map<String, Set<String>> _filledSlotsByDate = {};
  final Map<String, Map<String, Map<String, dynamic>>> _weeklySelections = {};
  List<Recipe> _catalogRecipes = const [];
  bool _isPlanConfirmed = false;
  Map<String, dynamic>? _groceryList;
  String? _groceryStatus;
  bool _isLoadingPlan = true;
  bool _isLoadingCatalog = true;

  static const List<String> _filters = [
    'All',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'High Protein',
    'Vegetarian',
    'Low Carb',
    'Quick',
  ];

  static const List<String> _slots = ['breakfast', 'lunch', 'dinner', 'snack'];
  static const List<String> _requiredSlots = ['breakfast', 'lunch', 'dinner'];

  List<Recipe> _filteredRecipes() {
    return _catalogRecipes.where((recipe) {
      final matchesFilter =
          _activeFilter == 'All' ||
          recipe.mealType == _activeFilter ||
          recipe.tags.contains(_activeFilter);
      return matchesFilter;
    }).toList();
  }

  String _dateId(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  DateTime _weekStart(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfThisWeek = _weekStart(today);
    _days = List<DateTime>.generate(
      7,
      (i) => startOfThisWeek.add(Duration(days: i)),
    );
    _loadCatalogRecipes();
    _loadWeeklySelections(showLoading: true);
  }

  Future<void> _loadCatalogRecipes() async {
    try {
      final recipes = await _recipeCatalogService.fetchRecipes();
      if (!mounted) return;
      setState(() {
        _catalogRecipes = recipes;
        _isLoadingCatalog = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCatalog = false);
    }
  }

  String _weekdayLabel(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday, $month ${date.day}';
  }

  String _slotForMealType(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'breakfast';
      case 'lunch':
        return 'lunch';
      case 'snack':
        return 'snack';
      case 'dinner':
        return 'dinner';
      default:
        return 'dinner';
    }
  }

  String _slotLabel(String slot) {
    switch (slot) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      case 'snack':
        return 'Snack';
      default:
        return slot;
    }
  }

  DateTime get _currentDay => _days[_currentDayIndex];

  Future<void> _loadWeeklySelections({bool showLoading = false}) async {
    final startedAt = DateTime.now();
    if (showLoading) {
      setState(() => _isLoadingPlan = true);
    }
    try {
      final plan = await _weeklyPlanService.loadWeeklyPlan(
        _weekStart(_days.first),
      );
      final elapsed = DateTime.now().difference(startedAt);
      if (showLoading && elapsed.inMilliseconds < 250) {
        await Future.delayed(
          Duration(milliseconds: 250 - elapsed.inMilliseconds),
        );
      }
      if (!mounted) return;
      setState(() {
        _weeklySelections
          ..clear()
          ..addAll(plan.selections);
        _filledSlotsByDate
          ..clear()
          ..addAll(plan.filledSlotsByDate);
        _isPlanConfirmed = plan.isConfirmed;
        _groceryList = plan.groceryList;
        _groceryStatus = plan.groceryStatus;
        _isLoadingPlan = false;
      });
    } catch (_) {
      // Ignore load errors; user can still proceed with picks.
      if (!mounted) return;
      setState(() => _isLoadingPlan = false);
    }
  }

  Future<void> _addToWeeklyPlan(Recipe recipe, DateTime day) async {
    final dateKey = _dateId(day);
    final slot = _slotForMealType(recipe.mealType);
    try {
      await _weeklyPlanService.addToWeeklyPlan(recipe, day);
    } catch (error) {
      if (error is SlotAlreadyFilledException) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_slotLabel(slot)} already selected for ${_weekdayLabel(day)}.',
            ),
          ),
        );
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in first.')));
      return;
    }

    if (!mounted) return;
    setState(() {
      final slots = _filledSlotsByDate.putIfAbsent(dateKey, () => <String>{});
      slots.add(slot);
      final daySelections = _weeklySelections.putIfAbsent(
        dateKey,
        () => <String, Map<String, dynamic>>{},
      );
      daySelections[slot] = recipe.toMap();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to ${_weekdayLabel(day)} · ${recipe.mealType}'),
      ),
    );
  }

  Future<void> _removeFromWeeklyPlan(DateTime day, String slot) async {
    try {
      await _weeklyPlanService.removeFromWeeklyPlan(day, slot);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: const Text('Please sign in first.')));
      return;
    }

    if (!mounted) return;
    final dateKey = _dateId(day);
    setState(() {
      final slots = _filledSlotsByDate[dateKey];
      slots?.remove(slot);
      if (slots != null && slots.isEmpty) {
        _filledSlotsByDate.remove(dateKey);
      }
      final daySelections = _weeklySelections[dateKey];
      daySelections?.remove(slot);
      if (daySelections != null && daySelections.isEmpty) {
        _weeklySelections.remove(dateKey);
      }
    });
  }

  bool _isDayComplete(DateTime date) {
    final slots = _filledSlotsByDate[_dateId(date)];
    if (slots == null) return false;
    return _requiredSlots.every(slots.contains);
  }

  Future<void> _addForCurrentDay(Recipe recipe) async {
    await _addToWeeklyPlan(recipe, _currentDay);
  }

  Recipe _recipeFromSelection(Map<String, dynamic> data) {
    final calories = (data['calories'] as num?)?.round() ?? 0;
    final protein = (data['protein'] as num?)?.round() ?? 0;
    final fats = (data['fats'] as num?)?.round() ?? 0;
    final carbs = (data['carbs'] as num?)?.round() ?? 0;
    final timeMinutes = (data['timeMinutes'] as num?)?.round() ?? 0;
    return Recipe(
      recipeId: data['recipeId']?.toString() ?? data['name']?.toString() ?? 'recipe',
      name: data['name']?.toString() ?? 'Recipe',
      mealType: data['mealType']?.toString() ?? 'Meal',
      calories: calories,
      protein: protein,
      fats: fats,
      carbs: carbs,
      timeMinutes: timeMinutes,
      tags: List<String>.from(data['tags'] ?? const <String>[]),
      imageUrl: data['imageUrl']?.toString() ?? data['image']?.toString() ?? '',
      ingredientsList: data['ingredientsList'] is List
          ? List<String>.from(data['ingredientsList'])
          : data['ingredients_list'] is List
          ? List<String>.from(data['ingredients_list'])
          : const <String>[],
      instructionsList: data['instructionsList'] is List
          ? List<String>.from(data['instructionsList'])
          : data['instructions_list'] is List
          ? List<String>.from(data['instructions_list'])
          : const <String>[],
      palette: const [Color(0xFF0F172A), Color(0xFFE2E8F0)],
    );
  }

  void _openDetailsForDay(Recipe recipe, DateTime day) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(
          recipe: recipe,
          onAdd: (_) => _addToWeeklyPlan(recipe, day),
        ),
      ),
    );
  }

  void _showReviewSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Weekly picks',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _days.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final day = _days[index];
                          final dateKey = _dateId(day);
                          final meals = _weeklySelections[dateKey] ?? {};
                          final orderedMeals = _slots
                              .where(meals.containsKey)
                              .map((slot) => MapEntry(slot, meals[slot]!))
                              .toList();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _weekdayLabel(day),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
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
                                      final recipe = _recipeFromSelection(
                                        entry.value,
                                      );
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: ReviewRecipeTile(
                                          recipe: recipe,
                                          slotLabel: _slotLabel(entry.key),
                                          onTap: () =>
                                              _openDetailsForDay(recipe, day),
                                          onRemove: () async {
                                            await _removeFromWeeklyPlan(
                                              day,
                                              entry.key,
                                            );
                                            if (context.mounted) {
                                              setModalState(() {});
                                            }
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _confirmWeeklyPlan,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                backgroundColor: Colors.greenAccent,
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Text('Confirm week'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Close'),
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
      },
    );
  }

  Future<void> _confirmWeeklyPlan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm weekly plan'),
        backgroundColor: Colors.white,
        content: const Text('You can still edit your plan later. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _weeklyPlanService.confirmWeeklyPlan(_weekStart(_days.first));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in first.')));
      return;
    }

    if (!mounted) return;
    setState(() {
      _isPlanConfirmed = true;
    });
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Weekly plan confirmed.')));
  }

  Future<void> _showGrocerySheet() async {
    if (_groceryStatus == 'generating') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grocery list is being generated...')),
      );
      return;
    }

    final list = _groceryList;
    if (list == null || list['items'] == null || _groceryStatus != 'ready') {
      setState(() => _groceryStatus = 'generating');
      try {
        await _weeklyPlanService.generateGroceryList(_weekStart(_days.first));
        if (!mounted) return;
        await _loadWeeklySelections();
      } catch (_) {
        if (!mounted) return;
        setState(() => _groceryStatus = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate grocery list.')),
        );
        return;
      }
    }

    final readyList = _groceryList;
    if (readyList == null || readyList['items'] == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grocery list is not ready yet.')),
      );
      return;
    }

    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => GroceryListSheet(groceryList: readyList),
    );
  }

  Future<void> _editWeeklyPlan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit weekly plan'),
        backgroundColor: Colors.white,
        content: const Text(
          'This will unlock your plan so you can make changes. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
            ),
            child: const Text('Edit week'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await _weeklyPlanService.unconfirmWeeklyPlan(_weekStart(_days.first));
      if (!mounted) return;
      setState(() {
        _isPlanConfirmed = false;
        _groceryList = null;
        _groceryStatus = null;
      });
      if (widget.mode == MealPlanViewMode.myWeek) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MainScreen(initialIndex: 1),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan unlocked for editing.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in first.')));
    }
  }

  Widget _buildConfirmedPlan(BuildContext context) {
    return ConfirmedPlanView(
      days: _days,
      weeklySelections: _weeklySelections,
      weekdayLabel: _weekdayLabel,
      slotLabel: _slotLabel,
      slots: _slots,
      groceryList: _groceryList,
      groceryStatus: _groceryStatus,
      onShowGrocery: _showGrocerySheet,
      onEditPlan: _editWeeklyPlan,
      onOpenRecipe: _openDetailsForDay,
      recipeFromSelection: _recipeFromSelection,
      dateId: _dateId,
    );
  }

  void _openDetails(Recipe recipe) {
    _openDetailsForDay(recipe, _currentDay);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPlan || _isLoadingCatalog) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (widget.mode == MealPlanViewMode.myWeek) {
      if (_isPlanConfirmed) {
        return _buildConfirmedPlan(context);
      }
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.event_note, size: 44, color: Colors.black38),
                const SizedBox(height: 12),
                const Text(
                  'No confirmed week yet.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Build and confirm your week in Planner to see it here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const MainScreen(initialIndex: 1),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Go to Planner'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // Planner tab remains editable/catalog-focused even after confirmation.
    // Confirmed plans are shown in the "My Week" tab.
    final recipes = _filteredRecipes();
    final currentDateKey = _dateId(_currentDay);
    final filledSlots = _filledSlotsByDate[currentDateKey] ?? <String>{};
    final currentDaySelections =
        _weeklySelections[currentDateKey] ?? <String, Map<String, dynamic>>{};
    final selectedRecipeIdBySlot = <String, String>{
      for (final entry in currentDaySelections.entries)
        entry.key: (entry.value['recipeId'] ?? entry.value['name'] ?? '').toString(),
    };
    final filledCount = filledSlots.length;
    final totalSlots = _slots.length;
    final missingSlots = _slots.where((slot) => !filledSlots.contains(slot));

    return WeekPlannerCatalogScreen(
      days: _days,
      currentDay: _currentDay,
      isDayComplete: _isDayComplete,
      onDateSelected: (date) {
        final index = _days.indexWhere((d) => _dateId(d) == _dateId(date));
        if (index != -1) {
          setState(() => _currentDayIndex = index);
        }
      },
      filledCount: filledCount,
      totalSlots: totalSlots,
      missingSlots: missingSlots,
      slotLabel: _slotLabel,
      filters: _filters,
      activeFilter: _activeFilter,
      onFilterSelected: (filter) => setState(() => _activeFilter = filter),
      recipes: recipes,
      slotForMealType: _slotForMealType,
      filledSlots: filledSlots,
      selectedRecipeIdBySlot: selectedRecipeIdBySlot,
      onOpenDetails: _openDetails,
      onAddForCurrentDay: _addForCurrentDay,
      onReviewPlan: _showReviewSheet,
    );
  }
}
