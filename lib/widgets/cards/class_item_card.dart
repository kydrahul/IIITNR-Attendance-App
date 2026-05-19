import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';

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
        return AppColors.green700;
      case 'Absent':
        return AppColors.red700;
      case 'Upcoming':
        return AppColors.blue700;
      default:
        return AppColors.gray600;
    }
  }

  Color _getStatusBg(String status) {
    switch (status) {
      case 'Present':
        return AppColors.green50;
      case 'Absent':
        return AppColors.red50;
      case 'Upcoming':
        return AppColors.blue50;
      default:
        return AppColors.gray50;
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
                    style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray800,
                        fontSize: 14)),
                Text(endTime, style: AppTextStyles.label),
                if (status == 'Upcoming') ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.blue500,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.blue100, width: 2),
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
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gray100),
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
                        Flexible(
                          child: Text(subject,
                              style: AppTextStyles.h4,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(instructor,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.gray500,
                            fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.only(top: 12),
                      decoration: const BoxDecoration(
                        border:
                            Border(top: BorderSide(color: AppColors.gray50)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildStat("CREDITS", credits == 0 ? "N/A" : credits.toString()),
                              Container(
                                width: 1,
                                height: 24,
                                color: AppColors.gray100,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              _buildStat(
                                "ATTENDANCE",
                                "$attendance%",
                                valueColor: attendance < 75
                                    ? AppColors.red500
                                    : AppColors.green600,
                              ),
                            ],
                          ),
                          const Icon(LucideIcons.chevronRight,
                                size: 16, color: AppColors.gray300),
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
        Text(label, style: AppTextStyles.label),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.gray700,
          ),
        ),
      ],
    );
  }
}
