import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/faculty/faculty_api_service.dart';
import '../../services/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleBiometricAndRoute(String targetRoute) async {
    final biometricService = BiometricService();
    final canCheck = await biometricService.checkBiometrics();

    if (canCheck) {
      final authenticated = await biometricService.authenticate();
      if (!authenticated) {
        setState(() {
          _errorMessage = 'Biometric authentication failed. Please try again.';
          _isLoading = false;
        });
        await _authService.signOut();
        return;
      }
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, targetRoute);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Validate email domain
      final email = userCredential.user?.email ?? '';
      if (!email.endsWith('@iiitnr.edu.in')) {
        setState(() {
          _errorMessage =
              'Only IIITNR students can access this app.\nPlease use your @iiitnr.edu.in email.';
          _isLoading = false;
        });
        await _authService.signOut();
        return;
      }

      // Check if profile exists (bypass cache to verify real DB state)
      try {
        await _apiService.getProfile(checkProfileExists: true);
        // Profile exists, navigate to home via biometric check
        await _handleBiometricAndRoute('/home');
      } catch (e) {
        if (e.toString().contains('Profile not found')) {
          // Profile doesn't exist, navigate to profile setup
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/profile-setup');
          }
        } else {
          // Other error (e.g. 500), show error message
          setState(() {
            _errorMessage =
                'Login Error: ${e.toString().replaceAll("Exception:", "")}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sign in: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleFacultyLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final email = userCredential.user?.email ?? '';
      if (!email.endsWith('@iiitnr.edu.in')) {
        setState(() {
          _errorMessage =
              'Only IIITNR faculty can access this app.\nPlease use your @iiitnr.edu.in email.';
          _isLoading = false;
        });
        await _authService.signOut();
        return;
      }

      // Check if profile exists
      try {
        await FacultyApiService().getProfile();
        // Profile exists, perform biometrics and navigate
        await _handleBiometricAndRoute('/faculty-home');
      } catch (e) {
        setState(() {
          _errorMessage =
              'Login Error: Profile not found or you do not have faculty access.';
          _isLoading = false;
        });
        await _authService.signOut();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sign in: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(flex: 3),
            // Logo Box
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/withoutlogo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.school,
                  size: 40,
                  color: AppColors.blue600,
                ),
              ),
            ),
            const SizedBox(height: 48),
            Text(
              'DSPM IIITNR\nATTENDANCE',
              style: AppTextStyles.h1.copyWith(
                fontSize: 32,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppColors.blue600,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(flex: 1),

            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),

            // Student Login Button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleGoogleSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.gray700,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.gray200),
                ),
                minimumSize: const Size(double.infinity, 56),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.school_outlined,
                            size: 24, color: AppColors.black),
                        const SizedBox(width: 12),
                        Text(
                          'Login as Student',
                          style: AppTextStyles.h4
                              .copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),

            // Faculty Login Button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleFacultyLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.gray700,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.gray200),
                ),
                minimumSize: const Size(double.infinity, 56),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_outline,
                      size: 24, color: AppColors.black),
                  const SizedBox(width: 12),
                  Text(
                    'Login as Faculty',
                    style:
                        AppTextStyles.h4.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Email domain hint
            Text(
              '( via institute email )',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.gray500,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Disclaimer
            Text(
              'By logging in, you agree to the Terms of Service and '
              'Privacy Policy of your institution.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray400),
              textAlign: TextAlign.center,
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
