import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kai/services/users_service.dart';
import 'package:kai/services/json_sanitizer.dart';
import 'package:kai/services/subscription_service.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _subscription = SubscriptionService.instance;

  late final String _uid;
  late final String _dateId; // yyyy-MM-dd
  bool _generationTriggered = false;
  String? _genError;

  // Option sources (customize freely)
  static const List<String> cuisines = <String>[
    'any',
    'Mediterranean',
    'Italian',
    'French',
    'Mexican',
    'Indian',
    'Japanese',
    'Chinese',
    'Middle Eastern',
    'Thai',
    'American',
  ];

  static const List<String> proteinOptions = <String>[
    'any',
    'chicken',
    'beef',
    'turkey',
    'pork',
    'fish',
    'seafood',
    'eggs',
    'dairy',
    'tofu',
    'tempeh',
    'legumes',
  ];

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

  // Tracks daily usage (meal generation count) per user per day.
  DocumentReference<Map<String, dynamic>> get _usageDoc =>
      _firestore.collection('users').doc(_uid).collection('usage').doc(_dateId);

  /// Prompts the user for cuisine, protein preferences, and optional custom notes.
  /// Returns a map shaped like:
  /// {
  ///   'cuisine': String,
  ///   'proteins': {'breakfast': String, 'lunch': String, 'dinner': String},
  ///   'custom': String (optional free text for LLM)
  /// }
  /// If the dialog is dismissed or Skip is pressed, returns null (treat as cancel).
  Future<Map<String, dynamic>?> _promptMealPreferences() async {
    String cuisine = 'any';
    String proteinBreakfast = 'any';
    String proteinLunch = 'any';
    String proteinDinner = 'any';
    String customText = '';
    final customController = TextEditingController();

    // Show the dialog; keep local state with StatefulBuilder
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Meal Preferences'),
          content: StatefulBuilder(
            builder: (ctx, setLocal) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Choose your cuisine and preferred protein for each meal.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: cuisine,
                      decoration: const InputDecoration(
                        labelText: 'Cuisine',
                        border: OutlineInputBorder(),
                      ),
                      items: cuisines
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(_capitalize(c)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setLocal(() => cuisine = v ?? 'any'),
                    ),
                    const SizedBox(height: 16),
                    _ProteinDropdown(
                      label: 'Breakfast protein',
                      value: proteinBreakfast,
                      onChanged: (v) => setLocal(() => proteinBreakfast = v),
                    ),
                    const SizedBox(height: 12),
                    _ProteinDropdown(
                      label: 'Lunch protein',
                      value: proteinLunch,
                      onChanged: (v) => setLocal(() => proteinLunch = v),
                    ),
                    const SizedBox(height: 12),
                    _ProteinDropdown(
                      label: 'Dinner protein',
                      value: proteinDinner,
                      onChanged: (v) => setLocal(() => proteinDinner = v),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: customController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Custom preferences (optional)',
                        hintText:
                            'e.g., avoid mushrooms, lactose-free, prefer air fryer, budget-friendly, quick prep',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => setLocal(() => customText = v),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );

    // Cancel if user pressed Skip or dismissed the dialog.
    if (result != true) return null;

    // Apply with current selections
    return {
      'cuisine': cuisine,
      'proteins': {
        'breakfast': proteinBreakfast,
        'lunch': proteinLunch,
        'dinner': proteinDinner,
      },
      if (customText.trim().isNotEmpty) 'custom': customText.trim(),
    };
  }

  Map<String, dynamic> _defaultPreferences() => {
    'cuisine': 'any',
    'proteins': {'breakfast': 'any', 'lunch': 'any', 'dinner': 'any'},
  };

  Future<bool> _handleGenerate({bool force = false}) async {
    if (_generationTriggered) return false;

    // Feature gate: only gate customization, not access
    bool entitled = false;
    try {
      entitled = await _subscription.isEntitled();
    } catch (_) {
      entitled = false;
    }

    Map<String, dynamic>? prefs;

    if (!entitled) {
      final action = await showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          title: const Text('Customize Meal Plan'),
          content: const Text(
            'Subscribe to unlock full meal plan customization, or generate a plan using default preferences.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('defaults'),
              child: const Text('Use defaults'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _subscription.presentPaywallIfNeeded();
                final nowEntitled = await _subscription.isEntitled();
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop(nowEntitled ? 'subscribed' : 'cancel');
              },
              child: const Text('Subscribe'),
            ),
          ],
        ),
      );

      if (action == 'defaults') {
        prefs = _defaultPreferences();
      } else if (action == 'subscribed') {
        // proceed to full preferences
        prefs = await _promptMealPreferences();
      } else {
        // cancel/dismiss
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plan generation canceled')),
          );
        }
        return false;
      }
    } else {
      // Entitled: show full preferences
      prefs = await _promptMealPreferences();
    }

    if (prefs == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan generation canceled')),
        );
      }
      return false;
    }

    // Enforce daily usage limits before starting generation.
    // Non‑subscribed: 1/day, Subscribed: 5/day.
    bool nowEntitled = false;
    try {
      nowEntitled = await _subscription.isEntitled();
    } catch (_) {
      nowEntitled = false;
    }

    final allowed = await _consumeDailyGenerationSlot(entitled: nowEntitled);
    if (!allowed) {
      // If not subscribed, show dialog with Subscribe action to present paywall.
      if (!nowEntitled) {
        final action = await showDialog<String>(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => AlertDialog(
            title: const Text('Daily limit reached'),
            content: const Text(
              'You\'ve used your 1 free daily meal generation. Subscribe for 5 per day or try again tomorrow.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop('cancel'),
                child: const Text('Not now'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _subscription.presentPaywallIfNeeded();
                  bool afterEntitled = false;
                  try {
                    afterEntitled = await _subscription.isEntitled();
                  } catch (_) {
                    afterEntitled = false;
                  }
                  if (!ctx.mounted) return;
                  Navigator.of(
                    ctx,
                  ).pop(afterEntitled ? 'subscribed' : 'cancel');
                },
                child: const Text('Subscribe'),
              ),
            ],
          ),
        );

        if (action == 'subscribed') {
          // Retry consume with subscriber limit (5/day)
          final retryAllowed = await _consumeDailyGenerationSlot(
            entitled: true,
          );
          if (retryAllowed) {
            await _startGenerationWithPrefs(prefs: prefs, force: force);
            return true;
          } else {
            if (!mounted) return false;
            await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Daily limit reached'),
                content: const Text(
                  'Daily limit reached (5 per day for subscribers). Try again tomorrow.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
            return false;
          }
        } else {
          if (!mounted) return false;
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Daily limit reached'),
              content: const Text(
                'Daily limit reached (1 per day on free). Subscribe for 5/day or try again tomorrow.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return false;
        }
      }

      // Already subscribed and at limit: show informational dialog.
      if (!mounted) return false;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Daily limit reached'),
          content: const Text(
            'Daily limit reached (5 per day for subscribers). Try again tomorrow.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }

    await _startGenerationWithPrefs(prefs: prefs, force: force);
    return true;
  }

  /// Attempts to consume one meal generation for the current day.
  /// Returns true if within limit (and increments usage), false if limit reached.
  Future<bool> _consumeDailyGenerationSlot({required bool entitled}) async {
    final int limit = entitled ? 5 : 1;
    try {
      final allowed = await _firestore.runTransaction<bool>((tx) async {
        final snap = await tx.get(_usageDoc);
        final data = snap.data();
        final used = (data != null
            ? (data['mealGenerations'] as int? ?? 0)
            : 0);
        if (used >= limit) {
          // Do not update; signal not allowed.
          return false;
        }
        if (snap.exists) {
          tx.update(_usageDoc, {
            'mealGenerations': used + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          tx.set(_usageDoc, {
            'mealGenerations': 1,
            'updatedAt': FieldValue.serverTimestamp(),
            'date': _dateId,
          });
        }
        return true;
      });
      return allowed;
    } catch (e) {
      // On any error, fail open to avoid blocking legitimate generations due to transient issues.
      // You may choose to fail closed instead depending on product needs.
      return true;
    }
  }

  Future<void> _startGenerationWithPrefs({
    required Map<String, dynamic> prefs,
    bool force = false,
  }) async {
    setState(() {
      _generationTriggered = true;
      _genError = null;
    });

    try {
      // Use Functions emulator only in debug/profile builds
      // if (const bool.fromEnvironment('dart.vm.product') == false) {
      //   FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
      // }

      final rawUserData = await UsersService().getUserData();
      final userData = sanitizeForCallable(rawUserData) as Map<String, dynamic>;
      final payload = {
        ...userData,
        'preferences': prefs,
        'dateId': _dateId,
        'progressive': true,
        if (force) 'forceRegenerate': true,
      };
      print('Generating meal plan with payload: $payload');
      await FirebaseFunctions.instance
          .httpsCallable('generate_meal_plan')
          .call(payload);
      if (mounted) setState(() => _genError = null);
    } catch (e) {
      if (mounted) {
        print('Error generating plan: $e');
        setState(() {
          _genError = 'Failed to generate plan: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _generationTriggered = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _planDoc.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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
            if (_genError != null) {
              return _ErrorState(
                message: _genError!,
                onRetry: () => setState(() => _genError = null),
              );
            }
            if (_generationTriggered) {
              return const _CenteredProgress('Generating your plan...');
            }
            return _EmptyPlanCta(
              onGenerate: () {
                _handleGenerate();
              },
            );
          }

          final data = doc.data()!;
          final meals = (data as Map<String, dynamic>?) ?? {};
          final status = meals['status'] as String?;
          final progress = meals['progress'] as Map<String, dynamic>?;
          final selected = (data['selected'] as Map<String, dynamic>?) ?? {};

          return RefreshIndicator(
            onRefresh: () async {
              await _planDoc.get(GetOptions(source: Source.server));
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (status == 'generating')
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Generating… ${(progress?['stage'] ?? '')} ${progress?['percent'] != null ? '(${progress!['percent']}%)' : ''}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                _TotalsCard(intakeDoc: _intakeDoc),
                const SizedBox(height: 16),
                _MealSection(
                  title: 'Breakfast',
                  keyName: 'breakfast',
                  options: (meals['breakfast'] as List<dynamic>? ?? [])
                      .map((e) => e as Map<String, dynamic>)
                      .toList(),
                  selected: selected['breakfast'],
                  pending:
                      status == 'generating' &&
                      ((meals['breakfast'] as List<dynamic>? ?? []).isEmpty),
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
                  pending:
                      status == 'generating' &&
                      ((meals['lunch'] as List<dynamic>? ?? []).isEmpty),
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
                  pending:
                      status == 'generating' &&
                      ((meals['dinner'] as List<dynamic>? ?? []).isEmpty),
                  onPick: (meal) => _selectMeal('dinner', meal),
                ),
                const SizedBox(height: 16),
                _MealSection(
                  title: 'Snack',
                  keyName: 'snack',
                  options: (meals['snack'] as List<dynamic>? ?? [])
                      .map((e) => e as Map<String, dynamic>)
                      .toList(),
                  selected: selected['snack'],
                  pending:
                      status == 'generating' &&
                      ((meals['snack'] as List<dynamic>? ?? []).isEmpty),
                  onPick: (meal) => _selectMeal('snack', meal),
                ),
                const SizedBox(height: 12),

                // Optional: allow regenerating with new preferences (gated)
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final started = await _handleGenerate(force: true);
                      if (mounted && started) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Regeneration started…'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to regenerate plan: $e'),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.tune),
                  label: const Text('Adjust preferences & regenerate'),
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
      case 'snack':
        return 'Snack';
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

  static String _capitalize(String v) =>
      v.isEmpty ? v : v[0].toUpperCase() + v.substring(1);
}

class _ProteinDropdown extends StatelessWidget {
  const _ProteinDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: _MealPlanScreenState.proteinOptions
          .map((p) => DropdownMenuItem(value: p, child: Text(_cap(p))))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  static String _cap(String v) =>
      v.isEmpty ? v : v[0].toUpperCase() + v.substring(1);
}

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.title,
    required this.keyName,
    required this.options,
    required this.selected,
    required this.onPick,
    this.pending = false,
  });

  final String title;
  final String keyName;
  final List<Map<String, dynamic>> options;
  final dynamic selected; // Map or null
  final void Function(Map<String, dynamic> meal) onPick;
  final bool pending;

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
            else if (pending)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Generating options…'),
                  SizedBox(height: 8),
                  LinearProgressIndicator(),
                ],
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

  List<String> _asStringList(dynamic v) {
    if (v == null) return const [];
    if (v is List) {
      return v
          .where((e) => e != null)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      child: const Text('Details'),
      onPressed: () {
        final theme = Theme.of(context);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (context) {
            final macros = (meal['macros'] as Map<String, dynamic>?) ?? {};
            final ingredients = _asStringList(
              meal['ingredients'],
            ); // <-- List<String>
            final instructions = _asStringList(
              meal['instructions'],
            ); // <-- List<String>

            final calories = macros['calories'] ?? meal['calories'];
            final protein = macros['protein'];
            final carbs = macros['carbs'];
            final fats = macros['fats'];

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        meal['name'] ?? 'Meal',
                        style: theme.textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Description
                      if ((meal['description'] as String?)?.isNotEmpty ==
                          true) ...[
                        Text(meal['description']),
                        const SizedBox(height: 12),
                      ],

                      // Macros chips
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          if (calories != null)
                            Chip(label: Text('Cal: $calories')),
                          if (protein != null)
                            Chip(label: Text('P: $protein g')),
                          if (carbs != null) Chip(label: Text('C: $carbs g')),
                          if (fats != null) Chip(label: Text('F: $fats g')),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Ingredients (bulleted)
                      if (ingredients.isNotEmpty) ...[
                        Text('Ingredients', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ...ingredients.map(
                          (line) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('•  '),
                                Expanded(child: Text(line)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Instructions (numbered)
                      if (instructions.isNotEmpty) ...[
                        Text(
                          'Instructions',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(instructions.length, (i) {
                          final step = instructions[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${i + 1}. '),
                                Expanded(child: Text(step)),
                              ],
                            ),
                          );
                        }),
                      ],

                      if (ingredients.isEmpty && instructions.isEmpty)
                        Text(
                          'No detailed ingredients or instructions available.',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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
                _Kpi(label: 'Protein', value: '${totals['proteins'] ?? 0}g'),
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

class _EmptyPlanCta extends StatelessWidget {
  const _EmptyPlanCta({required this.onGenerate});
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No plan for today yet.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the button below to set preferences and generate your daily plan.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Generate Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                minimumSize: const Size(200, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
