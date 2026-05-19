import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../models/data_models.dart';
import '../../utils/responsive.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onClick;

  const CourseCard({super.key, required this.course, required this.onClick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + faculty — takes available space, shrinks before %
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.name,
                        style: AppTextStyles.h4.copyWith(
                          fontSize: Responsive.sp(15, context),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        course.faculty,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.gray500,
                            fontWeight: FontWeight.w500,
                            fontSize: Responsive.sp(11, context)),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "${course.attendance}%",
                  style: AppTextStyles.h2.copyWith(
                    fontSize: Responsive.sp(18, context),
                    color: course.attendance > 75
                        ? AppColors.green600
                        : AppColors.red600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.gray50)),
              ),
              child: Row(
                children: [
                  Expanded(
                      child: _buildStat("CREDITS", course.credits == 0 ? "N/A" : course.credits.toString(),
                          align: CrossAxisAlignment.center)),
                  Container(width: 1, height: 24, color: AppColors.gray100),
                  Expanded(
                      child: _buildStat("TOTAL", course.totalClasses.toString(),
                          align: CrossAxisAlignment.center)),
                  Container(width: 1, height: 24, color: AppColors.gray100),
                  Expanded(
                      child: _buildStat("MISSED", course.missed.toString(),
                          valueColor: AppColors.red500,
                          align: CrossAxisAlignment.center)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value,
      {Color? valueColor,
      CrossAxisAlignment align = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: AppTextStyles.label),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.gray800,
          ),
        ),
      ],
    );
  }
}
