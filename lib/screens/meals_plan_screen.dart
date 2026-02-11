import 'package:flutter/material.dart';
import 'package:kai/models/recipe.dart';
import 'package:kai/screens/recipe_detail_screen.dart';
import 'package:kai/services/weekly_plan_service.dart';
import 'package:kai/widgets/recipes/confirmed_plan_view.dart';
import 'package:kai/widgets/recipes/grocery_list_sheet.dart';
import 'package:kai/widgets/recipes/recipe_card.dart';
import 'package:kai/widgets/recipes/review_recipe_tile.dart';
import 'package:kai/widgets/recipes/week_day_picker.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final _weeklyPlanService = WeeklyPlanService();
  String _activeFilter = 'All';
  late final List<DateTime> _days;
  int _currentDayIndex = 0;
  final Map<String, Set<String>> _filledSlotsByDate = {};
  final Map<String, Map<String, Map<String, dynamic>>> _weeklySelections = {};
  bool _isPlanConfirmed = false;
  Map<String, dynamic>? _groceryList;
  String? _groceryStatus;
  bool _isLoadingPlan = true;

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

  final List<Recipe> _recipes = const [
    Recipe(
      name: 'Citrus Salmon Bowl',
      mealType: 'Dinner',
      calories: 540,
      protein: 42,
      fats: 18,
      carbs: 36,
      timeMinutes: 25,
      tags: ['High Protein', 'Low Carb'],
      imageUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=1200&q=80&auto=format&fit=crop',
      palette: [Color(0xFF0F766E), Color(0xFF99F6E4)],
    ),
    Recipe(
      name: 'Honey Oat Parfait',
      mealType: 'Breakfast',
      calories: 320,
      protein: 22,
      fats: 8,
      carbs: 42,
      timeMinutes: 10,
      tags: ['Quick', 'Vegetarian'],
      imageUrl:
          'https://images.unsplash.com/photo-1505253213348-ce5ec29d52f3?w=1200&q=80&auto=format&fit=crop',
      palette: [Color(0xFFF97316), Color(0xFFFCD34D)],
    ),
    Recipe(
      name: 'Herb Chicken Lettuce Wraps',
      mealType: 'Lunch',
      calories: 410,
      protein: 38,
      fats: 12,
      carbs: 28,
      timeMinutes: 18,
      tags: ['Low Carb', 'Quick'],
      imageUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=1200&q=80&auto=format&fit=crop',
      palette: [Color(0xFF16A34A), Color(0xFFBBF7D0)],
    ),
    Recipe(
      name: 'Miso Soba Salad',
      mealType: 'Lunch',
      calories: 465,
      protein: 18,
      fats: 14,
      carbs: 62,
      timeMinutes: 20,
      tags: ['Vegetarian'],
      imageUrl:
          'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=1200&q=80&auto=format&fit=crop',
      palette: [Color(0xFF4F46E5), Color(0xFFC7D2FE)],
    ),
    Recipe(
      name: 'Smoky Turkey Chili',
      mealType: 'Dinner',
      calories: 560,
      protein: 46,
      fats: 16,
      carbs: 48,
      timeMinutes: 35,
      tags: ['High Protein'],
      imageUrl:
          'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=1200&q=80&auto=format&fit=crop',
      palette: [Color(0xFFB91C1C), Color(0xFFFECACA)],
    ),
    Recipe(
      name: 'Avocado Crunch Toast',
      mealType: 'Breakfast',
      calories: 350,
      protein: 15,
      fats: 17,
      carbs: 38,
      timeMinutes: 12,
      tags: ['Vegetarian'],
      imageUrl:
          'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=1200&q=80&auto=format&fit=crop',
      palette: [Color(0xFF0EA5E9), Color(0xFFBAE6FD)],
    ),
    Recipe(
      name: 'Tofu Rainbow Stir-Fry',
      mealType: 'Dinner',
      calories: 505,
      protein: 28,
      fats: 15,
      carbs: 58,
      timeMinutes: 22,
      tags: ['Vegetarian', 'Quick'],
      imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=1200&q=80&auto=format&fit=crop',
      palette: [Color(0xFF7C3AED), Color(0xFFE9D5FF)],
    ),
    Recipe(
      name: 'Berry Protein Shake',
      mealType: 'Snack',
      calories: 260,
      protein: 24,
      fats: 6,
      carbs: 28,
      timeMinutes: 6,
      tags: ['High Protein', 'Quick'],
      imageUrl:
          'https://images.unsplash.com/photo-1497534446932-c925b458314e?w=1200&q=80&auto=format&fit=crop',
      palette: [Color(0xFFDB2777), Color(0xFFFBCFE8)],
    ),
    Recipe(
      name: 'Zaatar Chickpea Bowl',
      mealType: 'Dinner',
      calories: 480,
      protein: 20,
      fats: 14,
      carbs: 62,
      timeMinutes: 28,
      tags: ['Vegetarian'],
      imageUrl:
          'https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?w=1200&q=80&auto=format&fit=crop',
      palette: [Color(0xFF0F172A), Color(0xFFE2E8F0)],
    ),
    Recipe(
      name: 'Peanut Noodle Jar',
      mealType: 'Lunch',
      calories: 520,
      protein: 21,
      fats: 18,
      carbs: 64,
      timeMinutes: 15,
      tags: ['Quick', 'Vegetarian'],
      imageUrl:
          'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=1200&q=80&auto=format&fit=crop',
      palette: [Color(0xFF9A3412), Color(0xFFFED7AA)],
    ),
  ];

  static const List<String> _slots = ['breakfast', 'lunch', 'dinner', 'snack'];
  static const List<String> _requiredSlots = ['breakfast', 'lunch', 'dinner'];

  List<Recipe> _filteredRecipes() {
    return _recipes.where((recipe) {
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
    _loadWeeklySelections(showLoading: true);
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
      name: data['name']?.toString() ?? 'Recipe',
      mealType: data['mealType']?.toString() ?? 'Meal',
      calories: calories,
      protein: protein,
      fats: fats,
      carbs: carbs,
      timeMinutes: timeMinutes,
      tags: List<String>.from(data['tags'] ?? const <String>[]),
      imageUrl: data['imageUrl']?.toString() ?? '',
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
    if (_isLoadingPlan) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_isPlanConfirmed) {
      return _buildConfirmedPlan(context);
    }

    final theme = Theme.of(context);
    final recipes = _filteredRecipes();
    final currentDateKey = _dateId(_currentDay);
    final filledSlots = _filledSlotsByDate[currentDateKey] ?? <String>{};
    final filledCount = filledSlots.length;
    final totalSlots = _slots.length;
    final progress = totalSlots == 0
        ? 0.0
        : (filledCount / totalSlots).clamp(0.0, 1.0);
    final missingSlots = _slots.where((slot) => !filledSlots.contains(slot));

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
                        days: _days,
                        selectedDate: _currentDay,
                        isFilled: _isDayComplete,
                        onDateSelected: (date) {
                          final index = _days.indexWhere(
                            (d) => _dateId(d) == _dateId(date),
                          );
                          if (index != -1) {
                            setState(() => _currentDayIndex = index);
                          }
                        },
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
                                  'Missing: ${missingSlots.map(_slotLabel).join(', ')}',
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
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final selected = _activeFilter == filter;
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
                          onSelected: (_) {
                            setState(() => _activeFilter = filter);
                          },
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
                    final slot = _slotForMealType(recipe.mealType);
                    final isSlotFilled = filledSlots.contains(slot);
                    return RecipeCard(
                      recipe: recipe,
                      onTap: () => _openDetails(recipe),
                      onAdd: () => _addForCurrentDay(recipe),
                      isSlotFilled: isSlotFilled,
                    );
                  }, childCount: recipes.length),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReviewSheet,
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.black,
        label: const Text('Review plan'),
        icon: const Icon(Icons.view_list),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
