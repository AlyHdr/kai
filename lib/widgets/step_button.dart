// lib/widgets/step_button.dart
import 'package:flutter/material.dart';

class StepButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final bool enabled;

  const StepButton({
    super.key,
    required this.onPressed,
    this.label = 'Continue',
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, 60),
          backgroundColor: Colors.greenAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: Text(label, style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
