// lib/screens/onboarding/steps/thank_you_step.dart
import 'package:flutter/material.dart';
import '../../../widgets/step_button.dart';

class ThankingStep extends StatelessWidget {
  final VoidCallback onNext;

  const ThankingStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 100),
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
          SizedBox(height: 24),
          Text(
            'Thank you!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'I appreciate your effort. I\'ll now analyze your information to personalize your experience.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          Spacer(),
          StepButton(label: 'Continue', onPressed: onNext),
        ],
      ),
    );
  }
}
