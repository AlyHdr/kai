import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kai/models/recipe.dart';

class RecipeCatalogService {
  RecipeCatalogService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<Recipe>> fetchRecipes({int limit = 300}) async {
    final snap = await _firestore.collection('recipes').limit(limit).get();

    return snap.docs
        .map((doc) => _recipeFromDoc(doc.id, doc.data()))
        .where((recipe) => recipe.name.isNotEmpty)
        .toList();
  }

  Recipe _recipeFromDoc(String recipeId, Map<String, dynamic> data) {
    int parseInt(dynamic value, {int fallback = 0}) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is num) return value.round();
      return int.tryParse(value.toString()) ?? fallback;
    }

    String mealType = (data['mealType'] ?? data['meal_type'] ?? 'Dinner')
        .toString();
    if (mealType.isNotEmpty) {
      mealType =
          mealType[0].toUpperCase() + mealType.substring(1).toLowerCase();
    }

    final tags = data['tags'] is List
        ? List<String>.from(data['tags'])
        : <String>[];

    final ingredientsList = data['ingredients_list'] is List
        ? List<String>.from(data['ingredients_list'])
        : data['ingredientsList'] is List
        ? List<String>.from(data['ingredientsList'])
        : <String>[];

    final instructionsList = data['instructions_list'] is List
        ? List<String>.from(data['instructions_list'])
        : data['instructionsList'] is List
        ? List<String>.from(data['instructionsList'])
        : <String>[];

    return Recipe(
      recipeId: (data['recipeId'] ?? recipeId).toString(),
      name: (data['name'] ?? data['title'] ?? '').toString(),
      mealType: mealType,
      calories: parseInt(data['calories']),
      protein: parseInt(data['protein'] ?? data['proteins']),
      fats: parseInt(data['fats']),
      carbs: parseInt(data['carbs']),
      timeMinutes: parseInt(data['timeMinutes'] ?? data['total_time_mins']),
      tags: tags,
      imageUrl: (data['imageUrl'] ?? data['image'] ?? '').toString(),
      palette: _paletteForMealType(mealType),
      ingredientsList: ingredientsList,
      instructionsList: instructionsList,
    );
  }

  List<Color> _paletteForMealType(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return const [Color(0xFFF97316), Color(0xFFFCD34D)];
      case 'lunch':
        return const [Color(0xFF16A34A), Color(0xFFBBF7D0)];
      case 'snack':
        return const [Color(0xFFDB2777), Color(0xFFFBCFE8)];
      case 'dinner':
      default:
        return const [Color(0xFF0F766E), Color(0xFF99F6E4)];
    }
  }
}
