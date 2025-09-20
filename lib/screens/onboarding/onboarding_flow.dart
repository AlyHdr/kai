// lib/screens/onboarding/onboarding_flow.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:kai/screens/authentication/verify_email_screen.dart';
import 'package:kai/screens/onboarding/steps/thanking_step.dart';
import 'package:kai/services/auth_service.dart';
import 'package:kai/services/macros_service.dart';
import 'package:kai/services/users_service.dart';
import '../../models/onboarding_data.dart';
import 'steps/activity_step.dart';
import 'steps/diet_step.dart';
import 'steps/gender_step.dart';
import 'steps/height_weight_step.dart';
import 'steps/dob_step.dart';
import 'steps/goal_step.dart';
import 'steps/registration_step.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  _OnboardingFlowState createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _controller = PageController();
  int _currentStep = 0;
  OnboardingData data = OnboardingData();
  final AuthService _authService = AuthService();
  final UsersService _userService = UsersService();
  final MacrosService _macrosService = MacrosService();
  void _nextStep() {
    if (_currentStep < 7) {
      _controller.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      // TODO: Finalize onboarding
      print(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (_currentStep > 0) {
              _controller.previousPage(
                duration: Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: LinearProgressIndicator(
          value: (_currentStep + 1) / 8, // Adjust based on number of steps
          backgroundColor: Colors.grey.shade300,
          color: Colors.greenAccent,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [],
      ),
      body: PageView(
        controller: _controller,
        physics: NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentStep = index),
        children: [
          GenderStep(
            selectedGender: data.gender,
            onNext: (gender) {
              setState(() => data.gender = gender);
              _nextStep();
            },
          ),
          ActivityLevelStep(
            selectedLevel: data.activityLevel,
            onNext: (level) {
              setState(() => data.activityLevel = level);
              _nextStep();
            },
          ),
          HeightWeightStep(
            initialHeight: data.heightCm ?? 170,
            initialWeight: data.weightKg ?? 70,
            onNext: (height, weight) {
              setState(() {
                data.heightCm = height;
                data.weightKg = weight;
              });
              _nextStep();
            },
          ),
          DateOfBirthStep(
            initialDate: data.dateOfBirth,
            onNext: (dob) {
              setState(() => data.dateOfBirth = dob);
              _nextStep();
            },
          ),
          GoalStep(
            selectedGoal: data.goal,
            onNext: (goal) {
              setState(() => data.goal = goal);
              _nextStep();
            },
          ),
          DietPreferenceStep(
            selectedDiet: data.dietPreference,
            onNext: (diet) {
              setState(() => data.dietPreference = diet);
              _nextStep();
            },
          ),
          ThankingStep(
            onNext: () {
              _nextStep();
            },
          ),
          RegistrationStep(
            onRegister: (fullName, email, password) async {
              try {
                final userCredentials = await _authService.signUp(
                  email,
                  password,
                );
                final uid = userCredentials.user?.uid;

                if (uid != null) {
                  setState(() {
                    data.fullName = fullName;
                  });

                  await _userService.createUser(uid, data);
                  await userCredentials.user?.sendEmailVerification();
                  await _macrosService.generateMacros(data, uid);

                  // Navigate to email verification screen once all succeeded
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          VerifyEmailScreen(user: userCredentials.user!),
                    ),
                  );
                } else {
                  throw Exception('User UID is null');
                }
              } catch (error) {
                // Allow RegistrationStep to surface the error to the user
                rethrow;
              }
            },
          ),
        ],
      ),
    );
  }
}
