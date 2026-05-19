import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../constants/faculty/faculty_colors.dart';
import '../../../../constants/faculty/faculty_text_styles.dart';
import '../../../../models/faculty/faculty_models.dart' as fm;
import '../../../../utils/date_utils.dart' as du;
import '../session_details_screen.dart';
import '../../faculty_weekly_timetable_screen.dart';

/// Tab 1 of CourseDetailsScreen — quick metrics, next class, recent activity.
class OverviewTab extends StatelessWidget {
  final Map<String, dynamic> course;
  final List<Map<String, dynamic>> allCourses;
  final List<dynamic> sessions;
  final int studentCount;

  const OverviewTab({
    super.key,
    required this.course,
    required this.allCourses,
    required this.sessions,
    required this.studentCount,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildQuickOverviewCard(context),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Activity',
                style: FacultyTextStyles.h3.copyWith(fontSize: 16)),
            TextButton(
              onPressed: () => DefaultTabController.of(context).animateTo(1),
              child: const Text('View All',
                  style: TextStyle(
                      color: FacultyColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (sessions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text('No recent activity yet',
                  style: TextStyle(color: FacultyColors.gray500)),
            ),
          )
        else
          ...sessions.take(5).map((session) {
            final String? iso = session['startTimeIso'];
            final String? dateField = session['date']?.toString();
            final DateTime local = _parseDateTime(iso, dateField);
            final String dateStr = '${local.day} ${du.monthAbbr(local.month)}';
            return _buildActivityItem(context, dateStr, session);
          }),
      ],
    );
  }

  // ─── Quick overview card ──────────────────────────────────────────────────

  Widget _buildQuickOverviewCard(BuildContext context) {
    final String acadYear = course['academicYear']?.toString() ?? 'N/A';
    final String sem = du.semesterOrdinal(course['semester']?.toString() ?? 'N/A');
    final String sessionStr = course['session']?.toString() ?? 'Autumn';
    final bool isSummer = sessionStr == 'Summer';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FacultyColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FacultyColors.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildCompactMetric(
                LucideIcons.users,
                'STUDENTS',
                studentCount.toString(),
                FacultyColors.blue600,
              ),
              _buildVerticalDivider(),
              _buildCompactMetric(
                LucideIcons.layers,
                isSummer ? 'TERM' : 'SEMESTER',
                isSummer ? 'Summer' : sem,
                FacultyColors.green600,
              ),
              _buildVerticalDivider(),
              _buildCompactMetric(
                LucideIcons.briefcase,
                isSummer ? 'YEAR' : 'BRANCH',
                isSummer
                    ? '2026'
                    : (course['department']?.toString() ??
                        course['branch']?.toString() ??
                        'N/A'),
                FacultyColors.gray500,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: FacultyColors.gray100),
          const SizedBox(height: 24),
          InkWell(
            onTap: () {
              final fm.Course currentCourse = fm.Course(
                id: (course['id'] ?? '').toString(),
                code: (course['code'] ?? '').toString(),
                name: (course['name'] ?? '').toString(),
                section: (course['section'] ?? 'A').toString(),
                enrolledCount: studentCount,
                joinCode: (course['joinCode'] ?? '').toString(),
                department:
                    (course['department'] ?? course['branch'] ?? '').toString(),
                academicYear: acadYear,
                credits:
                    int.tryParse(course['credits']?.toString() ?? '3') ?? 3,
                semester: (course['semester'] ?? '').toString(),
                session: sessionStr,
                timetable: (course['timetable'] as List?)
                        ?.map((t) => fm.TimetableSlot.fromJson(t))
                        .toList() ??
                    [],
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FacultyWeeklyTimetableScreen(
                    courses: [currentCourse],
                    highlightCourseCode: currentCourse.code,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(LucideIcons.calendar,
                      size: 24, color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('NEXT CLASS',
                          style: TextStyle(
                              color: FacultyColors.gray400,
                              letterSpacing: 0.5,
                              fontFamily: 'Roboto',
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      ...(() {
                        final info = _nextClassInfo(course);
                        final parts = info.split('|');
                        final dayStr = parts[0];
                        final timeStr = parts.length > 1 ? parts[1] : '';
                        return [
                          Text(dayStr,
                              style: GoogleFonts.montserrat(
                                  color: FacultyColors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          if (timeStr.isNotEmpty)
                            Text(timeStr,
                                style: GoogleFonts.roboto(
                                    color: FacultyColors.gray500,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                        ];
                      })(),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight,
                    size: 20, color: FacultyColors.gray300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() => Container(
        height: 32,
        width: 1,
        color: FacultyColors.gray100,
        margin: const EdgeInsets.symmetric(horizontal: 12),
      );

  Widget _buildCompactMetric(
      IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.roboto(
                      color: FacultyColors.gray400,
                      fontSize: 9,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                  color: FacultyColors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ─── Recent activity item ─────────────────────────────────────────────────

  Widget _buildActivityItem(
      BuildContext context, String date, dynamic session) {
    final DateTime local = _parseDateTime(
        session['startTimeIso'], session['date']?.toString());
    final String time = _formatTime(local);
    final String attendance =
        '${session['presentCount'] ?? 0}/${session['totalStudents'] ?? 0}';
    final String type =
        (session['type'] ?? session['classType'] ?? 'Theory').toString();
    final String room =
        (session['roomNumber'] ?? session['room'] ?? 'N/A').toString();
    final bool isLab = type.toLowerCase().contains('lab');

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SessionDetailsScreen(
            course: course,
            dateStr: date,
            timeStr: time,
            totalStudents: session['totalStudents'] ?? 0,
            presentCount: session['presentCount'] ?? 0,
            sessionId: session['id']?.toString(),
            roomNumber: room,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FacultyColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FacultyColors.gray100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isLab ? FacultyColors.yellow50 : FacultyColors.blue50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isLab ? LucideIcons.flaskConical : LucideIcons.bookOpen,
                size: 18,
                color: isLab ? FacultyColors.yellow700 : FacultyColors.blue600,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('$time • $type • Room: $room',
                      style: FacultyTextStyles.bodySmall
                          .copyWith(color: FacultyColors.gray500, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(attendance,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const Text('Present',
                    style: TextStyle(
                        color: FacultyColors.gray400, fontSize: 10)),
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
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }


  static String _nextClassInfo(Map<String, dynamic> courseData) {
    try {
      final timetable = courseData['timetable'] as List?;
      if (timetable == null || timetable.isEmpty) return 'No schedule set';
      final now = DateTime.now();
      const days = [
        'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
      ];
      for (int i = 0; i < 7; i++) {
        final dayIdx = (now.weekday - 1 + i) % 7;
        final dayName = days[dayIdx];
        final slots = timetable.where((s) => s['day'] == dayName).toList();
        if (slots.isNotEmpty) {
          final prefix =
              i == 0 ? 'Today' : (i == 1 ? 'Tomorrow' : dayName);
          return '$prefix|${slots.first['time'] ?? 'N/A'}';
        }
      }
      return 'No upcoming classes';
    } catch (_) {
      return 'Check schedule';
    }
  }
}
