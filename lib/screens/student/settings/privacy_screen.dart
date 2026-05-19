import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/text_styles.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold),
        ),
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
            // Header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E3A5F),
                    AppColors.blue600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.shield, color: Colors.white, size: 32),
                  const SizedBox(height: 12),
                  const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'DSPM IIIT Naya Raipur — Attendance System',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Last Updated: May 2026',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Commitment note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.shieldCheck,
                      size: 20, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'We collect only what is necessary. Your data is never sold, '
                      'shared with advertisers, or used for any purpose beyond attendance management.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFF1B5E20),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              icon: LucideIcons.database,
              title: '1. Data We Collect',
              content:
                  'We collect the following data, strictly limited to what is required for the attendance system:\n\n'
                  '• Identity: Full Name, Roll Number / Employee ID, Email Address (from Google Sign-In)\n'
                  '• Profile Photo: Retrieved from your Google account (optional display use only)\n'
                  '• Device Identifier: A unique device fingerprint to enforce device binding\n'
                  '• Location (GPS): Captured only at the instant of QR code scan to verify geofence\n'
                  '• Attendance Records: Timestamps, course IDs, session IDs of marked attendances\n'
                  '• Biometric Data: NOT collected — processed entirely on-device by the OS\n\n'
                  'For Interns additionally:\n'
                  '• College / Institution name\n'
                  '• Internship start & end dates\n'
                  '• Assigned faculty supervisor',
            ),

            _buildSection(
              icon: LucideIcons.mapPin,
              title: '2. Location Data — How & When',
              content:
                  'Location access is triggered ONLY when you tap the QR scan button to mark attendance. It is used exclusively to verify you are within the classroom geofence (≈ 150 m radius).\n\n'
                  '• We do NOT track your location in the background.\n'
                  '• We do NOT store GPS coordinates — only a pass/fail geofence result.\n'
                  '• Location is never used for profiling, advertising, or any non-academic purpose.\n\n'
                  'On Android, we request "While Using the App" permission only.',
            ),

            _buildSection(
              icon: LucideIcons.smartphone,
              title: '3. Device Binding Data',
              content:
                  'A hardware-based device identifier is collected at the time of profile creation and stored server-side. This is used solely to:\n'
                  '• Prevent one student from marking attendance from multiple devices.\n'
                  '• Detect unauthorized account sharing.\n\n'
                  'This identifier cannot be used to personally identify you outside the scope of the attendance system.',
            ),

            _buildSection(
              icon: LucideIcons.server,
              title: '4. How We Store & Protect Your Data',
              content:
                  '• All data is transmitted over HTTPS (TLS 1.2+).\n'
                  '• Authentication tokens are stored using encrypted secure storage (EncryptedSharedPreferences on Android).\n'
                  '• Server-side data is stored in Firebase Firestore and PostgreSQL (Supabase), both with at-rest encryption.\n'
                  '• Access to student/intern data is role-gated: faculty can only view attendance of their own courses.\n'
                  '• Attendance records include cryptographic HMAC signatures to prevent tampering.',
            ),

            _buildSection(
              icon: LucideIcons.share2,
              title: '5. Data Sharing',
              content:
                  'Your data is shared only with:\n'
                  '• Authorized Faculty: Can view attendance records for courses they teach.\n'
                  '• Academic Administration: May access aggregate attendance data for policy enforcement.\n'
                  '• Google Firebase: Used for authentication (subject to Google\'s Privacy Policy).\n'
                  '• Supabase: Used for database storage (subject to Supabase\'s Privacy Policy).\n\n'
                  'We never sell, rent, or share your data with third-party advertisers or marketers.',
            ),

            _buildSection(
              icon: LucideIcons.clock,
              title: '6. Data Retention',
              content:
                  '• Student/Intern attendance records are retained for the duration of the academic year, then archived.\n'
                  '• Account data is retained while you are an active member of IIITNR.\n'
                  '• Intern accounts and data are deactivated upon internship end date.\n'
                  '• You may request deletion of your personal data by contacting the developer at rahul24102@iiitnr.edu.in.',
            ),

            _buildSection(
              icon: LucideIcons.userCheck,
              title: '7. Your Rights',
              content:
                  'You have the right to:\n'
                  '• Access the personal data we hold about you.\n'
                  '• Request correction of inaccurate data.\n'
                  '• Request deletion of your account and associated data.\n'
                  '• Withdraw consent for non-essential data use.\n\n'
                  'To exercise these rights, contact the developer: rahul24102@iiitnr.edu.in',
            ),

            _buildSection(
              icon: LucideIcons.fingerprint,
              title: '8. Biometric Authentication',
              content:
                  'If your device supports biometric authentication (fingerprint / face recognition), the App uses it as an additional identity verification layer. All biometric processing occurs entirely on your device via the operating system\'s secure enclave.\n\n'
                  'The App does not have access to, store, or transmit your biometric data.',
            ),

            _buildSection(
              icon: LucideIcons.link,
              title: '9. Third-Party Services',
              content:
                  'The App integrates with the following services, each governed by their own privacy policies:\n'
                  '• Google Firebase (Authentication, Firestore): firebase.google.com/policies/privacy\n'
                  '• Supabase (Database): supabase.com/privacy\n'
                  '• Google Sign-In: policies.google.com/privacy',
            ),

            _buildSection(
              icon: LucideIcons.refreshCw,
              title: '10. Changes to This Policy',
              content:
                  'We may update this Privacy Policy periodically. Users will be notified of material changes via an in-app notification. Continued use of the App after updates constitutes acceptance of the revised policy.',
            ),

            _buildSection(
              icon: LucideIcons.mail,
              title: '11. Contact Us',
              content:
                  'For privacy-related questions or data requests, contact the development team:\n\n'
                  'Developers: Rahul Barma, Himanshu Deshmukh, Abhinav Bhagat\n'
                  'Contact: rahul24102@iiitnr.edu.in',
            ),

            const SizedBox(height: 8),
            // Project disclaimer
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.blue50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.blue200),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info,
                      size: 18, color: AppColors.blue600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This policy applies to all users: Students, Summer Interns, and Faculty.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.blue700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.blue600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style:
                AppTextStyles.body.copyWith(color: AppColors.gray700, height: 1.6),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.gray100),
        ],
      ),
    );
  }
}
