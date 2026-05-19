import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/faculty/faculty_api_service.dart';
import '../student/settings/terms_screen.dart';
import '../student/settings/privacy_screen.dart';

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
        // Profile exists — route to home (HomeScreen will trigger biometric)
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
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
        // Profile exists — route to home (HomeScreen will trigger biometric)
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
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
      setState(() {
        _errorMessage = 'Failed to sign in: ${e.toString()}';
        _isInternLoading = false;
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

      // TODO: UNCOMMENT FOR PRODUCTION — restrict to @iiitnr.edu.in only
      // final email = userCredential.user?.email ?? '';
      // if (!email.endsWith('@iiitnr.edu.in')) {
      //   setState(() {
      //     _errorMessage =
      //         'Only IIITNR faculty can access this app.\nPlease use your @iiitnr.edu.in email.';
      //     _isFacultyLoading = false;
      //   });
      //   await _authService.signOut();
      //   return;
      // }
      // final localPart = email.split('@').first;
      // final hasNumbers = RegExp(r'\d').hasMatch(localPart);
      // if (hasNumbers) {
      //   try {
      //     final isWhitelisted = await FacultyApiService().verifyFacultyAccess();
      //     if (!isWhitelisted) {
      //       setState(() {
      //         _errorMessage = 'This appears to be a student email.\nFaculty emails don\'t contain numbers.\nContact admin if this is incorrect.';
      //         _isFacultyLoading = false;
      //       });
      //       await _authService.signOut();
      //       return;
      //     }
      //   } catch (e) {
      //     setState(() {
      //       _errorMessage = 'Could not verify faculty access. Please try again.';
      //       _isFacultyLoading = false;
      //     });
      //     await _authService.signOut();
      //     return;
      //   }
      // }

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
            const Spacer(flex: 2),
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

            const SizedBox(height: 20),
            // Divider with Summer Intern label
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.gray200)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wb_sunny, size: 14, color: Colors.amber.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Summer 2026',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.gray200)),
              ],
            ),
            const SizedBox(height: 12),

            // Summer Intern Login Button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleInternLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.gray700,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.amber.shade300),
                ),
                minimumSize: const Size(double.infinity, 56),
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
                            size: 24, color: Colors.amber.shade700),
                        const SizedBox(width: 12),
                        Text(
                          'Login as Summer Intern',
                          style: AppTextStyles.h4
                              .copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 16),

            // Disclaimer — clickable links
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray400),
                children: [
                  const TextSpan(text: 'By logging in, you agree to our '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.blue600,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TermsAndConditionsScreen(),
                          ),
                        );
                      },
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.blue600,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                  ),
                  const TextSpan(text: ' of your institution.'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
