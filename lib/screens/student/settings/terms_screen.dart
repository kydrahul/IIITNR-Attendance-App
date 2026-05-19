import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/text_styles.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions',
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
                  colors: [AppColors.blue600, AppColors.blue500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.fileText, color: Colors.white, size: 32),
                  const SizedBox(height: 12),
                  const Text(
                    'Terms & Conditions',
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

            _buildSection(
              icon: LucideIcons.checkCircle,
              title: '1. Acceptance of Terms',
              content:
                  'By accessing and using the IIITNR Attendance System (the "App"), you — whether a student, summer intern, or faculty member — acknowledge that you have read, understood, and agree to be bound by these Terms & Conditions. If you do not agree, you must immediately discontinue use of the App.',
            ),

            _buildSection(
              icon: LucideIcons.users,
              title: '2. User Roles & Eligibility',
              content:
                  '• Students: Must possess an active @iiitnr.edu.in institutional email address.\n'
                  '• Summer Interns: Must be officially registered through the institution\'s internship program and approved by an assigned faculty supervisor.\n'
                  '• Faculty: Must hold an active institutional email and be registered as teaching staff. Faculty are responsible for the integrity of sessions they create.\n\n'
                  'Any use of the App by unauthorized persons is strictly prohibited.',
            ),

            _buildSection(
              icon: LucideIcons.qrCode,
              title: '3. Attendance & QR Code Policy',
              content:
                  'The App uses cryptographically signed, time-bound QR codes (refreshed every 10–30 seconds) combined with GPS geofencing to verify physical presence in class.\n\n'
                  '• QR codes expire automatically and are non-transferable.\n'
                  '• Attempting to share, photograph, or remotely transmit a QR code for proxy attendance is a serious violation.\n'
                  '• Attendance records are server-validated and tamper-resistant.\n'
                  '• Faculty may manually override attendance only in exceptional, documented circumstances.',
            ),

            _buildSection(
              icon: LucideIcons.mapPin,
              title: '4. Location Services (Geofencing)',
              content:
                  'Location access is requested solely at the moment of QR code scanning to confirm you are within the classroom geofence (default radius: 150 m). The App does not track your location in the background, at any other time, or for any other purpose.\n\n'
                  'Denying location permission will prevent attendance marking via the App.',
            ),

            _buildSection(
              icon: LucideIcons.smartphone,
              title: '5. Device Binding',
              content:
                  'Your account is permanently bound to the first device used to complete profile setup. This binding:\n'
                  '• Prevents proxy attendance via multiple devices.\n'
                  '• Is enforced server-side and cannot be bypassed.\n'
                  '• Can only be reset by an administrator for legitimate reasons (device loss, malfunction).\n\n'
                  'Logging in from a new device after binding will be flagged and denied.',
            ),

            _buildSection(
              icon: LucideIcons.fingerprint,
              title: '6. Biometric Authentication',
              content:
                  'The App may use device biometric authentication (fingerprint / face recognition) as an additional identity verification layer after login. Biometric data is processed entirely on-device by the operating system and is never transmitted to or stored by the App or its servers.',
            ),

            _buildSection(
              icon: LucideIcons.shieldAlert,
              title: '7. Academic Integrity & Prohibited Conduct',
              content:
                  'The following actions are strictly prohibited and may result in disciplinary action as per IIITNR\'s Academic Integrity Policy:\n'
                  '• Marking attendance on behalf of another person (proxy attendance).\n'
                  '• Using GPS spoofing, VPNs, or other tools to fake location.\n'
                  '• Sharing login credentials or QR codes.\n'
                  '• Tampering with or attempting to reverse-engineer the App.\n'
                  '• Any form of academic dishonesty facilitated through this system.',
            ),

            _buildSection(
              icon: LucideIcons.info,
              title: '8. Intern-Specific Terms',
              content:
                  'Summer interns are subject to additional conditions:\n'
                  '• Attendance records are shared with the assigned faculty supervisor.\n'
                  '• Interns must maintain attendance above the threshold specified in their internship agreement.\n'
                  '• Enrollment in a course is subject to faculty approval. A "pending" status indicates awaiting faculty authorization.\n'
                  '• Intern accounts are automatically deactivated upon the internship end date.',
            ),

            _buildSection(
              icon: LucideIcons.userCheck,
              title: '9. Faculty Responsibilities',
              content:
                  'Faculty members using the App agree to:\n'
                  '• Only create attendance sessions for courses they are authorized to teach.\n'
                  '• Not share QR generation access with students or unauthorized parties.\n'
                  '• Accurately set geofence parameters reflecting the actual classroom location.\n'
                  '• Report any suspected misuse or system anomalies to the administration.',
            ),

            _buildSection(
              icon: LucideIcons.refreshCw,
              title: '10. Modifications',
              content:
                  'IIITNR reserves the right to modify these Terms at any time. Users will be notified of significant changes via the App. Continued use of the App after changes constitutes acceptance of the updated Terms.',
            ),

            _buildSection(
              icon: LucideIcons.alertTriangle,
              title: '11. Disclaimer of Warranties',
              content:
                  'The App is provided "as is" without warranty of any kind. While we strive for accuracy, IIITNR is not liable for temporary service outages, data inaccuracies due to device/connectivity issues, or any indirect damages resulting from use of the App.',
            ),

            _buildSection(
              icon: LucideIcons.mail,
              title: '12. Contact',
              content:
                  'For questions, feedback, or reporting issues, contact the development team:\n\n'
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
                      'These terms apply to all roles: Students, Summer Interns, and Faculty.',
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
