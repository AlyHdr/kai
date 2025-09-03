// lib/screens/onboarding/steps/registration_step.dart
import 'package:flutter/material.dart';
import '../../../widgets/step_button.dart';

class RegistrationStep extends StatefulWidget {
  final Function(String fullName, String email, String password, bool isTrial)
  onRegister;

  const RegistrationStep({super.key, required this.onRegister});

  @override
  State<RegistrationStep> createState() => _RegistrationStepState();
}

class _RegistrationStepState extends State<RegistrationStep> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  bool isTrial = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePlan(bool trial) {
    setState(() => isTrial = trial);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Text(
            'Create your account',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Start your 3-day free trial or get full access for \$9.99.'),
          SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _togglePlan(true),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isTrial ? Colors.greenAccent : Color(0xFFF7F6FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '3-Day Trial',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => _togglePlan(false),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: !isTrial ? Colors.greenAccent : Color(0xFFF7F6FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '\$9.99 Full Access',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 32),
          TextField(
            controller: _fullNameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person, color: Colors.greenAccent),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(height: 32),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email, color: Colors.greenAccent),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(height: 32),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock, color: Colors.greenAccent),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            obscureText: true,
          ),
          Spacer(),
          StepButton(
            enabled:
                _emailController.text.isNotEmpty &&
                _passwordController.text.isNotEmpty &&
                _fullNameController.text.isNotEmpty,
            label: 'Register',
            onPressed: () => widget.onRegister(
              _fullNameController.text.trim(),
              _emailController.text.trim(),
              _passwordController.text.trim(),
              isTrial,
            ),
          ),
        ],
      ),
    );
  }
}
