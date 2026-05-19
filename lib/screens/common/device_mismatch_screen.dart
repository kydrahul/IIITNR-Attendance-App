import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';

class DeviceMismatchScreen extends StatefulWidget {
  final String message;

  const DeviceMismatchScreen({super.key, required this.message});

  @override
  State<DeviceMismatchScreen> createState() => _DeviceMismatchScreenState();
}

class _DeviceMismatchScreenState extends State<DeviceMismatchScreen> {
  bool _isSigningOut = false;

  Future<void> _handleSignOut() async {
    if (_isSigningOut) return; // guard against double-tap
    setState(() => _isSigningOut = true);

    try {
      await AuthService().signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      debugPrint('DeviceMismatchScreen: signOut failed: $e');
      if (!mounted) return;

      // Show the error but still offer a navigation escape so the user is
      // never permanently stuck on this screen.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-out failed: $e\nRedirecting to login anyway…'),
          backgroundColor: AppColors.red600,
          duration: const Duration(seconds: 3),
        ),
      );

      // Brief delay so the user can read the snackbar, then navigate anyway.
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.phonelink_lock,
                size: 100,
                color: AppColors.red600,
              ),
              const SizedBox(height: 32),
              Text(
                'Device Not Authorized',
                style: AppTextStyles.h1.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                widget.message,
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.gray700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.yellow50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.yellow200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.yellow700,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This account is already bound to another device.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.yellow900,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please contact your administrator or faculty to unbind your previous device and register this one.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.yellow800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSigningOut ? null : _handleSignOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red600,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.red600.withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSigningOut
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Sign Out',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
