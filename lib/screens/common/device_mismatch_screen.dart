import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';

class DeviceMismatchScreen extends StatelessWidget {
  final String message;

  const DeviceMismatchScreen({super.key, required this.message});

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
                message,
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
                  onPressed: () async {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red600,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
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
