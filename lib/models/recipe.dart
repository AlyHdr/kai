import 'package:flutter/material.dart';

class Recipe {
  const Recipe({
    required this.name,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.fats,
    required this.carbs,
    required this.timeMinutes,
    required this.tags,
    required this.imageUrl,
    required this.palette,
  });

  final String name;
  final String mealType;
  final int calories;
  final int protein;
  final int fats;
  final int carbs;
  final int timeMinutes;
  final List<String> tags;
  final String imageUrl;
  final List<Color> palette;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mealType': mealType,
      'calories': calories,
      'protein': protein,
      'fats': fats,
      'carbs': carbs,
      'timeMinutes': timeMinutes,
      'tags': tags,
      'imageUrl': imageUrl,
    };
  }
}
