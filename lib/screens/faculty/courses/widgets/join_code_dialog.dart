import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../constants/faculty/faculty_colors.dart';
import '../../../../constants/faculty/faculty_text_styles.dart';

class JoinCodeDialog extends StatelessWidget {
  final String courseName;
  final String courseCode;
  final String joinCode;

  const JoinCodeDialog({
    super.key,
    required this.courseName,
    required this.courseCode,
    required this.joinCode,
  });

  static void show(BuildContext context, String courseName, String courseCode, String joinCode) {
    showDialog(
      context: context,
      builder: (context) => JoinCodeDialog(
        courseName: courseName,
        courseCode: courseCode,
        joinCode: joinCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: FacultyColors.blue50,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.key, color: FacultyColors.blue600, size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              'Course Joining Code',
              style: FacultyTextStyles.h3.copyWith(color: FacultyColors.gray900),
            ),
            const SizedBox(height: 8),
            Text(
              'Share this code with your students to join the class.',
              textAlign: TextAlign.center,
              style: FacultyTextStyles.bodyMedium.copyWith(color: FacultyColors.gray500),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: FacultyColors.gray50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FacultyColors.gray200),
              ),
              child: SelectableText(
                joinCode,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: FacultyColors.black,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: joinCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied to clipboard')),
                      );
                    },
                    icon: const Icon(LucideIcons.copy, size: 18),
                    label: const Text('Copy'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final String subject = 'Joining Code for $courseName';
                      final String body = 'Hi students,\n\nPlease use the following code to join the course "$courseName" ($courseCode) on the Attendance App:\n\nJoin Code: $joinCode\n\nBest regards.';
                      Share.share(body, subject: subject);
                    },
                    icon: const Icon(LucideIcons.mail, size: 18),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FacultyColors.black,
                      foregroundColor: FacultyColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: FacultyColors.gray500)),
            ),
          ],
        ),
      ),
    );
  }
}
