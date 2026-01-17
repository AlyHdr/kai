import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kai/models/recipe.dart';
import 'package:kai/screens/recipe_detail_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String _activeFilter = 'All';
  late final List<DateTime> _days;
  int _currentDayIndex = 0;
  final Map<String, Set<String>> _filledSlotsByDate = {};
  final Map<String, Map<String, Map<String, dynamic>>> _weeklySelections = {};

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
    final startOfNextWeek = startOfThisWeek.add(const Duration(days: 7));
    _days = List<DateTime>.generate(
      7,
      (i) => startOfNextWeek.add(Duration(days: i)),
    );
    _loadWeeklySelections();
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

  Future<void> _loadWeeklySelections() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final weekId = _dateId(_weekStart(_days.first));
    final planRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('weekly_plans')
        .doc(weekId);

    try {
      final snap = await planRef.get();
      if (!snap.exists) return;

      final data = snap.data() ?? {};
      final daysData = Map<String, dynamic>.from(data['days'] ?? {});
      final selections = <String, Map<String, Map<String, dynamic>>>{};
      final filled = <String, Set<String>>{};

      for (final entry in daysData.entries) {
        final dayData = Map<String, dynamic>.from(entry.value ?? {});
        final meals = Map<String, dynamic>.from(dayData['meals'] ?? {});
        final mealsMap = <String, Map<String, dynamic>>{};

        for (final mealEntry in meals.entries) {
          if (mealEntry.value is Map<String, dynamic>) {
            mealsMap[mealEntry.key] = Map<String, dynamic>.from(
              mealEntry.value,
            );
          }
        }

        if (mealsMap.isNotEmpty) {
          selections[entry.key] = mealsMap;
          filled[entry.key] = mealsMap.keys.toSet();
        }
      }

      if (!mounted) return;
      setState(() {
        _weeklySelections
          ..clear()
          ..addAll(selections);
        _filledSlotsByDate
          ..clear()
          ..addAll(filled);
      });
    } catch (_) {
      // Ignore load errors; user can still proceed with picks.
    }
  }

  Future<void> _addToWeeklyPlan(Recipe recipe, DateTime day) async {
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in first.')));
      return;
    }

    final weekId = _dateId(_weekStart(day));
    final dateKey = _dateId(day);
    final slot = _slotForMealType(recipe.mealType);
    final planRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('weekly_plans')
        .doc(weekId);

    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(planRef);
        final data = snap.data() ?? {};
        final days = Map<String, dynamic>.from(data['days'] ?? {});
        final dayData = Map<String, dynamic>.from(days[dateKey] ?? {});
        final meals = Map<String, dynamic>.from(dayData['meals'] ?? {});
        if (meals.containsKey(slot)) {
          throw Exception('Slot already filled');
        }
        meals[slot] = recipe.toMap();
        dayData['meals'] = meals;
        days[dateKey] = dayData;

        if (snap.exists) {
          tx.update(planRef, {
            'days': days,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          tx.set(planRef, {
            'weekStart': weekId,
            'days': days,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (_) {
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
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in first.')));
      return;
    }

    final weekId = _dateId(_weekStart(day));
    final dateKey = _dateId(day);
    final planRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('weekly_plans')
        .doc(weekId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(planRef);
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      final days = Map<String, dynamic>.from(data['days'] ?? {});
      final dayData = Map<String, dynamic>.from(days[dateKey] ?? {});
      final meals = Map<String, dynamic>.from(dayData['meals'] ?? {});

      if (!meals.containsKey(slot)) return;
      meals.remove(slot);
      if (meals.isEmpty) {
        days.remove(dateKey);
      } else {
        dayData['meals'] = meals;
        days[dateKey] = dayData;
      }

      tx.update(planRef, {
        'days': days,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    if (!mounted) return;
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
    final timeMinutes = (data['timeMinutes'] as num?)?.round() ?? 0;
    return Recipe(
      name: data['name']?.toString() ?? 'Recipe',
      mealType: data['mealType']?.toString() ?? 'Meal',
      calories: calories,
      protein: protein,
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
                                        child: _ReviewRecipeTile(
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
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
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

  void _openDetails(Recipe recipe) {
    _openDetailsForDay(recipe, _currentDay);
  }

  @override
  Widget build(BuildContext context) {
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
                      _WeekDayPicker(
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
                    return _RecipeCard(
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
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        label: const Text('Review plan'),
        icon: const Icon(Icons.view_list),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _WeekDayPicker extends StatelessWidget {
  const _WeekDayPicker({
    required this.days,
    required this.selectedDate,
    required this.isFilled,
    required this.onDateSelected,
  });

  final List<DateTime> days;
  final DateTime selectedDate;
  final bool Function(DateTime date) isFilled;
  final ValueChanged<DateTime> onDateSelected;

  String _initialFor(DateTime date) {
    const initials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return initials[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((date) {
        final isSelected =
            date.year == selectedDate.year &&
            date.month == selectedDate.month &&
            date.day == selectedDate.day;
        final filled = isFilled(date);
        final accentColor = Colors.greenAccent;
        final showAccent = isSelected || filled;
        final textColor = isSelected
            ? Colors.white
            : (filled ? accentColor : Colors.grey);
        final borderColor = filled && !isSelected ? accentColor : Colors.grey;

        return GestureDetector(
          onTap: () => onDateSelected(date),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? accentColor : Colors.transparent,
                      border: Border.all(color: borderColor),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initialFor(date),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: showAccent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (filled)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                date.day.toString(),
                style: TextStyle(
                  color: showAccent ? accentColor : Colors.grey,
                  fontWeight: showAccent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.recipe,
    required this.onTap,
    required this.onAdd,
    required this.isSlotFilled,
  });

  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final bool isSlotFilled;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: recipe.palette,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageHeight = (constraints.maxHeight * 0.46).clamp(80.0, 140.0);
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: imageHeight,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            recipe.imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(color: recipe.palette.first);
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(color: recipe.palette.first);
                            },
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: _Badge(text: recipe.mealType),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            top: 10,
                            child: _AddButton(
                              onTap: isSlotFilled ? null : onAdd,
                              isChecked: isSlotFilled,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            recipe.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '${recipe.calories} kcal · ${recipe.protein}g protein',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: recipe.tags
                                .take(2)
                                .map((tag) => _TagChip(label: tag))
                                .toList(),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${recipe.timeMinutes} min',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ],
                      ),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _ReviewRecipeTile extends StatelessWidget {
  const _ReviewRecipeTile({
    required this.recipe,
    required this.slotLabel,
    required this.onTap,
    required this.onRemove,
  });

  final Recipe recipe;
  final String slotLabel;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: recipe.imageUrl.isEmpty
                      ? Container(color: recipe.palette.first)
                      : Image.network(
                          recipe.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(color: recipe.palette.first);
                          },
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slotLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${recipe.calories} kcal · ${recipe.protein}g protein',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, color: Colors.black38),
                tooltip: 'Remove',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap, this.isChecked = false});

  final VoidCallback? onTap;
  final bool isChecked;

  @override
  Widget build(BuildContext context) {
    final background = isChecked
        ? Colors.greenAccent
        : Colors.white.withOpacity(0.9);
    final icon = isChecked ? Icons.check : Icons.add;
    final iconColor = Colors.black87;
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}
