import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:kai/screens/landing_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
  await initPlatformState();
}

Future<void> initPlatformState() async {
  await Purchases.setLogLevel(LogLevel.debug);

  PurchasesConfiguration? configuration;
  // Inject keys via --dart-define to avoid committing them
  const rcAndroidKey = String.fromEnvironment('RC_ANDROID_SDK_KEY');
  const rciOSKey = String.fromEnvironment('RC_IOS_SDK_KEY');

  if (Platform.isAndroid && rcAndroidKey.isNotEmpty) {
    configuration = PurchasesConfiguration(rcAndroidKey);
  } else if (Platform.isIOS && rciOSKey.isNotEmpty) {
    configuration = PurchasesConfiguration(rciOSKey);
  }
  if (configuration != null) {
    await Purchases.configure(configuration);
    final paywallResult = await RevenueCatUI.presentPaywallIfNeeded('premium');
    print('Paywall presented: $paywallResult');
  } else {
    print('Unsupported platform for Purchases');
  }
}
// Future<void> testHello() async {
//   final fns = FirebaseFunctions.instanceFor(region: 'us-central1');
//   final hello = fns.httpsCallable('print_hello');

//   try {
//     final res = await hello.call({'name': 'Kai'});
//     print('print_hello -> ${res.data}');
//   } on FirebaseFunctionsException catch (e) {
//     // This gives you the real server error (code/message/details)
//     print(
//       'FunctionsException code=${e.code} message=${e.message} details=${e.details}',
//     );
//   } catch (e, st) {
//     print('Unknown error: $e\n$st');
//   }
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kai',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
      ),
      home: const LandingScreen(),
    );
  }
}
