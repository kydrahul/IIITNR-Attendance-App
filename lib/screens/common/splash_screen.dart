import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/biometric_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate({bool isRetry = false}) async {
    // Artificial delay for splash effect (skip on retry)
    if (!isRetry) await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // ── 30-second hard cap so the spinner never hangs forever ──────────────
    try {
      await _doAuthCheck().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException(
            'Connection timed out. Please check your internet and try again.'),
      );
    } on TimeoutException catch (e) {
      if (mounted) {
        _showConnectionError(e.message ?? 'Connection timed out.');
      }
    } catch (e) {
      if (mounted) {
        _showConnectionError(e.toString().replaceAll('Exception:', '').trim());
      }
    }
  }

  Future<void> _doAuthCheck() async {
    if (!mounted) return;

    final user = _authService.currentUser;

    if (user == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // User is authenticated, check if profile exists
    final role = await _authService.getUserRole();

    if (role == 'faculty') {
      // Skip profile check/biometrics for faculty auto-login
      if (mounted) Navigator.pushReplacementNamed(context, '/faculty-home');
      return;
    }

    // For both students and interns, check profile and biometrics.
    // Profile-not-found is a valid routing signal, not an error; handle it here.
    // Any other exception (network, 500, timeout) is re-thrown so the outer
    // timeout/catch in _checkAuthAndNavigate can surface it to the user.
    try {
      await _apiService.getProfile(checkProfileExists: true);
    } catch (e) {
      if (e.toString().contains('Profile not found')) {
        if (mounted) {
          if (role == 'intern') {
            Navigator.pushReplacementNamed(context, '/intern-profile-setup');
          } else {
            Navigator.pushReplacementNamed(context, '/profile-setup');
          }
        }
        return;
      }
      rethrow; // Let the outer handler show the error dialog.
    }

    // Student Profile exists, now check Biometrics
    if (mounted) {
      final biometricService = BiometricService();
      final hasEnrolledBiometrics = await biometricService.checkBiometrics();

      if (hasEnrolledBiometrics) {
        final authenticated = await biometricService.authenticate();
        if (authenticated) {
          if (mounted) Navigator.pushReplacementNamed(context, '/home');
        } else {
          // authenticate() returned false — either the user cancelled or
          // the device has biometric hardware but nothing enrolled.
          // Device-binding already secures the account, so proceed to home.
          if (mounted) Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // No enrolled biometrics — proceed to home (device-binding is the guard).
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  void _showConnectionError(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Connection Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _checkAuthAndNavigate(isRetry: true);
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              _authService.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/logo.png',
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.school,
                    size: 100, color: AppColors.blue600);
              },
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Verifying Profile...',
              style: TextStyle(
                color: AppColors.gray600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
