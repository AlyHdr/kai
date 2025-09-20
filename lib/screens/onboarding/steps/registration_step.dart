// lib/screens/onboarding/steps/registration_step.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String? _error;

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
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
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
              setState(() => _error = null);
              try {
                await widget.onRegister(
                  _fullNameController.text.trim(),
                  _emailController.text.trim(),
                  _passwordController.text.trim(),
                );
              } on FirebaseAuthException catch (e) {
                final message = _mapAuthError(e);
                if (mounted) {
                  setState(() => _error = message);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(message)));
                }
              } catch (e) {
                final message = 'Registration failed: $e';
                if (mounted) {
                  setState(() => _error = message);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(message)));
                }
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
          ),
        ],
      ),
    );
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email sign-in is disabled for this project.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Registration error (${e.code}).';
    }
  }
}
