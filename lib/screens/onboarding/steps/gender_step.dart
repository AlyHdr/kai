// lib/screens/onboarding/steps/gender_step.dart
import 'package:flutter/material.dart';
import '../../../widgets/step_button.dart';

class GenderStep extends StatefulWidget {
  final String? selectedGender;
  final Function(String gender) onNext;

  const GenderStep({super.key, this.selectedGender, required this.onNext});

  @override
  State<GenderStep> createState() => _GenderStepState();
}

class _GenderStepState extends State<GenderStep> {
  final List<String> genders = ['Male', 'Female', 'Other'];
  String? selected;

  @override
  void initState() {
    super.initState();
    selected = widget.selectedGender;
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
            'Choose your Gender',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('This will be used to calibrate your custom plan.'),
          SizedBox(height: 32),
          ...genders.map(
            (gender) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GestureDetector(
                onTap: () => setState(() => selected = gender),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: selected == gender
                        ? Colors.greenAccent
                        : Color(0xFFF7F6FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      gender,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
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
