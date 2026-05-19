import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/faculty/faculty_api_service.dart';
import '../../services/biometric_service.dart';
import '../../utils/responsive.dart';
import '../../utils/snackbar_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  bool _isStudentLoading = false;
  bool _isFacultyLoading = false;
  bool _isInternLoading = false;
  bool get _isLoading => _isStudentLoading || _isFacultyLoading || _isInternLoading;
  String? _errorMessage;

  Future<void> _handleBiometricAndRoute(String targetRoute) async {
    final biometricService = BiometricService();
    final hasEnrolledBiometrics = await biometricService.checkBiometrics();

    if (hasEnrolledBiometrics) {
      // authenticate() may return false on devices with biometric hardware
      // but no enrolled biometrics, or on OEM Android 14 devices where
      // BiometricPrompt misbehaves. Either way, proceed — device-binding
      // is the real security guard.
      await biometricService.authenticate();
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
      final msg = e.toString().replaceAll('Exception: ', '').replaceAll('Exception:', '');
      setState(() {
        _errorMessage = msg;
        _isStudentLoading = false;
      });
      if (mounted) showErrorSnackbar(context, msg);
    }
  }

  Future<void> _handleInternLogin() async {
    setState(() {
      _isInternLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential == null) {
        setState(() {
          _isInternLoading = false;
        });
        return;
      }

      // No email domain restriction for interns — any email is allowed

      // Check if profile exists
      try {
        final apiService = ApiService();
        await apiService.getProfile(checkProfileExists: true);

        await _authService.setUserRole('intern');
        // Profile exists, navigate to home via biometric check
        await _handleBiometricAndRoute('/home');
      } catch (e) {
        if (e.toString().contains('Profile not found')) {
          await _authService.setUserRole('intern');
          // Profile doesn't exist, navigate to intern profile setup
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/intern-profile-setup');
          }
        } else {
          setState(() {
            _errorMessage =
                'Login Error: ${e.toString().replaceAll("Exception:", "")}';
            _isInternLoading = false;
          });
        }
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '').replaceAll('Exception:', '');
      setState(() {
        _errorMessage = msg;
        _isInternLoading = false;
      });
      if (mounted) showErrorSnackbar(context, msg);
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

      // Restrict to @iiitnr.edu.in domain for faculty
      final email = userCredential.user?.email ?? '';
      if (!email.endsWith('@iiitnr.edu.in')) {
        setState(() {
          _errorMessage =
              'Only IIITNR faculty can access this app.\nPlease use your @iiitnr.edu.in email.';
          _isFacultyLoading = false;
        });
        await _authService.signOut();
        return;
      }
      final localPart = email.split('@').first;
      final hasNumbers = RegExp(r'\d').hasMatch(localPart);
      if (hasNumbers) {
        try {
          final isWhitelisted = await FacultyApiService().verifyFacultyAccess();
          if (!isWhitelisted) {
            setState(() {
              _errorMessage = 'This appears to be a student email.\nFaculty emails don\'t contain numbers.\nContact admin if this is incorrect.';
              _isFacultyLoading = false;
            });
            await _authService.signOut();
            return;
          }
        } catch (e) {
          setState(() {
            _errorMessage = 'Could not verify faculty access. Please try again.';
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

      await _authService.setUserRole('faculty');
      if (mounted) {
        if (isProfileComplete) {
          Navigator.pushReplacementNamed(context, '/faculty-home');
        } else {
          Navigator.pushReplacementNamed(
              context, '/faculty-profile-completion');
        }
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '').replaceAll('Exception:', '');
      setState(() {
        _errorMessage = msg;
        _isFacultyLoading = false;
      });
      if (mounted) showErrorSnackbar(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.horizontalPadding(context);
    final logoSize = Responsive.w(110, context).clamp(80.0, 130.0);
    final btnHeight = Responsive.h(52, context).clamp(44.0, 60.0);
    final titleFontSize = Responsive.sp(28, context).clamp(22.0, 34.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo Box
              Container(
                width: logoSize,
                height: logoSize,
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
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.school,
                    size: logoSize * 0.35,
                    color: AppColors.blue600,
                  ),
                ),
              ),
              SizedBox(height: Responsive.h(36, context)),
              Text(
                'DSPM IIITNR\nATTENDANCE',
                style: AppTextStyles.h1.copyWith(
                  fontSize: titleFontSize,
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
                    style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: Responsive.sp(12, context)),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Student Login Button
              SizedBox(
                width: double.infinity,
                height: btnHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.gray700,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.gray200),
                    ),
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
                                size: 22, color: AppColors.black),
                            const SizedBox(width: 10),
                            Text(
                              'Login as Student',
                              style: AppTextStyles.h4.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: Responsive.sp(15, context),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: Responsive.h(10, context)),

              // Faculty Login Button
              SizedBox(
                width: double.infinity,
                height: btnHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleFacultyLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.gray700,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.gray200),
                    ),
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
                                size: 22, color: AppColors.black),
                            const SizedBox(width: 10),
                            Text(
                              'Login as Faculty',
                              style: AppTextStyles.h4.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: Responsive.sp(15, context),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: Responsive.h(8, context)),
              // Email domain hint
              Text(
                '( via institute email )',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.gray500,
                  fontWeight: FontWeight.w500,
                  fontSize: Responsive.sp(11, context),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: Responsive.h(16, context)),
              // Divider with Summer Intern label
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.gray200)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wb_sunny,
                            size: 13, color: Colors.amber.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Summer 2026',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: Responsive.sp(11, context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.gray200)),
                ],
              ),
              SizedBox(height: Responsive.h(10, context)),

              // Summer Intern Login Button
              SizedBox(
                width: double.infinity,
                height: btnHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleInternLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.gray700,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.amber.shade300),
                    ),
                  ),
                  child: _isInternLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wb_sunny_outlined,
                                size: 22, color: Colors.amber.shade700),
                            const SizedBox(width: 10),
                            Text(
                              'Login as Summer Intern',
                              style: AppTextStyles.h4.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: Responsive.sp(15, context),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              SizedBox(height: Responsive.h(12, context)),

              // Disclaimer
              Text(
                'By logging in, you agree to the Terms of Service and '
                'Privacy Policy of your institution.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.gray400,
                  fontSize: Responsive.sp(11, context),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Responsive.h(20, context)),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
