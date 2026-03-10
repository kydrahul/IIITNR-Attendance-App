import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/faculty/faculty_colors.dart';
import '../../../constants/faculty/faculty_text_styles.dart';

class ClassItemCard extends StatelessWidget {
  final String startTime;
  final String endTime;
  final String subject;
  final String status; // "Present", "Absent", "Upcoming"
  final String instructor;
  final int credits;
  final int attendance;
  final VoidCallback? onTap;

  const ClassItemCard({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.status,
    required this.instructor,
    required this.credits,
    required this.attendance,
    this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return FacultyColors.green700;
      case 'Absent':
        return FacultyColors.red700;
      case 'Upcoming':
        return FacultyColors.blue700;
      default:
        return FacultyColors.gray600;
    }
  }

  Color _getStatusBg(String status) {
    switch (status) {
      case 'Present':
        return FacultyColors.green50;
      case 'Absent':
        return FacultyColors.red50;
      case 'Upcoming':
        return FacultyColors.blue50;
      default:
        return FacultyColors.gray50;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Text(startTime,
                    style: FacultyTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: FacultyColors.gray800,
                        fontSize: 14)),
                Text(endTime, style: FacultyTextStyles.label),
                if (status == 'Upcoming') ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: FacultyColors.blue500,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: FacultyColors.blue100, width: 2),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Card
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FacultyColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FacultyColors.gray100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(subject, style: FacultyTextStyles.h4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusBg(status),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                                color: _getStatusBg(status).withOpacity(
                                    0.5)), // slightly darker border
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(instructor,
                        style: FacultyTextStyles.bodySmall.copyWith(
                            color: FacultyColors.gray500,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.only(top: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                            top: BorderSide(color: FacultyColors.gray50)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildStat("CREDITS", credits.toString()),
                              Container(
                                width: 1,
                                height: 24,
                                color: FacultyColors.gray100,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              _buildStat(
                                "ATTENDANCE",
                                "$attendance%",
                                valueColor: attendance < 75
                                    ? FacultyColors.red500
                                    : FacultyColors.green600,
                              ),
                            ],
                          ),
                          if (status == 'Upcoming')
                            const Icon(LucideIcons.chevronRight,
                                size: 16, color: FacultyColors.gray300),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FacultyTextStyles.label),
        Text(
          value,
          style: FacultyTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? FacultyColors.gray700,
          ),
        ),
      ],
    );
  }
}
