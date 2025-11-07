import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kai/screens/authentication/verify_email_screen.dart';
import 'package:kai/services/users_service.dart';

/// Centralizes post-sign-in decisions: verify email, require onboarding, or go to main.
class AuthFlowService {
  AuthFlowService._();

  static Future<void> handlePostSignInRouting(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // If email not verified (common for email/password), go to verification.
    if (!user.emailVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => VerifyEmailScreen(user: user)),
      );
      return;
    }

    // Check if user has completed onboarding (has user document).
    final hasUserDoc = await UsersService().currentUserExists();
    if (!hasUserDoc) {
      // Defer to LandingScreen to render OnboardingFlow to avoid race with auth stream
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    // If verified and onboarded, return to previous (Landing will show Main).
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}
