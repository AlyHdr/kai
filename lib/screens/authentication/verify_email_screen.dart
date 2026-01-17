// lib/screens/verify_email_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kai/screens/main_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final User user;

  const VerifyEmailScreen({super.key, required this.user});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _emailSent = false;
  bool _isChecking = false;

  Future<void> _sendVerificationEmail() async {
    try {
      await widget.user.sendEmailVerification();
      setState(() => _emailSent = true);
    } catch (e) {
      print('Error sending verification email: $e');
    }
  }

  Future<void> _checkEmailVerified() async {
    setState(() => _isChecking = true);
    await widget.user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (refreshedUser != null && refreshedUser.emailVerified) {
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Email verified successfully!')));
      // Return to the LandingScreen; it will render MainScreen via auth stream.
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else {
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Email is still not verified.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email_outlined, size: 80, color: Colors.greenAccent),
            SizedBox(height: 24),
            Text(
              'Verify Your Email',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'I\'ve sent a verification link to your email. Please check your inbox.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isChecking ? null : _checkEmailVerified,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.greenAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              child: _isChecking
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('I verified my email'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Didn\'t receive it?'),
                TextButton(
                  onPressed: _emailSent ? null : _sendVerificationEmail,
                  child: Text('Resend Email'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
