import 'package:flutter/material.dart';
import '../../../constants/faculty/faculty_colors.dart';
import '../../../constants/faculty/faculty_text_styles.dart';

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
                      style: FacultyTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                          color: FacultyColors.gray400,
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
                      color: FacultyColors.gray200, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Idle - No Class",
                  style: FacultyTextStyles.bodySmall.copyWith(
                    color: FacultyColors.gray400,
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
