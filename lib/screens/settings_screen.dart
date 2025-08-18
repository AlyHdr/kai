import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kai/services/users_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  Future<void> insertTestIntakeToSubcollection() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      print("❌ No user logged in.");
      return;
    }

    final dateKey = "2025-07-25"; // Or use today's date programmatically

    final testMeals = [
      {
        "name": "Oatmeal & Banana",
        "category": "Breakfast",
        "calories": 320,
        "fats": 8,
        "carbs": 45,
        "proteins": 10,
      },
      {
        "name": "Grilled Chicken Salad",
        "category": "Lunch",
        "calories": 450,
        "fats": 12,
        "carbs": 20,
        "proteins": 40,
      },
    ];

    final intakeRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('intake')
        .doc(dateKey);

    await intakeRef.set({
      'meals': testMeals,
      'createdAt': FieldValue.serverTimestamp(), // optional
    });

    print("✅ Test intake data inserted for $dateKey");
  }

  Future<void> _callGenerateMealFunction() async {
    FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
    var userData = await UsersService().getUserData();
    final result = await FirebaseFunctions.instance
        .httpsCallable('generate_meal_plan')
        .call(userData);
    print("Meal Plan Result: ${result.data}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: insertTestIntakeToSubcollection,
              child: const Text("Insert Test Intake Data"),
            ),
            ElevatedButton(
              onPressed: () {
                _callGenerateMealFunction();
              },
              child: const Text("Call Generate Meal Function"),
            ),
          ],
        ),
      ),
    );
  }
}
