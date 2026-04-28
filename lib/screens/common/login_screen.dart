import 'package:flutter/foundation.dart';
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
  bool _isStudentLoading = false;
  bool _isFacultyLoading = false;
  bool get _isLoading => _isStudentLoading || _isFacultyLoading;
  String? _errorMessage;

  Future<void> _handleBiometricAndRoute(String targetRoute) async {
    final biometricService = BiometricService();
    final canCheck = await biometricService.checkBiometrics();

    if (canCheck) {
      final authenticated = await biometricService.authenticate();
      if (!authenticated) {
        setState(() {
          _errorMessage = 'Biometric authentication failed. Please try again.';
          _isStudentLoading = false;
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
      _isStudentLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential == null) {
        setState(() {
          _isStudentLoading = false;
        });
        return;
      }

      // Validate email domain
      final email = userCredential.user?.email ?? '';
      if (!email.endsWith('@iiitnr.edu.in')) {
        setState(() {
          _errorMessage =
              'Only IIITNR students can access this app.\nPlease use your @iiitnr.edu.in email.';
          _isStudentLoading = false;
        });
        await _authService.signOut();
        return;
      }

      // Check if profile exists (bypass cache to verify real DB state)
      try {
        final apiService = ApiService();
        await apiService.getProfile(checkProfileExists: true);

        await _authService.setUserRole('student');
        // Profile exists, navigate to home via biometric check
        await _handleBiometricAndRoute('/home');
      } catch (e) {
        if (e.toString().contains('Profile not found')) {
          await _authService.setUserRole('student');
          // Profile doesn't exist, navigate to profile setup
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/profile-setup');
          }
        } else {
          // Other error (e.g. 500), show error message
          setState(() {
            _errorMessage =
                'Login Error: ${e.toString().replaceAll("Exception:", "")}';
            _isStudentLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sign in: ${e.toString()}';
        _isStudentLoading = false;
      });
    }
  }

  Future<void> _handleFacultyLogin() async {
    setState(() {
      _isFacultyLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential == null) {
        setState(() {
          _isFacultyLoading = false;
        });
        return;
      }

      // Validate faculty email
      final email = userCredential.user?.email ?? '';

      // Must be @iiitnr.edu.in
      if (!email.endsWith('@iiitnr.edu.in')) {
        setState(() {
          _errorMessage =
              'Only IIITNR faculty can access this app.\nPlease use your @iiitnr.edu.in email.';
          _isFacultyLoading = false;
        });
        await _authService.signOut();
        return;
      }

      // Faculty emails don't have numbers (students have roll numbers like bt2024001)
      final localPart = email.split('@').first;
      final hasNumbers = RegExp(r'\d').hasMatch(localPart);

      if (hasNumbers) {
        // Email has numbers — could be a student. Check server-side whitelist.
        try {
          final isWhitelisted =
              await FacultyApiService().verifyFacultyAccess();
          if (!isWhitelisted) {
            setState(() {
              _errorMessage =
                  'This appears to be a student email.\nFaculty emails don\'t contain numbers.\nContact admin if this is incorrect.';
              _isFacultyLoading = false;
            });
            await _authService.signOut();
            return;
          }
        } catch (e) {
          setState(() {
            _errorMessage =
                'Could not verify faculty access. Please try again.';
            _isFacultyLoading = false;
          });
          await _authService.signOut();
          return;
        }
      }

      // Check if profile is complete
      bool isProfileComplete = false;
      try {
        final profile = await FacultyApiService().getProfile();
        if (profile.name.isNotEmpty) {
          isProfileComplete = true;
        }
      } catch (e) {
        debugPrint(
            'Faculty profile check failed: $e. Assuming first-time login.');
        isProfileComplete = false;
      }

      if (mounted) {
        await _authService.setUserRole('faculty');
        if (isProfileComplete) {
          Navigator.pushReplacementNamed(context, '/faculty-home');
        } else {
          Navigator.pushReplacementNamed(
              context, '/faculty-profile-completion');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sign in: ${e.toString()}';
        _isFacultyLoading = false;
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
              child: _isStudentLoading
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
              child: _isFacultyLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_outline,
                            size: 24, color: AppColors.black),
                        const SizedBox(width: 12),
                        Text(
                          'Login as Faculty',
                          style: AppTextStyles.h4
                              .copyWith(fontWeight: FontWeight.w500),
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
            const SizedBox(height: 32),

            // --- DEVELOPMENT BYPASS (debug builds only) ---
            if (kDebugMode) ...[
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.gray200)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "DEV BYPASS",
                      style:
                          AppTextStyles.label.copyWith(color: AppColors.gray400),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.gray200)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/home'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side:
                            BorderSide(color: AppColors.blue600.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Student App",
                          style:
                              TextStyle(color: AppColors.blue600, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, '/faculty-home'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppColors.black.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Faculty App",
                          style: TextStyle(color: AppColors.black, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
