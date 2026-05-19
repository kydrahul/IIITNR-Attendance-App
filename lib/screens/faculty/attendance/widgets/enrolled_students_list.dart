import 'package:flutter/material.dart';
import '../../../../constants/faculty/faculty_colors.dart';
import '../../../../constants/faculty/faculty_text_styles.dart';

/// Scrollable list of students enrolled in the selected course showing their
/// overall attendance percentage and present/total counts.
class EnrolledStudentsList extends StatelessWidget {
  final List<dynamic> students;
  final int totalSessions;

  const EnrolledStudentsList({
    super.key,
    required this.students,
    required this.totalSessions,
  });

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const Center(
          child: Text('No students enrolled for this course.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: students.length,
      itemBuilder: (context, index) =>
          _buildStudentCard(students[index]),
    );
  }

  Widget _buildStudentCard(dynamic student) {
    final String name = (student['name'] ?? 'Unknown').toString();
    final String roll =
        (student['rollNumber'] ?? student['rollNo'] ?? 'N/A').toString();
    final num perc = student['attendancePercentage'] ?? 0;
    final int attended = student['attendedCount'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FacultyColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FacultyColors.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: name + roll number
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: FacultyTextStyles.h3.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(roll,
                    style: FacultyTextStyles.bodySmall.copyWith(
                        color: FacultyColors.gray500,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          // Right: percentage + present/total
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${perc.toStringAsFixed(1)}%',
                  style: FacultyTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: perc >= 75
                          ? FacultyColors.green600
                          : FacultyColors.red600)),
              Text('$attended/$totalSessions Present',
                  style: FacultyTextStyles.bodySmall
                      .copyWith(color: FacultyColors.gray500)),
            ],
          ),
        ],
      ),
    );
  }
}
