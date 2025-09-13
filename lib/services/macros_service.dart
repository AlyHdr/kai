import 'package:cloud_functions/cloud_functions.dart';
import 'package:kai/models/onboarding_data.dart';
import 'package:kai/services/users_service.dart';

class MacrosService {
  Future<void> generateMacros(OnboardingData data, String uid) async {
    // if (const bool.fromEnvironment('dart.vm.product') == false) {
    //   FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
    // }
    final result = await FirebaseFunctions.instance
        .httpsCallable('generate_macros')
        .call(data.toMap());

    final macrosData = result.data;
    print("Macros: $macrosData");
    if (macrosData is Map<String, dynamic>) {
      // Normalize key naming: ensure 'proteins' exists for targets
      if (!macrosData.containsKey('proteins') && macrosData.containsKey('protein')) {
        macrosData['proteins'] = macrosData['protein'];
      }
      // Save the generated macros to the user's document
      await UsersService().updateMacros(uid, macrosData);
    } else {
      throw Exception('Invalid macros data received');
    }
  }
}
