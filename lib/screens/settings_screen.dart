import 'package:flutter/material.dart';
import 'package:kai/services/subscription_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
      body: ListView(
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
                  const SnackBar(content: Text('Purchases restored (if any).')),
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
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
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
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

