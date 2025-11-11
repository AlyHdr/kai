// screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:kai/screens/landing_screen.dart';
import 'package:kai/screens/authentication/verify_email_screen.dart';
import 'package:kai/services/auth_service.dart';
import 'package:kai/services/auth_flow_service.dart';
import 'package:kai/widgets/social_auth_buttons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  String? _error;
  bool _sendingReset = false;
  bool _busy = false;

  void _login() async {
    try {
      setState(() => _busy = true);
      var userCredentials = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // Unify routing: verify email -> onboarding -> main
      await AuthFlowService.handlePostSignInRouting(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
      }
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    try {
      setState(() => _busy = true);
      await _authService.signInWithGoogle();
      if (!mounted) return;
      await AuthFlowService.handlePostSignInRouting(context);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Google sign-in failed: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Google sign-in failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loginWithApple() async {
    try {
      setState(() => _busy = true);
      await _authService.signInWithApple();
      if (!mounted) return;
      await AuthFlowService.handlePostSignInRouting(context);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Apple sign-in failed: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Apple sign-in failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _promptPasswordReset() async {
    final controller = TextEditingController(
      text: _emailController.text.trim(),
    );
    String? localError;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset password'),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your account email to receive a reset link.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'email@example.com',
                errorText: localError,
              ),
              onChanged: (_) {
                if (localError != null) {
                  setState(() {});
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
            ),
            child: const Text('Send link'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final email = controller.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your email.')));
      return;
    }

    try {
      setState(() => _sendingReset = true);
      await _authService.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Reset link sent to $email')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reset email: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingReset = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo-only.png', height: 100),
            const SizedBox(height: 16),
            const Text(
              'Welcome back',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.email, color: Colors.greenAccent),
                hintText: 'Enter your email',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.lock, color: Colors.greenAccent),
                hintText: 'Enter your password',
              ),
              obscureText: true,
            ),
            // const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _sendingReset ? null : _promptPasswordReset,
                child: _sendingReset
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Forgot password?'),
              ),
            ),
            // const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _busy ? null : _login,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                backgroundColor: Colors.greenAccent,
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: Text('Sign in'),
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
            const SizedBox(height: 12),
            // Social sign-in buttons stacked vertically
            LayoutBuilder(
              builder: (context, constraints) {
                final showApple =
                    Theme.of(context).platform == TargetPlatform.iOS ||
                    Theme.of(context).platform == TargetPlatform.macOS;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _loginWithGoogle,
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
                      label: const Text('Sign in with Google'),
                    ),
                    if (showApple) const SizedBox(height: 12),
                    if (showApple)
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _loginWithApple,
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
                        label: const Text('Sign in with Apple'),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const Spacer(),
            // Register prompt pinned to bottom
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Don\'t have an account?'),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LandingScreen()),
                    );
                  },
                  child: const Text('Register'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
