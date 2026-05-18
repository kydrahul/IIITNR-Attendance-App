import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication auth = LocalAuthentication();

  // Check if device supports biometrics
  Future<bool> isDeviceSupported() async {
    bool isSupported = false;
    try {
      isSupported = await auth.isDeviceSupported();
    } on PlatformException catch (e) {
      debugPrint("Error checking device support: $e");
    }
    return isSupported;
  }

  // Check if user has biometrics enrolled (fingerprint/face)
  Future<bool> checkBiometrics() async {
    bool canCheckBiometrics = false;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      debugPrint("Error checking biometrics: $e");
    }
    return canCheckBiometrics;
  }

  // Static flag to prevent lifecycle loops
  static bool isAuthenticating = false;
  static DateTime? lastAuthTime;

  // Authenticate user
  Future<bool> authenticate() async {
    bool authenticated = false;
    try {
      isAuthenticating = true; // Set flag
      authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (authenticated) {
        lastAuthTime = DateTime.now();
      }
    } on PlatformException catch (e) {
      debugPrint("Error authenticating: $e");
      // If error (e.g. LockedOut), return false
    } finally {
      isAuthenticating = false; // Reset flag
    }
    return authenticated;
  }
}
