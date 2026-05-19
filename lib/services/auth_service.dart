import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'faculty/faculty_api_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  // encryptedSharedPreferences avoids the Android Keystore user-auth
  // requirement — devices without biometrics/PIN can still read/write tokens.
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Store ID token
      final idToken = await userCredential.user?.getIdToken();
      if (idToken != null) {
        await _storage.write(key: 'auth_token', value: idToken);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Google Sign-In FirebaseAuthException [${e.code}]: ${e.message}');
      // Map specific Firebase error codes to user-friendly messages and rethrow
      // so the calling screen can display them.
      final message = _mapFirebaseAuthError(e.code);
      throw Exception(message);
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Maps Firebase Auth error codes to human-readable messages.
  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but a different sign-in method.';
      case 'invalid-credential':
      case 'invalid-verification-code':
        return 'The sign-in credential is invalid. Please try again.';
      case 'user-disabled':
        return 'Your account has been disabled. Contact your administrator.';
      case 'too-many-requests':
        return 'Too many sign-in attempts. Please wait a moment and try again.';
      case 'operation-not-allowed':
        return 'Google Sign-In is not enabled. Contact your administrator.';
      case 'user-not-found':
        return 'No account found for this email. Please register first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      default:
        return 'Sign-in failed ($code). Please try again.';
    }
  }

  // Get stored token
  Future<String?> getToken() async {
    try {
      // Try to get fresh token from current user
      final user = _auth.currentUser;
      if (user != null) {
        final token = await user.getIdToken(true);
        await _storage.write(key: 'auth_token', value: token);
        return token;
      }

      // Fallback to stored token
      return await _storage.read(key: 'auth_token');
    } on FirebaseAuthException catch (e) {
      // Token refresh failed (e.g. user-token-expired, network-request-failed)
      debugPrint('getToken FirebaseAuthException [${e.code}]: ${e.message}');
      // Return stored token as fallback — api_client will handle 401 if it is stale.
      return await _storage.read(key: 'auth_token');
    } catch (e) {
      debugPrint('getToken Error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    // Clear faculty cache (in-memory + SharedPreferences)
    try {
      await FacultyApiService().clearCache();
    } catch (_) {
      // Best-effort — don't block sign-out if cache clear fails
    }

    // Clear student cache (in-memory + SharedPreferences)
    try {
      await ApiService().clearCache();
    } catch (_) {}

    // Clear all remaining SharedPreferences keys (belt-and-suspenders)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}

    // Sign out from Google and Firebase — each wrapped individually so a
    // failure in one step does not prevent the others from running.
    try {
      await _googleSignIn.signOut();
    } on FirebaseAuthException catch (e) {
      debugPrint('signOut: Google sign-out FirebaseAuthException [${e.code}]: ${e.message}');
    } catch (e) {
      debugPrint('signOut: Google sign-out error: $e');
    }

    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      debugPrint('signOut: Firebase sign-out FirebaseAuthException [${e.code}]: ${e.message}');
    } catch (e) {
      debugPrint('signOut: Firebase sign-out error: $e');
    }

    try {
      await _storage.delete(key: 'auth_token');
      await _storage.delete(key: 'user_role');
    } catch (e) {
      debugPrint('signOut: Secure storage delete error: $e');
    }
  }

  // Set user role (student or faculty)
  Future<void> setUserRole(String role) async {
    await _storage.write(key: 'user_role', value: role);
  }

  // Get user role
  Future<String?> getUserRole() async {
    return await _storage.read(key: 'user_role');
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
