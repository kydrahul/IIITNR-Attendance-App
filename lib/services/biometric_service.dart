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

  /// Authenticate user.
  /// Returns:
  ///   true  — authenticated successfully
  ///   false — user cancelled / failed (show retry dialog)
  ///   null  — hardware unavailable / not enrolled (skip gate silently)
  Future<bool?> authenticate() async {
    try {
      isAuthenticating = true;
      final result = await auth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (result) lastAuthTime = DateTime.now();
      return result;
    } on PlatformException catch (e) {
      debugPrint("Error authenticating: $e");
      // NotAvailable / NotEnrolled / PasscodeNotSet — skip gate
      final skipCodes = [
        'NotAvailable',
        'NotEnrolled',
        'PasscodeNotSet',
        'otherOperatingSystem',
      ];
      if (skipCodes.any((c) => e.code.contains(c))) return null;
      return false; // other errors: show retry
    } finally {
      isAuthenticating = false;
    }
  }
}
