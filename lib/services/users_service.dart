// lib/services/onboarding_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/onboarding_data.dart';

class UsersService {
  static final UsersService _instance = UsersService._internal();

  factory UsersService() => _instance;
  UsersService._internal();
  final _usersCollection = FirebaseFirestore.instance.collection('users');

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

  Future<void> updateMacros(String uid, Map<String, dynamic> macros) async {
    try {
      await _usersCollection.doc(uid).update({'macros': macros});
    } catch (e) {
      throw Exception('Failed to update macros: $e');
    }
  }

  Future<Map<String, dynamic>?> getDashboardData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    // Fetch user document
    final userDoc = await _usersCollection.doc(uid).get();
    if (!userDoc.exists) return null;

    final userData = userDoc.data();
    print("User Data: $userData");
    final macros = userData?['macros'];
    if (macros == null) return null;

    // Format today's date as YYYY-MM-DD
    final now = DateTime.now();
    final dateKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Fetch today's intake
    final intakeDoc = await _usersCollection
        .doc(uid)
        .collection('intake')
        .doc(dateKey)
        .get();

    print("Intake Document: ${intakeDoc.data()}");
    List<dynamic> meals = intakeDoc.data()?['meals'] ?? [];
    // Aggregate today's totals
    double totalCalories = 0, totalFats = 0, totalCarbs = 0, totalProteins = 0;

    for (final meal in meals) {
      totalCalories += (meal['calories'] ?? 0).toDouble();
      totalFats += (meal['fats'] ?? 0).toDouble();
      totalCarbs += (meal['carbs'] ?? 0).toDouble();
      totalProteins += (meal['proteins'] ?? 0).toDouble();
    }

    // Calculate progress
    double calorieProgress = totalCalories / (macros['calories'] ?? 1);
    double fatProgress = totalFats / (macros['fats'] ?? 1);
    double carbProgress = totalCarbs / (macros['carbs'] ?? 1);
    double proteinProgress = totalProteins / (macros['proteins'] ?? 1);

    return {
      'macros': macros,
      'meals': meals,
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
}
