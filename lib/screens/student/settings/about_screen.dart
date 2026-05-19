import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/text_styles.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text("About",
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.blue50,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.school,
                  size: 64, color: AppColors.blue600),
            ),
            const SizedBox(height: 24),
            Text("IIITNR Attendance",
                style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Version 1.0.0",
                style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
            const SizedBox(height: 48),

            _buildInfoCard("Developers",
                "Rahul Barma\nHimanshu Deshmukh\nAbhinav Bhagat",
                LucideIcons.code),
            const SizedBox(height: 16),
            _buildInfoCard(
                "Contact", "rahul24102@iiitnr.edu.in", LucideIcons.mail),
            const SizedBox(height: 48),

            // Personal project disclaimer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.alertTriangle,
                      size: 18, color: Color(0xFFF57F17)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '⚠️ This app is an independent academic project built by Rahul Barma '
                      'as part of a minor project at IIITNR. It is NOT an official product '
                      'of DSPM IIIT Naya Raipur and is not formally endorsed or operated by the institution.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFF7B4700),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              "© 2025 Rahul Barma. All rights reserved.",
              style: AppTextStyles.label.copyWith(color: AppColors.gray400),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.blue600),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(value,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
