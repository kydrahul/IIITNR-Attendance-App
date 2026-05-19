import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../constants/faculty/faculty_colors.dart';
import '../../../../utils/date_utils.dart' as du;
import '../session_details_screen.dart';

/// Tab 2 of CourseDetailsScreen — full chronological session list with
/// individual "Details" buttons that navigate to SessionDetailsScreen.
class CourseAttendanceTab extends StatelessWidget {
  final Map<String, dynamic> course;
  final List<dynamic> sessions;

  const CourseAttendanceTab({
    super.key,
    required this.course,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.calendar, size: 48, color: FacultyColors.gray300),
            const SizedBox(height: 16),
            const Text('No sessions recorded for this course yet.',
                style: TextStyle(color: FacultyColors.gray500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: sessions.length,
      itemBuilder: (context, index) =>
          _buildSessionCard(context, sessions[index]),
    );
  }

  Widget _buildSessionCard(BuildContext context, dynamic session) {
    final String? iso = session['startTimeIso'];
    final String? dateField = session['date']?.toString();
    final DateTime local = _parseDateTime(iso, dateField);

    final String dateStr =
        '${local.day} ${du.monthAbbr(local.month)} ${local.year}';
    final String startTime = _formatTime(local);
    final String room =
        session['roomNumber']?.toString() ?? session['room']?.toString() ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FacultyColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FacultyColors.gray100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(
                    '${session['type'] ?? session['classType'] ?? 'Theory'} Session',
                    style: const TextStyle(
                        color: FacultyColors.gray500, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _buildMetric('Time', startTime, FacultyColors.blue600)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildMetric('Room', room, FacultyColors.gray600)),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SessionDetailsScreen(
                      course: course,
                      dateStr: dateStr,
                      timeStr: startTime,
                      totalStudents: session['totalStudents'] ?? 0,
                      presentCount: session['presentCount'] ?? 0,
                      sessionId: session['id']?.toString(),
                      roomNumber: room,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FacultyColors.black,
                  foregroundColor: FacultyColors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Details', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          Text(label,
              style: const TextStyle(
                  color: FacultyColors.gray500, fontSize: 11)),
        ],
      );

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
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

}
