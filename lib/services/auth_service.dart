import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'faculty/faculty_api_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

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
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
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
    } catch (e) {
      debugPrint('Get Token Error: $e');
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

    // Clear student cache from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}

    await _googleSignIn.signOut();
    await _auth.signOut();
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_role');
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
