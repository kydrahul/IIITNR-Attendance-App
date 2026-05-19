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

  // Returns true ONLY when biometrics are actually ENROLLED on the device.
  // canCheckBiometrics = biometric hardware present (not necessarily enrolled).
  // getAvailableBiometrics() = list of enrolled biometrics — this is the
  // correct check to avoid calling authenticate() on a device that has
  // biometric hardware but no fingerprints/face set up (which causes
  // authenticate() to silently return false or show a failed prompt).
  Future<bool> checkBiometrics() async {
    try {
      final available = await auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } on PlatformException catch (e) {
      debugPrint("Error checking enrolled biometrics: $e");
      return false;
    }
  }

  // Static flag to prevent lifecycle loops
  static bool isAuthenticating = false;
  static DateTime? lastAuthTime;

  // Authenticate user
  Future<bool> authenticate() async {
    bool authenticated = false;
    try {
      isAuthenticating = true; // Set flag
      // stickyAuth:false → if the app is backgrounded during auth,
      // the prompt is dismissed and returns false immediately (no hang).
      // stickyAuth:true causes an indefinite hang on Android 14 OEM devices
      // (OnePlus/ColorOS) due to a conflict with the predictive-back API.
      // The 30-second timeout is an additional safety net.
      authenticated = await auth
          .authenticate(
            localizedReason: 'Please authenticate to access the app',
            options: const AuthenticationOptions(
              stickyAuth: false,
              biometricOnly: false,
            ),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('BiometricService: authenticate() timed out — returning false');
              return false;
            },
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
