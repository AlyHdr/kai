// lib/models/onboarding_data.dart
class OnboardingData {
  String? fullName;
  String? gender;
  int? heightCm;
  int? weightKg;
  String? activityLevel;
  DateTime? dateOfBirth;
  String? goal;
  String? dietPreference;
  bool isTrial = true;
  @override
  String toString() {
    return 'OnboardingData(gender: $gender, heightCm: $heightCm, weightKg: $weightKg, activityLevel: $activityLevel dateOfBirth: $dateOfBirth goal: $goal dietPreference: $dietPreference)';
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'gender': gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'activityLevel': activityLevel,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'goal': goal,
      'dietPreference': dietPreference,
      'isTrial': isTrial,
    };
  }
}

const Map<String, String> activityLevels = {
  'Low': 'Mostly sedentary lifestyle, little to no exercise.',
  'Moderate': 'Light exercise or daily activity like walking.',
  'High': 'Frequent intense workouts or physically demanding job.',
};

const Map<String, String> diets = {
  'No Preference': 'No specific dietary restriction or preference.',
  'Vegetarian': 'No meat, but includes dairy and eggs.',
  'Vegan': 'No animal products of any kind.',
  'Low Carb': 'Focus on reducing carbohydrate intake.',
  'High Protein': 'Emphasizes protein-rich foods for muscle growth.',
};

const Map<String, String> goals = {
  'Lose Weight': 'Focus on fat loss and calorie control.',
  'Build Muscle': 'Support muscle growth with nutrition and training.',
  'Maintain': 'Sustain your current physique and health.',
};
