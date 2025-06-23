// lib/screens/onboarding/onboarding_flow.dart
import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';
import 'steps/activity_step.dart';
import 'steps/gender_step.dart';
import 'steps/height_weight_step.dart';
import 'steps/dob_step.dart';
import 'steps/goal_step.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  _OnboardingFlowState createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _controller = PageController();
  int _currentStep = 0;
  OnboardingData data = OnboardingData();

  void _nextStep() {
    if (_currentStep < 4) {
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
          value: (_currentStep + 1) / 5, // Adjust based on number of steps
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
        ],
      ),
    );
  }
}
