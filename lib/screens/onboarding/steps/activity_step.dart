// lib/screens/onboarding/steps/activity_level_step.dart
import 'package:flutter/material.dart';
import '../../../widgets/step_button.dart';

class ActivityLevelStep extends StatefulWidget {
  final String? selectedLevel;
  final Function(String level) onNext;

  const ActivityLevelStep({
    super.key,
    this.selectedLevel,
    required this.onNext,
  });

  @override
  State<ActivityLevelStep> createState() => _ActivityLevelStepState();
}

class _ActivityLevelStepState extends State<ActivityLevelStep> {
  final List<String> levels = ['Low', 'Moderate', 'High'];

  final Map<String, String> descriptions = {
    'Low': 'Mostly sedentary lifestyle, little to no exercise.',
    'Moderate': 'Light exercise or daily activity like walking.',
    'High': 'Frequent intense workouts or physically demanding job.',
  };

  String? selected;

  @override
  void initState() {
    super.initState();
    selected = widget.selectedLevel;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 60),
          Text(
            'How active are you?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('This helps me tailor your experience to your lifestyle.'),
          SizedBox(height: 32),
          ...levels.map(
            (level) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GestureDetector(
                onTap: () => setState(() => selected = level),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    color: selected == level
                        ? Colors.greenAccent
                        : Color(0xFFF7F6FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        descriptions[level]!,
                        style: TextStyle(color: Colors.black87, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Spacer(),
          StepButton(
            enabled: selected != null,
            onPressed: () => widget.onNext(selected!),
          ),
        ],
      ),
    );
  }
}
