// lib/screens/onboarding/steps/diet_preference_step.dart
import 'package:flutter/material.dart';
import '../../../widgets/step_button.dart';

class DietPreferenceStep extends StatefulWidget {
  final String? selectedDiet;
  final Function(String diet) onNext;

  const DietPreferenceStep({
    super.key,
    this.selectedDiet,
    required this.onNext,
  });

  @override
  State<DietPreferenceStep> createState() => _DietPreferenceStepState();
}

class _DietPreferenceStepState extends State<DietPreferenceStep> {
  final List<String> diets = [
    'No Preference',
    'Vegetarian',
    'Vegan',
    'Low Carb',
    'High Protein',
  ];

  final Map<String, String> descriptions = {
    'No Preference': 'No specific dietary restriction or preference.',
    'Vegetarian': 'No meat, but includes dairy and eggs.',
    'Vegan': 'No animal products of any kind.',
    'Low Carb': 'Focus on reducing carbohydrate intake.',
    'High Protein': 'Emphasizes protein-rich foods for muscle growth.',
  };

  String? selected;

  @override
  void initState() {
    super.initState();
    selected = widget.selectedDiet;
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
            'Do you have any diet preference?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('This helps me tailor recommendations to your lifestyle.'),
          SizedBox(height: 32),
          ...diets.map(
            (diet) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GestureDetector(
                onTap: () => setState(() => selected = diet),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    color: selected == diet
                        ? Colors.greenAccent
                        : Color(0xFFF7F6FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diet,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        descriptions[diet]!,
                        style: TextStyle(
                          color: selected == diet
                              ? Colors.white70
                              : Colors.black87,
                          fontSize: 14,
                        ),
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
