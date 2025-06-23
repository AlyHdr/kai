import 'package:flutter/material.dart';
import '../../../widgets/step_button.dart';

class GoalStep extends StatefulWidget {
  final String? selectedGoal;
  final Function(String goal) onNext;

  const GoalStep({super.key, this.selectedGoal, required this.onNext});

  @override
  State<GoalStep> createState() => _GoalStepState();
}

class _GoalStepState extends State<GoalStep> {
  final List<String> goals = ['Lose Weight', 'Build Muscle', 'Maintain'];

  final Map<String, String> descriptions = {
    'Lose Weight': 'Focus on fat loss and calorie control.',
    'Build Muscle': 'Support muscle growth with nutrition and training.',
    'Maintain': 'Sustain your current physique and health.',
  };

  String? selected;

  @override
  void initState() {
    super.initState();
    selected = widget.selectedGoal;
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
            'What is your main goal?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('This helps us personalize your program.'),
          SizedBox(height: 32),
          ...goals.map(
            (goal) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GestureDetector(
                onTap: () => setState(() => selected = goal),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    color: selected == goal
                        ? Colors.greenAccent
                        : Color(0xFFF7F6FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        descriptions[goal]!,
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
