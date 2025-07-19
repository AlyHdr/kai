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
