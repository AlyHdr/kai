// lib/screens/onboarding/steps/registration_step.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kai/services/auth_service.dart';
import '../../authentication/verify_email_screen.dart';
import '../../../models/onboarding_data.dart';
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
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          // Divider with centered label
          Row(
            children: const [
              Expanded(child: Divider()),
              SizedBox(width: 8),
              Text('Or Sign up with'),
              SizedBox(width: 8),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _IconOnlyButton(
                onPressed: _busySocial
                    ? null
                    : () => _handleSocialSignUp(provider: 'google'),
                background: Colors.white,
                border: Colors.black12,
                icon: const FaIcon(
                  FontAwesomeIcons.google,
                  color: Color(0xFF4285F4),
                ),
                tooltip: 'Continue with Google',
              ),
              const SizedBox(width: 16),
              if (Theme.of(context).platform == TargetPlatform.iOS ||
                  Theme.of(context).platform == TargetPlatform.macOS)
                _IconOnlyButton(
                  onPressed: _busySocial
                      ? null
                      : () => _handleSocialSignUp(provider: 'apple'),
                  background: Colors.black,
                  border: Colors.black,
                  icon: const FaIcon(
                    FontAwesomeIcons.apple,
                    color: Colors.white,
                  ),
                  tooltip: 'Continue with Apple',
                ),
            ],
          ),
          const Spacer(),
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

      if (!mounted) return;
      if (user.emailVerified) {
        // Pop back to root; LandingScreen will transition to MainScreen.
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => VerifyEmailScreen(user: user)),
        );
      }
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

class _IconOnlyButton extends StatelessWidget {
  const _IconOnlyButton({
    required this.onPressed,
    required this.icon,
    required this.background,
    required this.border,
    required this.tooltip,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final Color background;
  final Color border;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          side: BorderSide(color: border),
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(14),
        ),
        child: icon,
      ),
    );
  }
}
