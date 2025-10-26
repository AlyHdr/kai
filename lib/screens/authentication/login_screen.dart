// screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:kai/screens/landing_screen.dart';
import 'package:kai/screens/authentication/verify_email_screen.dart';
import 'package:kai/services/auth_service.dart';
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

      final user = userCredentials.user;
      if (user != null && !user.emailVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyEmailScreen(user: user),
          ),
        );
      } else {
        print('User logged in: ${user?.email}');
        // Return to the LandingScreen; it will render MainScreen via auth stream.
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      print('Login error: $e');
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    try {
      setState(() => _busy = true);
      final cred = await _authService.signInWithGoogle();
      final user = cred.user;
      if (user != null && !user.emailVerified) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyEmailScreen(user: user),
          ),
        );
      } else {
        if (mounted) Navigator.of(context).pop();
      }
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
      final cred = await _authService.signInWithApple();
      final user = cred.user;
      if (user != null && !user.emailVerified) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyEmailScreen(user: user),
          ),
        );
      } else {
        if (mounted) Navigator.of(context).pop();
      }
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
            Image.asset('assets/images/logo-transparent.png', height: 50),
            SizedBox(height: 32),
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
            SizedBox(height: 24),
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
              child: Text('Login'),
            ),
            TextButton(
              onPressed: _sendingReset ? null : _promptPasswordReset,
              child: _sendingReset
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Forgot password?'),
            ),
            const SizedBox(height: 8),
            // Divider with centered label
            Row(
              children: const [
                Expanded(child: Divider()),
                SizedBox(width: 8),
                Text('Or Login with'),
                SizedBox(width: 8),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),
            // Icon-only social buttons on one row
            LayoutBuilder(
              builder: (context, constraints) {
                final showApple =
                    Theme.of(context).platform == TargetPlatform.iOS ||
                    Theme.of(context).platform == TargetPlatform.macOS;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _IconOnlyButton(
                      onPressed: _busy ? null : _loginWithGoogle,
                      background: Colors.white,
                      border: Colors.black12,
                      icon: const FaIcon(
                        FontAwesomeIcons.google,
                        color: Color(0xFF4285F4),
                      ),
                      tooltip: 'Continue with Google',
                    ),
                    const SizedBox(width: 16),
                    if (showApple)
                      _IconOnlyButton(
                        onPressed: _busy ? null : _loginWithApple,
                        background: Colors.black,
                        border: Colors.black,
                        icon: const FaIcon(
                          FontAwesomeIcons.apple,
                          color: Colors.white,
                        ),
                        tooltip: 'Continue with Apple',
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            // Move register prompt to the bottom
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
