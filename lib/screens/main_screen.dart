import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kai/screens/dashboard_screen.dart';
import 'package:kai/screens/meals_plan_screen.dart';
import 'package:kai/screens/profile_screen.dart';
import 'package:kai/services/auth_service.dart';
import 'package:kai/services/subscription_service.dart';

import 'landing_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  bool _isEntitled = true;
  bool _checkingEntitlement = true;
  final SubscriptionService _subscription = SubscriptionService.instance;
  StreamSubscription<bool>? _entitlementSub;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const MealPlanScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _screens.length - 1);
    _initSubscriptionGate();
  }

  Future<void> _initSubscriptionGate() async {
    await _subscription.initListeners();
    _entitlementSub = _subscription.entitlementStream.listen((entitled) {
      if (!mounted) return;
      final loggingIn = _subscription.isLoggingIn;
      setState(() {
        print('Entitlement changed: $entitled (loggingIn=$loggingIn)');
        _isEntitled = entitled;
        // Avoid brief flicker: if we are still logging in to RevenueCat and
        // entitlement is false, keep showing the spinner until it settles.
        _checkingEntitlement = loggingIn && !entitled ? true : false;
      });
    });
  }

  Future<void> _refreshEntitlement() async {
    final entitled = await _subscription.isEntitled();
    if (!mounted) return;
    setState(() {
      _isEntitled = entitled;
      _checkingEntitlement = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo-transparent.png',
          height: 25, // Adjust height as needed
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            // Handle menu button press
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () {
              // Handle notifications button press
              _authService
                  .signOut()
                  .then((_) {
                    SubscriptionService.instance.logOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LandingScreen(),
                      ),
                    );
                  })
                  .catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error signing out: $error')),
                    );
                  });
            },
          ),
        ],
      ),
      body: _checkingEntitlement
          ? const Center(child: CircularProgressIndicator())
          : _isEntitled
          ? _screens[_currentIndex]
          : _SubscriptionRequired(
              onSubscribe: () async {
                await _subscription.presentPaywallIfNeeded();
                await _refreshEntitlement();
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        fixedColor: Colors.greenAccent,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Meal Plans',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _SubscriptionRequired extends StatelessWidget {
  const _SubscriptionRequired({required this.onSubscribe});
  final Future<void> Function() onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 72, color: Colors.greenAccent),
          const SizedBox(height: 16),
          const Text(
            'Subscription Required',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Start your free trial to unlock Kai. You can cancel anytime before your trial ends.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: onSubscribe,
              child: const Text('Subscribe / Start Free Trial'),
            ),
          ),
        ],
      ),
    );
  }
}
