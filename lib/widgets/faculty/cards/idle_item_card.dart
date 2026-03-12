import 'package:flutter/material.dart';
import '../../../constants/faculty/faculty_colors.dart';
import '../../../constants/faculty/faculty_text_styles.dart';

class IdleItemCard extends StatelessWidget {
  final String time;

  const IdleItemCard({super.key, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: FacultyColors.gray50.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FacultyColors.gray100, style: BorderStyle.solid),
      ),
      child: Text(
        "Free Slot",
        style: FacultyTextStyles.bodySmall.copyWith(
          color: FacultyColors.gray300,
          fontSize: 12,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
