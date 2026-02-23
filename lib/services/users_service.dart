// lib/services/onboarding_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/onboarding_data.dart';

class UsersService {
  static final UsersService _instance = UsersService._internal();

  factory UsersService() => _instance;
  UsersService._internal();
  final _usersCollection = FirebaseFirestore.instance.collection('users');

  Future<bool> userExists(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed checking user existence: $e');
    }
  }

  Future<bool> currentUserExists() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    return userExists(uid);
  }

  Future<void> createUser(String uid, OnboardingData data) async {
    try {
      await _usersCollection.doc(uid).set(data.toMap());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchMacros() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists || doc.data()?['macros'] == null) return null;

    return Map<String, dynamic>.from(doc.data()!['macros']);
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Future<void> updateMacros(String uid, Map<String, dynamic> macros) async {
    try {
      await _usersCollection.doc(uid).update({'macros': macros});
    } catch (e) {
      throw Exception('Failed to update macros: $e');
    }
  }

  Future<Map<String, dynamic>?> getDashboardData(DateTime selectedDate) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final userDoc = await _usersCollection.doc(uid).get();
    if (!userDoc.exists) return null;

    final userData = userDoc.data();
    final macros = userData?['macros'];
    if (macros == null) return null;

    DateTime weekStart(DateTime date) {
      final normalized = DateTime(date.year, date.month, date.day);
      return normalized.subtract(Duration(days: normalized.weekday - 1));
    }

    String dateId(DateTime date) {
      final year = date.year.toString();
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      return '$year-$month-$day';
    }

    final dateKey = dateId(selectedDate);
    final weekId = dateId(weekStart(selectedDate));

    final planDoc = await _usersCollection
        .doc(uid)
        .collection('weekly_plans')
        .doc(weekId)
        .get();

    final planData = planDoc.data() ?? {};
    final isConfirmed = planData['status']?.toString() == 'confirmed';
    final days = isConfirmed
        ? (planData['days'] as Map<String, dynamic>? ?? <String, dynamic>{})
        : <String, dynamic>{};
    final dayData = days[dateKey] as Map<String, dynamic>? ?? {};
    final mealsMap = dayData['meals'] as Map<String, dynamic>? ?? {};

    double totalCalories = 0, totalFats = 0, totalCarbs = 0, totalProteins = 0;

    mealsMap.forEach((key, meal) {
      if (meal is Map<String, dynamic>) {
        totalCalories += (meal['calories'] ?? 0).toDouble();
        totalProteins += (meal['protein'] ?? 0).toDouble();
        totalFats += (meal['fats'] ?? 0).toDouble();
        totalCarbs += (meal['carbs'] ?? 0).toDouble();
      }
    });

    double calorieProgress = totalCalories / (macros['calories'] ?? 1);
    double fatProgress = totalFats / (macros['fats'] ?? 1);
    double carbProgress = totalCarbs / (macros['carbs'] ?? 1);
    double proteinProgress = totalProteins / (macros['proteins'] ?? 1);

    return {
      'macros': macros,
      'meals': mealsMap,
      'progress': {
        'calories': calorieProgress.clamp(0.0, 1.0),
        'fats': fatProgress.clamp(0.0, 1.0),
        'carbs': carbProgress.clamp(0.0, 1.0),
        'proteins': proteinProgress.clamp(0.0, 1.0),
      },
      'totals': {
        'calories': totalCalories,
        'fats': totalFats,
        'carbs': totalCarbs,
        'proteins': totalProteins,
      },
    };
  }

  Future<bool> hasWeeklyPlanForWeek(DateTime date) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    DateTime weekStart(DateTime d) {
      final normalized = DateTime(d.year, d.month, d.day);
      return normalized.subtract(Duration(days: normalized.weekday - 1));
    }

    String dateId(DateTime d) {
      final y = d.year.toString();
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '$y-$m-$day';
    }

    final weekId = dateId(weekStart(date));

    final planDoc = await _usersCollection
        .doc(uid)
        .collection('weekly_plans')
        .doc(weekId)
        .get();

    if (!planDoc.exists) return false;
    final data = planDoc.data() ?? {};
    if (data['status']?.toString() != 'confirmed') return false;
    final days = data['days'] as Map<String, dynamic>? ?? {};
    return days.isNotEmpty;
  }

  Future<bool> hasWeeklyPlanForNextWeek(DateTime date) async {
    final startOfThisWeek = DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
    final startOfNextWeek = startOfThisWeek.add(const Duration(days: 7));
    return hasWeeklyPlanForWeek(startOfNextWeek);
  }
}
