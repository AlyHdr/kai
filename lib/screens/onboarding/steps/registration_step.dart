// lib/screens/onboarding/steps/registration_step.dart
import 'package:flutter/material.dart';
import '../../../widgets/step_button.dart';

class RegistrationStep extends StatefulWidget {
  final Future<void> Function(String fullName, String email, String password)
      onRegister;

  const RegistrationStep({super.key, required this.onRegister});

  @override
  State<RegistrationStep> createState() => _RegistrationStepState();
}

class _RegistrationStepState extends State<RegistrationStep> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
          Text('Start your 7-day free trial. You can cancel anytime.'),
          SizedBox(height: 32),
          TextField(
            controller: _fullNameController,
            onChanged: (_) => setState(() {}),
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
            onChanged: (_) => setState(() {}),
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
            onChanged: (_) => setState(() {}),
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
            busy: _loading,
            label: _loading ? 'Registering...' : 'Register',
            onPressed: () async {
              setState(() => _loading = true);
              try {
                await widget.onRegister(
                  _fullNameController.text.trim(),
                  _emailController.text.trim(),
                  _passwordController.text.trim(),
                );
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
          ),
        ],
      ),
    );
  }
}
