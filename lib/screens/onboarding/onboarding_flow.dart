// lib/screens/onboarding/onboarding_flow.dart
import 'package:flutter/material.dart';
import 'package:kai/screens/authentication/verify_email_screen.dart';
import 'package:kai/screens/onboarding/steps/thanking_step.dart';
import 'package:kai/services/auth_service.dart';
import 'package:kai/services/macros_service.dart';
import 'package:kai/services/users_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/onboarding_data.dart';
import 'steps/activity_step.dart';
import 'steps/diet_step.dart';
import 'steps/gender_step.dart';
import 'steps/height_weight_step.dart';
import 'steps/dob_step.dart';
import 'steps/goal_step.dart';
import 'steps/registration_step.dart';
import 'package:kai/screens/main_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  _OnboardingFlowState createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _controller = PageController();
  int _currentStep = 0;
  OnboardingData data = OnboardingData();
  final AuthService _authService = AuthService();
  final UsersService _userService = UsersService();
  final MacrosService _macrosService = MacrosService();
  bool _checkingExisting = true;
  bool _finalizing = false;

  @override
  void initState() {
    super.initState();
    _checkExistingUserAndMaybeSkip();
  }

  Future<void> _checkExistingUserAndMaybeSkip() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final exists = await _userService.userExists(user.uid);
        if (exists) {
          if (!mounted) return;
          // User already onboarded; go to main and clear stack.
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
          );
          return;
        }
      }
    } catch (_) {
      // Ignore and continue onboarding if we cannot determine.
    } finally {
      if (mounted) setState(() => _checkingExisting = false);
    }
  }

  void _nextStep() {
    if (_currentStep < 7) {
      _controller.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      // TODO: Finalize onboarding
      print(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingExisting || _finalizing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _onBackPressed),
        title: LinearProgressIndicator(
          value: (_currentStep + 1) / 8, // Adjust based on number of steps
          backgroundColor: Colors.grey.shade300,
          color: Colors.greenAccent,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [],
      ),
      body: PageView(
        controller: _controller,
        physics: NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentStep = index),
        children: [
          GenderStep(
            selectedGender: data.gender,
            onNext: (gender) {
              setState(() => data.gender = gender);
              _nextStep();
            },
          ),
          ActivityLevelStep(
            selectedLevel: data.activityLevel,
            onNext: (level) {
              setState(() => data.activityLevel = level);
              _nextStep();
            },
          ),
          HeightWeightStep(
            initialHeight: data.heightCm ?? 170,
            initialWeight: data.weightKg ?? 70,
            onNext: (height, weight) {
              setState(() {
                data.heightCm = height;
                data.weightKg = weight;
              });
              _nextStep();
            },
          ),
          DateOfBirthStep(
            initialDate: data.dateOfBirth,
            onNext: (dob) {
              setState(() => data.dateOfBirth = dob);
              _nextStep();
            },
          ),
          GoalStep(
            selectedGoal: data.goal,
            onNext: (goal) {
              setState(() => data.goal = goal);
              _nextStep();
            },
          ),
          DietPreferenceStep(
            selectedDiet: data.dietPreference,
            onNext: (diet) {
              setState(() => data.dietPreference = diet);
              _nextStep();
            },
          ),
          ThankingStep(
            onNext: () async {
              // If user already authenticated (e.g., via social), finalize now and skip registration.
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await _finalizeOnboardingForUser(user);
              } else {
                _nextStep();
              }
            },
          ),
          RegistrationStep(
            onRegister: (fullName, email, password) async {
              try {
                final userCredentials = await _authService.signUp(
                  email,
                  password,
                );
                final user = userCredentials.user;
                if (user == null) throw Exception('User UID is null');
                // Centralized finalize for email/password; send verification email.
                await _finalizeOnboardingForUser(
                  user,
                  fullName: fullName,
                  sendVerificationIfNeeded: true,
                  showErrors: false,
                  rethrowErrors: true,
                );
              } catch (error) {
                // Allow RegistrationStep to surface the error to the user
                rethrow;
              }
            },
            onSocialRegister: (user) async {
              try {
                await _finalizeOnboardingForUser(
                  user,
                  showErrors: false,
                  rethrowErrors: true,
                );
              } catch (error) {
                rethrow;
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onBackPressed() async {
    if (_currentStep > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      return;
    }
    // At first step: if user is authenticated (social sign-in path), sign out
    // so LandingScreen rebuilds to the logged-out landing UI, no pop needed.
    if (FirebaseAuth.instance.currentUser != null) {
      final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Leave onboarding?'),
              content: const Text(
                'You are signed in. Going back will sign you out and return to the start.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ) ??
          false;
      if (confirm) {
        try {
          await _authService.signOut();
        } catch (_) {}
      }
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _finalizeOnboardingForUser(
    User user, {
    String? fullName,
    bool sendVerificationIfNeeded = false,
    bool showErrors = true,
    bool rethrowErrors = false,
  }) async {
    try {
      setState(() => _finalizing = true);
      final uid = user.uid;
      if (uid.isEmpty) throw Exception('User UID is null');

      // Resolve full name precedence: explicit > collected > provider displayName
      final resolvedName = (fullName != null && fullName.trim().isNotEmpty)
          ? fullName.trim()
          : (data.fullName ?? user.displayName);
      data.fullName = resolvedName;

      await _userService.createUser(uid, data);
      await _macrosService.generateMacros(data, uid);

      if (!mounted) return;
      if (user.emailVerified) {
        // Go straight to main; clear stack so back does not return to onboarding.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      } else {
        if (sendVerificationIfNeeded) {
          await user.sendEmailVerification();
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyEmailScreen(user: user),
          ),
        );
      }
    } catch (e) {
      if (showErrors && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to finish onboarding: $e')),
        );
      }
      if (rethrowErrors) rethrow;
    } finally {
      if (mounted) setState(() => _finalizing = false);
    }
  }
}
