import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:kai/screens/landing_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initPlatformState();
  runApp(const MyApp());
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      configuration.appUserID = uid;
    }
    await Purchases.configure(configuration);
  } else {
    // Helpful diagnostics when keys are missing or not injected
    if (Platform.isAndroid && rcAndroidKey.isEmpty) {
      print('[Purchases] Missing RC_ANDROID_SDK_KEY. Pass via --dart-define or env.json');
    } else if (Platform.isIOS && rciOSKey.isEmpty) {
      print('[Purchases] Missing RC_IOS_SDK_KEY. Pass via --dart-define or env.json');
    } else {
      print('Unsupported platform for Purchases');
    }
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
