import 'package:flutter/material.dart';

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
  final String? degree;
  final String? year;
  final String? semester;
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
    this.degree,
    this.year,
    this.semester,
    this.onTap,
  });


  String _getOrdinal(String? sem) {
    if (sem == null || sem.isEmpty) return 'N/A';
    int n = int.tryParse(sem) ?? 0;
    if (n == 0) return sem;
    if (n % 10 == 1 && n % 100 != 11) return "${n}st Semester";
    if (n % 10 == 2 && n % 100 != 12) return "${n}nd Semester";
    if (n % 10 == 3 && n % 100 != 13) return "${n}rd Semester";
    return "${n}th Semester";
  }

  @override
  Widget build(BuildContext context) {
    final String yearDisplay = (year?.toLowerCase().contains('year') == true)
        ? (year ?? 'N/A')
        : '${year ?? 'N/A'} Year';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: FacultyColors.white,
          borderRadius: BorderRadius.circular(12),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    subject,
                    style: FacultyTextStyles.h4.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: FacultyColors.gray900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.more_horiz,
                  size: 16,
                  color: FacultyColors.gray300,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${degree ?? 'B.Tech'}  |  $yearDisplay  |  ${_getOrdinal(semester)}',
              style: FacultyTextStyles.bodySmall.copyWith(
                color: FacultyColors.gray500,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
