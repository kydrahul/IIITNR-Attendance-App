import 'package:flutter/material.dart';
import '../../../../constants/faculty/faculty_colors.dart';
import '../../../../constants/faculty/faculty_text_styles.dart';
import '../../../../models/faculty/faculty_models.dart';
import '../../courses/session_details_screen.dart';

/// Scrollable list of past attendance sessions for the selected course.
/// Tapping a row navigates to [SessionDetailsScreen].
class SessionHistoryList extends StatelessWidget {
  final List<dynamic> sessions;
  final Course selectedCourse;
  final List<dynamic> students;

  const SessionHistoryList({
    super.key,
    required this.sessions,
    required this.selectedCourse,
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const Center(child: Text('No session history found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: sessions.length,
      itemBuilder: (context, index) =>
          _buildSessionCard(context, sessions[index]),
    );
  }

  Widget _buildSessionCard(BuildContext context, dynamic session) {
    final DateTime local = _parseDateTime(
        session['startTimeIso'], session['date']?.toString());

    final String date =
        '${local.day}/${local.month}/${local.year}';
    final String time = _formatTime(local);
    final String type =
        session['type'] ?? session['classType'] ?? 'Theory';
    final String room =
        session['roomNumber']?.toString() ??
            session['room']?.toString() ??
            'N/A';
    final int total = session['totalStudents'] ?? 0;
    final int present = session['presentCount'] ?? 0;
    final num perc = total > 0 ? ((present / total) * 100).round() : 0;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SessionDetailsScreen(
            course: {
              'id': selectedCourse.id,
              'code': selectedCourse.code,
              'name': selectedCourse.name,
              'semester': selectedCourse.semester,
              'students': students,
            },
            dateStr: date,
            timeStr: time,
            totalStudents: total,
            presentCount: present,
            sessionId: session['id']?.toString(),
            roomNumber: room,
          ),
        ),
      ),
      child: Container(
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date,
                      style: FacultyTextStyles.h3.copyWith(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('$time • $type • Room: $room',
                      style: FacultyTextStyles.bodySmall.copyWith(
                          color: FacultyColors.gray500,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${perc.toStringAsFixed(1)}%',
                    style: FacultyTextStyles.h2.copyWith(
                        color: perc >= 75
                            ? FacultyColors.green600
                            : FacultyColors.red600)),
                Text('Attendance',
                    style: FacultyTextStyles.bodySmall
                        .copyWith(color: FacultyColors.gray500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static DateTime _parseDateTime(String? iso, String? dateField) {
    if (iso != null && DateTime.tryParse(iso) != null) {
      return DateTime.parse(iso).toLocal();
    }
    if (dateField != null && DateTime.tryParse(dateField) != null) {
      return DateTime.parse(dateField).toLocal();
    }
    return DateTime.now();
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour > 12
        ? (dt.hour - 12).toString()
        : (dt.hour == 0 ? '12' : dt.hour.toString());
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }
}
