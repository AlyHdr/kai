import 'package:flutter/material.dart';
import '../../../widgets/step_button.dart';

class DateOfBirthStep extends StatefulWidget {
  final DateTime? initialDate;
  final Function(DateTime dob) onNext;

  const DateOfBirthStep({super.key, this.initialDate, required this.onNext});

  @override
  State<DateOfBirthStep> createState() => _DateOfBirthStepState();
}

class _DateOfBirthStepState extends State<DateOfBirthStep> {
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 100);
    final lastDate = DateTime(now.year - 13); // assume user must be at least 13

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(now.year - 20),
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
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
            'What is your date of birth?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('This helps me personalize your experience.'),
          SizedBox(height: 32),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: Color(0xFFF7F6FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedDate != null
                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : 'Select your birth date',
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                  Icon(Icons.calendar_today, color: Colors.grey),
                ],
              ),
            ),
          ),
          Spacer(),
          StepButton(
            enabled: selectedDate != null,
            onPressed: () => widget.onNext(selectedDate!),
          ),
        ],
      ),
    );
  }
}
