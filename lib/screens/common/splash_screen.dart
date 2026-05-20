import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../constants/colors.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../student/settings/terms_screen.dart';
import '../student/settings/privacy_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  // Keep references so we can dispose them properly
  final TapGestureRecognizer _termsTap = TapGestureRecognizer();
  final TapGestureRecognizer _privacyTap = TapGestureRecognizer();

  @override
  void initState() {
    super.initState();
    _termsTap.onTap = () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen()),
    );
    _privacyTap.onTap = () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Artificial delay for splash effect
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = _authService.currentUser;

    if (user == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // User is authenticated, check if profile exists
    try {
      final role = await _authService.getUserRole();

      if (role == 'faculty') {
        // Skip profile check/biometrics for faculty auto-login
        if (mounted) Navigator.pushReplacementNamed(context, '/faculty-home');
        return;
      }

      // For both students and interns, verify profile exists then go to home.
      // Biometric gate is handled inside HomeScreen after login.

      // Pass true to bypass cache and verify real DB existence
      await _apiService.getProfile(checkProfileExists: true);

      // Profile exists — navigate to home (biometric will be triggered there)
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      debugPrint('Profile check failed: $e');

      if (e.toString().contains('Profile not found')) {
        final role = await _authService.getUserRole();
        if (mounted) {
          if (role == 'intern') {
            Navigator.pushReplacementNamed(context, '/intern-profile-setup');
          } else {
            Navigator.pushReplacementNamed(context, '/profile-setup');
          }
        }
      } else {
        // Show error dialog for other errors (e.g. 500, Network)
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Connection Error'),
              content: Text(
                  'Could not verify profile. Error: ${e.toString().replaceAll("Exception:", "")}'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    _checkAuthAndNavigate(); // Retry
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Main centered content
          Expanded(
            child: Center(
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
                  const SizedBox(height: 12),
                  const Text(
                    'DSPM IIITNR',
                    style: TextStyle(
                      color: AppColors.blue600,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Attendance System',
                    style: TextStyle(
                      color: AppColors.gray500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.blue600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Verifying Profile...',
                    style: TextStyle(
                      color: AppColors.gray600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer with clickable Terms & Privacy
          Padding(
            padding: const EdgeInsets.only(bottom: 32, left: 24, right: 24),
            child: Column(
              children: [
                const Divider(color: AppColors.gray100),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      color: AppColors.gray400,
                      fontSize: 12,
                    ),
                    children: [
                      const TextSpan(text: 'By using this app, you agree to our '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: const TextStyle(
                          color: AppColors.blue600,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          fontSize: 12,
                        ),
                        recognizer: _termsTap,
                      ),
                      const TextSpan(text: ' & '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(
                          color: AppColors.blue600,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          fontSize: 12,
                        ),
                        recognizer: _privacyTap,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '© 2026 DSPM IIIT Naya Raipur',
                  style: TextStyle(
                    color: AppColors.gray300,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
