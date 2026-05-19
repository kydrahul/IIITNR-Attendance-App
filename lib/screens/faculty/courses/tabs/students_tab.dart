import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../constants/faculty/faculty_colors.dart';
import '../student_stats_screen.dart';

/// Tab 3 of CourseDetailsScreen — searchable enrolled student list.
class StudentsTab extends StatefulWidget {
  final Map<String, dynamic> course;
  final List<dynamic> students;
  final List<dynamic> allSessions;

  const StudentsTab({
    super.key,
    required this.course,
    required this.students,
    required this.allSessions,
  });

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.students.where((s) {
      final name = s['name']?.toString().toLowerCase() ?? '';
      final rollNo = s['rollNo']?.toString().toLowerCase() ?? '';
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || rollNo.contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search Students...',
              prefixIcon: const Icon(LucideIcons.search,
                  size: 20, color: FacultyColors.gray400),
              filled: true,
              fillColor: FacultyColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: FacultyColors.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: FacultyColors.gray200),
              ),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No students found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _buildStudentTile(context, filtered[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildStudentTile(BuildContext context, dynamic student) {
    final attendance = student['attendancePercentage'] ?? 0;
    final name = student['name'] ?? 'Unknown';
    final rollNo =
        (student['rollNo'] ?? student['rollNumber'] ?? 'N/A').toString();
    final statusColor = attendance > 85
        ? FacultyColors.green600
        : (attendance > 75 ? FacultyColors.primary : FacultyColors.red600);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentStatsScreen(
            studentName: name,
            rollNo: rollNo,
            courseName: widget.course['name'] ?? 'Course',
            allSessions: widget.allSessions,
            studentSessions: student['sessions'],
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: FacultyColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FacultyColors.gray100),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: FacultyColors.blue50,
              radius: 20,
              child: Text(
                rollNo.length > 2
                    ? rollNo.substring(rollNo.length - 2)
                    : rollNo,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: FacultyColors.blue600),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('Roll: $rollNo',
                      style: const TextStyle(
                          color: FacultyColors.gray500, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$attendance%',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: statusColor)),
                const Text('Attendance',
                    style: TextStyle(
                        color: FacultyColors.gray400, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
