// lib/models/onboarding_data.dart
class OnboardingData {
  String? gender;
  int? heightCm;
  int? weightKg;
  String? activityLevel;
  DateTime? dateOfBirth;
  String? goal;
  @override
  String toString() {
    return 'OnboardingData(gender: $gender, heightCm: $heightCm, weightKg: $weightKg, activityLevel: $activityLevel dateOfBirth: $dateOfBirth goal: $goal)';
  }
}
