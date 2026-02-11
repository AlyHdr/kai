import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kai/models/recipe.dart';

class WeeklyPlanData {
  const WeeklyPlanData({
    required this.selections,
    required this.filledSlotsByDate,
    required this.isConfirmed,
    required this.groceryList,
    required this.groceryStatus,
  });

  final Map<String, Map<String, Map<String, dynamic>>> selections;
  final Map<String, Set<String>> filledSlotsByDate;
  final bool isConfirmed;
  final Map<String, dynamic>? groceryList;
  final String? groceryStatus;
}

class SlotAlreadyFilledException implements Exception {}

class WeeklyPlanService {
  WeeklyPlanService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  String _dateId(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  DateTime weekStart(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  Future<WeeklyPlanData> loadWeeklyPlan(DateTime weekStartDate) async {
    final user = _auth.currentUser;
    if (user == null) {
      return const WeeklyPlanData(
        selections: {},
        filledSlotsByDate: {},
        isConfirmed: false,
        groceryList: null,
        groceryStatus: null,
      );
    }

    final weekId = _dateId(weekStartDate);
    final planRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('weekly_plans')
        .doc(weekId);

    final snap = await planRef.get();
    if (!snap.exists) {
      return const WeeklyPlanData(
        selections: {},
        filledSlotsByDate: {},
        isConfirmed: false,
        groceryList: null,
        groceryStatus: null,
      );
    }

    final data = snap.data() ?? {};
    final daysData = Map<String, dynamic>.from(data['days'] ?? {});
    final selections = <String, Map<String, Map<String, dynamic>>>{};
    final filled = <String, Set<String>>{};
    final status = data['status']?.toString();
    final groceryList = data['groceryList'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(data['groceryList'])
        : null;
    final groceryStatus = data['groceryStatus']?.toString();

    for (final entry in daysData.entries) {
      final dayData = Map<String, dynamic>.from(entry.value ?? {});
      final meals = Map<String, dynamic>.from(dayData['meals'] ?? {});
      final mealsMap = <String, Map<String, dynamic>>{};

      for (final mealEntry in meals.entries) {
        if (mealEntry.value is Map<String, dynamic>) {
          mealsMap[mealEntry.key] = Map<String, dynamic>.from(mealEntry.value);
        }
      }

      if (mealsMap.isNotEmpty) {
        selections[entry.key] = mealsMap;
        filled[entry.key] = mealsMap.keys.toSet();
      }
    }

    return WeeklyPlanData(
      selections: selections,
      filledSlotsByDate: filled,
      isConfirmed: status == 'confirmed',
      groceryList: groceryList,
      groceryStatus: groceryStatus,
    );
  }

  Future<void> addToWeeklyPlan(Recipe recipe, DateTime day) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Unauthenticated');
    }

    final weekId = _dateId(weekStart(day));
    final dateKey = _dateId(day);
    final slot = _slotForMealType(recipe.mealType);
    final planRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('weekly_plans')
        .doc(weekId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(planRef);
      final data = snap.data() ?? {};
      final days = Map<String, dynamic>.from(data['days'] ?? {});
      final dayData = Map<String, dynamic>.from(days[dateKey] ?? {});
      final meals = Map<String, dynamic>.from(dayData['meals'] ?? {});
      if (meals.containsKey(slot)) {
        throw SlotAlreadyFilledException();
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
  }

  Future<void> removeFromWeeklyPlan(DateTime day, String slot) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Unauthenticated');
    }

    final weekId = _dateId(weekStart(day));
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
  }

  Future<void> confirmWeeklyPlan(DateTime weekStartDate) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Unauthenticated');
    }

    final weekId = _dateId(weekStartDate);
    final planRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('weekly_plans')
        .doc(weekId);

    await planRef.set({
      'status': 'confirmed',
      'confirmedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> generateGroceryList(DateTime weekStartDate) async {
    // if (const bool.fromEnvironment('dart.vm.product') == false) {
    //   _functions.useFunctionsEmulator('localhost', 5001);
    // }

    final weekId = _dateId(weekStartDate);
    await _functions.httpsCallable('generate_grocery_list').call({
      'weekId': weekId,
    });
  }

  Future<void> unconfirmWeeklyPlan(DateTime weekStartDate) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Unauthenticated');
    }

    final weekId = _dateId(weekStartDate);
    final planRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('weekly_plans')
        .doc(weekId);

    await planRef.set({
      'status': 'draft',
      'confirmedAt': FieldValue.delete(),
      'groceryList': FieldValue.delete(),
      'groceryStatus': FieldValue.delete(),
      'groceryGeneratedAt': FieldValue.delete(),
      'groceryUpdatedAt': FieldValue.delete(),
      'groceryError': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
}
