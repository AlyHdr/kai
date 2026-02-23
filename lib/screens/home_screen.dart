import 'package:flutter/material.dart';
import 'package:kai/screens/main_screen.dart';
import 'package:kai/services/users_service.dart';
import 'package:kai/services/weekly_plan_service.dart';
import 'package:kai/widgets/dashboard_stats.dart';
import 'package:kai/widgets/week_progress.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeeklyPlanService _weeklyPlanService = WeeklyPlanService();
  late Future<Map<String, dynamic>?> _dashboardData;
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  WeeklyPlanData? _plan;

  static const List<String> _slots = ['breakfast', 'lunch', 'dinner'];

  @override
  void initState() {
    super.initState();
    _dashboardData = UsersService().getDashboardData(_selectedDate);
    _loadPlanForDate(_selectedDate, showLoader: true);
  }

  DateTime _weekStart(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  String _dateId(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _loadPlanForDate(
    DateTime date, {
    bool showLoader = false,
  }) async {
    if (showLoader && mounted) {
      setState(() => _loading = true);
    }
    final start = _weekStart(date);
    final plan = await _weeklyPlanService.loadWeeklyPlan(start);
    if (!mounted) return;
    setState(() {
      _plan = plan;
      _loading = false;
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _dashboardData = UsersService().getDashboardData(_selectedDate);
    });
    _loadPlanForDate(date);
  }

  void _openPlanDestination() {
    final hasConfirmedWeek = _plan?.isConfirmed ?? false;
    final tabIndex = hasConfirmedWeek ? 2 : 1;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainScreen(initialIndex: tabIndex)),
    );
  }

  String _todayLabel(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}';
  }

  String _greetingForNow() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final plan = _plan;
    final isPlanConfirmed = plan?.isConfirmed ?? false;
    final hasDraftSelections = !isPlanConfirmed &&
        (plan?.selections.isNotEmpty ?? false);
    final todayKey = _dateId(_selectedDate);
    final todayMeals = isPlanConfirmed
        ? (plan?.selections[todayKey] ?? <String, Map<String, dynamic>>{})
        : <String, Map<String, dynamic>>{};

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: ListView(
          children: [
            Text(
              _greetingForNow(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              'Selected day · ${_todayLabel(_selectedDate)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 10),
            WeekProgressBar(
              selectedDate: _selectedDate,
              onDateSelected: _onDateSelected,
            ),
            if (hasDraftSelections) ...[
              const SizedBox(height: 8),
              const _DraftPendingCard(),
            ],
            const SizedBox(height: 8),
            _SectionCard(
              title: 'Todays Meals',
              trailing: _SectionAction(label: 'Plan', onTap: _openPlanDestination),
              child: Builder(
                builder: (context) {
                  final plannedMeals = _slots
                      .map((slot) {
                        final meal = todayMeals[slot];
                        if (meal == null) return null;
                        return _PlannedMeal(slot: slot, data: meal);
                      })
                      .whereType<_PlannedMeal>()
                      .toList();

                  if (plannedMeals.isEmpty) {
                    return _EmptyTodayMeals(onTap: _openPlanDestination);
                  }

                  return SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: plannedMeals.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return _MealPreviewCard(
                          meal: plannedMeals[index],
                          onTap: _openPlanDestination,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 2),
            _SectionCard(
              title: 'Macros Progress',
              child: FutureBuilder<Map<String, dynamic>?>(
                future: _dashboardData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Add your targets to see stats here.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }
                  final data = snapshot.data!;
                  final progress = data['progress'] as Map<String, dynamic>;
                  final totals = data['totals'] as Map<String, dynamic>;
                  final macros = data['macros'] as Map<String, dynamic>;
                  return GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.78,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      MacroRingTile(
                        label: 'Protein',
                        progress: (progress['proteins'] ?? 0).toDouble(),
                        color: Colors.blueAccent,
                        consumed: (totals['proteins'] ?? 0).toDouble(),
                        target: (macros['proteins'] ?? 0).toDouble(),
                      ),
                      MacroRingTile(
                        label: 'Carbs',
                        progress: (progress['carbs'] ?? 0).toDouble(),
                        color: Colors.orangeAccent,
                        consumed: (totals['carbs'] ?? 0).toDouble(),
                        target: (macros['carbs'] ?? 0).toDouble(),
                      ),
                      MacroRingTile(
                        label: 'Fats',
                        progress: (progress['fats'] ?? 0).toDouble(),
                        color: Colors.redAccent,
                        consumed: (totals['fats'] ?? 0).toDouble(),
                        target: (macros['fats'] ?? 0).toDouble(),
                      ),
                      CaloriesTankTile(
                        progress: (progress['calories'] ?? 0).toDouble(),
                        consumedKcal: (totals['calories'] ?? 0).toDouble(),
                        targetKcal: (macros['calories'] ?? 0).toDouble(),
                      ),
                    ],
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

class _DraftPendingCard extends StatelessWidget {
  const _DraftPendingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: const Row(
        children: [
          Icon(Icons.pending_actions, size: 18, color: Color(0xFF92400E)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Draft week not confirmed yet. Home stats use confirmed plans only.',
              style: TextStyle(
                color: Color(0xFF78350F),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFFF7F9F6),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _SectionAction extends StatelessWidget {
  const _SectionAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            const Icon(Icons.edit_calendar, size: 16, color: Colors.black54),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlannedMeal {
  const _PlannedMeal({required this.slot, required this.data});

  final String slot;
  final Map<String, dynamic> data;
}

class _EmptyTodayMeals extends StatelessWidget {
  const _EmptyTodayMeals({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const Icon(Icons.restaurant_menu, color: Colors.black54),
          const SizedBox(width: 10),
          const Expanded(child: Text('No meals planned for today yet.')),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(foregroundColor: Colors.black87),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _MealPreviewCard extends StatelessWidget {
  const _MealPreviewCard({required this.meal, required this.onTap});

  final _PlannedMeal meal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = meal.data['name']?.toString() ?? 'Recipe';
    final imageUrl = meal.data['imageUrl']?.toString();
    final calories = meal.data['calories'];
    final time = meal.data['timeMinutes'];
    final slotLabel = _slotLabel(meal.slot);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 190,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: imageUrl == null
                  ? Container(
                      color: const Color(0xFFE7EFE8),
                      child: const Center(
                        child: Icon(Icons.image, color: Colors.black38),
                      ),
                    )
                  : Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFE7EFE8),
                          child: const Center(
                            child: Icon(Icons.image, color: Colors.black38),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: const Color(0xFFE7EFE8),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _InfoChip(label: slotLabel),
                      if (calories != null)
                        _InfoChip(label: '${calories.toString()} kcal'),
                      if (time != null) _InfoChip(label: '${time.toString()}m'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _slotLabel(String slot) {
    switch (slot) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      default:
        return slot;
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
