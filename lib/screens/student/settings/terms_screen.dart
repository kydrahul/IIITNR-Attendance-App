import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/text_styles.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text("Terms & Conditions",
            style:
                TextStyle(color: AppColors.black, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Last Updated: December 2025",
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.gray500)),
            const SizedBox(height: 24),
            _buildSection("1. Acceptance of Terms",
                "By accessing and using the IIITNR Attendance App, you accept and agree to be bound by the terms and provision of this agreement."),
            _buildSection("2. Attendance Tracking",
                "This app uses location services (Geofencing) and QR code scanning to verify your physical presence in class. Any attempt to spoof location or share QR codes remotely is a violation of the academic integrity policy."),
            _buildSection("3. Device Binding",
                "Your account is bound to your specific device. You may not log in from multiple devices simultaneously to mark attendance for others."),
            _buildSection("4. Data Accuracy",
                "You are responsible for ensuring your device's time and location settings are accurate during attendance marking."),
            _buildSection("5. Academic Integrity",
                "Falsifying attendance records is a serious offense and will be reported to the academic administration."),
            _buildSection("6. Modifications",
                "We reserve the right to modify these terms at any time. Continued use of the app constitutes acceptance of new terms."),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(content,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.gray700, height: 1.5)),
        ],
      ),
    );
  }
}
