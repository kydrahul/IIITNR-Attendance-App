import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/text_styles.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text("Privacy Policy",
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
            _buildSection("1. Information We Collect",
                "We collect your Name, Roll Number, Email, Device ID, and Location Data specifically during the attendance marking process."),
            _buildSection("2. How We Use Location Data",
                "Location data is used ONLY at the moment of scanning a QR code to verify you are within the classroom geofence. We do not track your location in the background or at any other time."),
            _buildSection("3. Device Information",
                "We verify your Device ID to prevent proxy attendance. This ID is linked to your student profile."),
            _buildSection("4. Data Security",
                "Your data is stored securely on encrypted servers. Access is restricted to authorized faculty and administration."),
            _buildSection("5. Third-Party Services",
                "We use Google Firebase for authentication and database services. Their privacy policies also apply."),
            _buildSection("6. Contact Us",
                "If you have questions about this policy, please contact the IT department."),
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
