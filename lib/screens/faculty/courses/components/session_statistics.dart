import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../constants/faculty/faculty_colors.dart';
import '../../../../constants/faculty/faculty_text_styles.dart';
import '../../../../providers/live_session_provider.dart';

class SessionStatistics extends StatelessWidget {
  const SessionStatistics({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LiveSessionProvider>();
    
    // In real implementation we could fetch this locally or externally
    int totalEnrolled = provider.students.length;
    if (totalEnrolled == 0) totalEnrolled = 45; // Fallback mock value
    final int present = provider.students.where((s) => s['isPresent']).length;
    final int absent = totalEnrolled - present;
    final double attendancePercent = totalEnrolled > 0 ? (present / totalEnrolled) : 0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: FacultyColors.green50.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FacultyColors.green100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.barChart3,
                      color: FacultyColors.green600, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Session Statistics',
                    style: FacultyTextStyles.h3
                        .copyWith(color: FacultyColors.black),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildStatCard('Total\nStudents',
                          totalEnrolled.toString(), FacultyColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard('Present', present.toString(),
                          FacultyColors.green600),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                          'Absent', absent.toString(), FacultyColors.red600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: attendancePercent,
                backgroundColor: FacultyColors.gray200,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(FacultyColors.green600),
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${(attendancePercent * 100).toStringAsFixed(1)}% Attendance',
                  style: const TextStyle(
                      color: FacultyColors.gray500,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            context.read<LiveSessionProvider>().startNewSession();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: FacultyColors.primary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Start New Session',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: FacultyColors.white)),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: FacultyColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FacultyColors.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: valueColor),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 32,
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 12, color: FacultyColors.gray500, height: 1.2),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
