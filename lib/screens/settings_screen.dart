import 'package:flutter/material.dart';
import 'package:kai/screens/landing_screen.dart';
import 'package:kai/services/subscription_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _deleting = false;

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> ref, {
    int batchSize = 50,
  }) async {
    while (true) {
      final snap = await ref.limit(batchSize).get();
      if (snap.docs.isEmpty) break;
      final batch = FirebaseFirestore.instance.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
      // Small delay to avoid aggressive loops
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<bool> _reauthenticateIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final email = user.email;
    // If the user signed up with email/password, prompt for password to ensure recent login.
    final usesPasswordProvider = user.providerData.any(
      (p) => p.providerId == 'password' && (email != null),
    );
    if (!usesPasswordProvider) return true; // skip for non-password providers

    String password = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Re-authentication required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please enter your password to confirm account deletion.',
            ),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              obscureText: true,
              onChanged: (v) => password = v,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;

    try {
      final cred = EmailAuthProvider.credential(
        email: email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Re-authentication failed: $e')));
      }
      return false;
    }
  }

  Future<void> _performDeleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    // Confirm destructive action
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently delete your account and all your data (plans, intake, profile). '
          'This does not cancel your App Store/Play subscription; manage that from Subscription settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    // Ensure recent login
    final ok = await _reauthenticateIfNeeded();
    if (!ok) return;

    setState(() => _deleting = true);
    try {
      final fs = FirebaseFirestore.instance;

      // Delete Firestore data first while user is still authenticated
      final userDoc = fs.collection('users').doc(uid);
      await _deleteCollection(userDoc.collection('plans'));
      await _deleteCollection(userDoc.collection('intake'));
      await userDoc.delete();

      // Log out from RevenueCat (best effort)
      await SubscriptionService.instance.logOut();

      // Delete the auth user
      await user.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted. Goodbye!')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete account: $e')));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const termsUrl = String.fromEnvironment('TERMS_URL');
    const privacyUrl = String.fromEnvironment('PRIVACY_URL');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Subscription',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                title: const Text('Restore Purchases'),
                trailing: const Icon(Icons.refresh),
                onTap: () async {
                  await SubscriptionService.instance.restorePurchases();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Purchases restored (if any).'),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('Manage Subscription'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () async {
                  await SubscriptionService.instance.openManageSubscriptions();
                },
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Legal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (privacyUrl.isNotEmpty)
                ListTile(
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () async {
                    final uri = Uri.parse(privacyUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              if (termsUrl.isNotEmpty)
                ListTile(
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () async {
                    final uri = Uri.parse(termsUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),

              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Danger Zone',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _deleting ? null : _performDeleteAccount,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Delete Account'),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
          if (_deleting)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        'Deleting account…',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
