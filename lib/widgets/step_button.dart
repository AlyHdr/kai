// lib/widgets/step_button.dart
import 'package:flutter/material.dart';

class StepButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final bool enabled;
  final bool busy;

  const StepButton({
    super.key,
    required this.onPressed,
    this.label = 'Continue',
    this.enabled = true,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: ElevatedButton(
        onPressed: enabled && !busy ? onPressed : null,
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, 60),
          backgroundColor: Colors.greenAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: busy
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(label, style: TextStyle(fontSize: 16)),
                ],
              )
            : Text(label, style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
