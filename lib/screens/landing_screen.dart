import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kai/screens/authentication/login_screen.dart';
import 'package:kai/screens/authentication/verify_email_screen.dart';
import 'package:kai/screens/main_screen.dart';
import 'package:lottie/lottie.dart';
import 'onboarding/onboarding_flow.dart';
import 'package:kai/services/subscription_service.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          final user = snapshot.data!;
          // Gate the app by email verification status
          if (user.emailVerified) {
            // Ensure RevenueCat is identified with Firebase UID only when verified
            final uid = user.uid;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              SubscriptionService.instance.logIn(uid);
            });
            return const MainScreen();
          } else {
            // Keep RevenueCat logged out for unverified accounts
            WidgetsBinding.instance.addPostFrameCallback((_) {
              SubscriptionService.instance.logOut();
            });
            return VerifyEmailScreen(user: user);
          }
        } else {
          // When logged out, ensure RevenueCat uses anonymous id
          WidgetsBinding.instance.addPostFrameCallback((_) {
            SubscriptionService.instance.logOut();
          });
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/logo-only.png', height: 200),

                    const SizedBox(height: 20),
                    const Text(
                      'Hello I\'m Kai!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Your personal nutrition and fitness assistant',
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Colors.greenAccent,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OnboardingFlow(),
                          ),
                        );
                      },
                      child: const Text('Get Started'),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account?'),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(),
                              ),
                            );
                          },
                          child: const Text('Sign In'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
