// lib/screens/onboarding/steps/registration_step.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kai/services/auth_service.dart';
import '../../../widgets/step_button.dart';

class RegistrationStep extends StatefulWidget {
  final Future<void> Function(String fullName, String email, String password)
  onRegister;
  final Future<void> Function(User user) onSocialRegister;

  const RegistrationStep({
    super.key,
    required this.onRegister,
    required this.onSocialRegister,
  });

  @override
  State<RegistrationStep> createState() => _RegistrationStepState();
}

class _RegistrationStepState extends State<RegistrationStep> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _busySocial = false;
  final _authService = AuthService();
  bool _autoCompleting = false;

  @override
  void initState() {
    super.initState();
    _maybeFinalizeIfAlreadySignedIn();
  }

  Future<void> _maybeFinalizeIfAlreadySignedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      setState(() {
        _autoCompleting = true;
        _busySocial = true;
        _error = null;
      });
      // User is already authenticated (likely via social from login). Finalize onboarding.
      await widget.onSocialRegister(user);
      // Navigation is handled by the parent flow.
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed finalizing account: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed finalizing account: $e')));
    } finally {
      if (mounted)
        setState(() {
          _autoCompleting = false;
          _busySocial = false;
        });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_autoCompleting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Preparing your account…'),
          ],
        ),
      );
    }
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
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          StepButton(
            enabled: true,
            busy: _loading,
            label: _loading ? 'Registering...' : 'Register',
            onPressed: () async {
              // Require all fields before proceeding
              if (_fullNameController.text.trim().isEmpty ||
                  _emailController.text.trim().isEmpty ||
                  _passwordController.text.trim().isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please fill your full name, email, and password.',
                      ),
                    ),
                  );
                }
                return;
              }

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
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                }
              } catch (e) {
                final message = 'Registration failed: $e';
                if (mounted) {
                  setState(() => _error = message);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                }
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
          ),
          const SizedBox(height: 16),
          // Divider with centered label
          Row(
            children: const [
              Expanded(child: Divider()),
              SizedBox(width: 8),
              Text('or'),
              SizedBox(width: 8),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: _busySocial
                    ? null
                    : () => _handleSocialSignUp(provider: 'google'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.black12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                icon: const FaIcon(
                  FontAwesomeIcons.google,
                  color: Color(0xFF4285F4),
                ),
                label: const Text('Sign up with Google'),
              ),
              if (Theme.of(context).platform == TargetPlatform.iOS ||
                  Theme.of(context).platform == TargetPlatform.macOS)
                const SizedBox(height: 12),
              if (Theme.of(context).platform == TargetPlatform.iOS ||
                  Theme.of(context).platform == TargetPlatform.macOS)
                OutlinedButton.icon(
                  onPressed: _busySocial
                      ? null
                      : () => _handleSocialSignUp(provider: 'apple'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Colors.black12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  icon: const FaIcon(
                    FontAwesomeIcons.apple,
                    color: Colors.black,
                  ),
                  label: const Text('Sign up with Apple'),
                ),
            ],
          ),
          const Spacer(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already have an account?'),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Login Now'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleSocialSignUp({required String provider}) async {
    try {
      setState(() {
        _busySocial = true;
        _error = null;
      });
      UserCredential cred;
      if (provider == 'google') {
        cred = await _authService.signInWithGoogle();
      } else if (provider == 'apple') {
        cred = await _authService.signInWithApple();
      } else {
        throw Exception('Unsupported provider: $provider');
      }

      final user = cred.user;
      if (user == null) throw Exception('Authentication failed.');

      // Delegate user creation + macros generation to the parent flow
      await widget.onSocialRegister(user);

      // Navigation handled by parent flow.
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Sign up failed: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign up failed: $e')));
    } finally {
      if (mounted) setState(() => _busySocial = false);
    }
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

// Removed legacy _IconOnlyButton in favor of labeled OutlinedButtons
