import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';

class IdleItemCard extends StatelessWidget {
  final String time;

  const IdleItemCard({super.key, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Opacity(
        opacity: 0.5,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 60,
              child: Column(
                children: [
                  Text(time,
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray400,
                          fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: AppColors.gray200,
                      style: BorderStyle
                          .solid), // Dashed border is hard in basic Flutter, solid is fine for now or use a package
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Idle - No Class",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.gray400,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
