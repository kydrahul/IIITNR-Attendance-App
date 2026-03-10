import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/faculty/faculty_colors.dart';
import '../../../constants/faculty/faculty_text_styles.dart';
import '../../../models/faculty/faculty_models.dart' as fm;
import '../faculty_weekly_timetable_screen.dart';
import 'session_details_screen.dart';
import 'student_stats_screen.dart';
import 'start_session_screen.dart';

class CourseDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> course;
  final List<Map<String, dynamic>> allCourses;

  const CourseDetailsScreen({
    super.key,
    required this.course,
    required this.allCourses,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: FacultyColors.background,
        appBar: AppBar(
          backgroundColor: FacultyColors.white,
          elevation: 0,
          leading: IconButton(
            icon:
                const Icon(LucideIcons.chevronLeft, color: FacultyColors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course['name']?.toString() ?? 'Unknown Course',
                style: FacultyTextStyles.h3.copyWith(fontSize: 18),
              ),
              Text(
                '${course['code']} • ${course['branch']}',
                style: FacultyTextStyles.bodySmall.copyWith(
                  color: FacultyColors.gray500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            labelColor: FacultyColors.primary,
            unselectedLabelColor: FacultyColors.gray500,
            indicatorColor: FacultyColors.primary,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Attendance'),
              Tab(text: 'Students'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.settings,
                  color: FacultyColors.gray500, size: 20),
              onPressed: () {},
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StartSessionScreen(course: course),
              ),
            );
          },
          backgroundColor: FacultyColors.black,
          icon: const Icon(LucideIcons.qrCode,
              color: FacultyColors.white, size: 20),
          label: const Text('Start Session',
              style: TextStyle(
                  color: FacultyColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(course: course, allCourses: allCourses),
            _AttendanceTab(course: course),
            _StudentsTab(course: course),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> course;
  final List<Map<String, dynamic>> allCourses;
  const _OverviewTab({required this.course, required this.allCourses});

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
              onPressed: () {},
              child: const Text('View All',
                  style: TextStyle(
                      color: FacultyColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
            context, 'Monday, 8 Mar', '9:30 AM - 10:30 AM', '42/50', true),
        _buildActivityItem(
            context, 'Friday, 5 Mar', '2:30 PM - 3:30 PM', '38/50', false),
        _buildActivityItem(
            context, 'Wednesday, 3 Mar', '11:30 AM - 12:30 PM', '45/50', true),
      ],
    );
  }

  Widget _buildQuickOverviewCard(BuildContext context) {
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
              _buildCompactMetric(LucideIcons.users, 'Enrolled',
                  (course['students'] ?? 0).toString(), FacultyColors.blue600),
              _buildDivider(),
              _buildCompactMetric(LucideIcons.award, 'Credits',
                  (course['credits'] ?? 0).toString(), FacultyColors.yellow700),
              _buildDivider(),
              _buildCompactMetric(
                  LucideIcons.calendar,
                  'Year',
                  (course['year']?.toString() ?? 'N/A').split(' ')[0],
                  FacultyColors.primary),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildCompactMetric(
                  LucideIcons.layers,
                  'Semester',
                  course['semester']?.toString() ?? 'N/A',
                  FacultyColors.green600),
              _buildDivider(),
              _buildCompactMetric(
                  LucideIcons.history,
                  'Acad Year',
                  course['academicYear']?.toString() ?? '2023-24',
                  FacultyColors.blue500),
              _buildDivider(),
              _buildCompactMetric(
                  LucideIcons.clock,
                  'Session',
                  (course['session']?.toString() ?? 'Autumn').split(' ')[0],
                  FacultyColors.gray600),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: FacultyColors.gray100),
          const SizedBox(height: 20),
          InkWell(
            onTap: () {
              // Convert mock data maps to Course model objects with robust type handling
              final List<fm.Course> coursesList = allCourses.map((c) {
                return fm.Course(
                  id: (c['id'] ?? '').toString(),
                  code: (c['code'] ?? '').toString(),
                  name: (c['name'] ?? '').toString(),
                  section: (c['section'] ?? 'A').toString(),
                  enrolledCount:
                      int.tryParse(c['students']?.toString() ?? '0') ?? 0,
                  joinCode: (c['joinCode'] ?? '').toString(),
                  department: (c['branch'] ?? '').toString(),
                  academicYear: (c['academicYear'] ?? '2023-24').toString(),
                  credits: int.tryParse(c['credits']?.toString() ?? '3') ?? 3,
                  semester: (c['semester'] ?? '1').toString(),
                  session: (c['session'] ?? 'Autumn').toString(),
                  timetable: [
                    fm.TimetableSlot(
                        day: 'Monday',
                        time: '09:00 AM',
                        type: 'theory',
                        room: 'LT-1'),
                    fm.TimetableSlot(
                        day: 'Wednesday',
                        time: '11:00 AM',
                        type: 'theory',
                        room: 'LT-1'),
                  ],
                );
              }).toList();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FacultyWeeklyTimetableScreen(
                    courses: coursesList,
                    highlightCourseCode: (course['code'] ?? '').toString(),
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: FacultyColors.blue50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.calendar,
                      size: 20, color: FacultyColors.blue600),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Next Class',
                          style: TextStyle(
                              color: FacultyColors.gray500,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                      Text('Tomorrow, 09:00 AM - 10:00 AM',
                          style: TextStyle(
                              color: FacultyColors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight,
                    size: 18, color: FacultyColors.gray400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 32,
      width: 1,
      color: FacultyColors.gray100,
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

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
                  style: const TextStyle(
                      color: FacultyColors.gray500,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: FacultyTextStyles.h2
                  .copyWith(fontSize: 18, color: FacultyColors.black)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, String date, String time,
      String attendance, bool isLab) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SessionDetailsScreen(
              course: course,
              dateStr: date,
              timeStr: time,
              totalStudents: 50,
              presentCount: int.tryParse(attendance.split('/')[0]) ?? 42,
            ),
          ),
        );
      },
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
                  Text(time,
                      style: FacultyTextStyles.bodySmall.copyWith(
                          color: FacultyColors.gray500, fontSize: 12)),
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
                    style:
                        TextStyle(color: FacultyColors.gray400, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceTab extends StatelessWidget {
  final Map<String, dynamic> course;
  const _AttendanceTab({required this.course});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 10,
      itemBuilder: (context, index) {
        return _buildSessionCard(context, index);
      },
    );
  }

  Widget _buildSessionCard(BuildContext context, int index) {
    final date = DateTime.now().subtract(Duration(days: index * 2));
    final String dateStr = '${date.day} ${_getMonth(date.month)} ${date.year}';

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
                  const Text('Lecture Session • 1 hour',
                      style: TextStyle(
                          color: FacultyColors.gray500, fontSize: 12)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: FacultyColors.green50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('85%',
                    style: TextStyle(
                        color: FacultyColors.green700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('Present', '42', FacultyColors.green600),
              _buildMetric('Absent', '8', FacultyColors.red600),
              _buildMetric('Total', '50', FacultyColors.gray600),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SessionDetailsScreen(
                        course: course,
                        dateStr: dateStr,
                        timeStr: '9:30 AM - 10:30 AM', // Mock time
                        totalStudents: 50,
                        presentCount: 42,
                      ),
                    ),
                  );
                },
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

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label,
            style: const TextStyle(color: FacultyColors.gray500, fontSize: 11)),
      ],
    );
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}

class _StudentsTab extends StatelessWidget {
  final Map<String, dynamic> course;
  const _StudentsTab({required this.course});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: TextField(
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
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: 15,
            itemBuilder: (context, index) {
              return _buildStudentTile(context, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStudentTile(BuildContext context, int index) {
    final attendance = 70 + (index * 2) % 30; // Mock attendance %
    final statusColor = attendance > 85
        ? FacultyColors.green600
        : (attendance > 75 ? FacultyColors.primary : FacultyColors.red600);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentStatsScreen(
              studentName: 'Student Name ${index + 1}',
              rollNo: '2022CSB0${65 + index}',
              courseName: course['name'] ?? 'Course',
            ),
          ),
        );
      },
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
                '${65 + index}', // Mock roll number last digits
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
                  Text('Student Name ${index + 1}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('Roll: 2022CSB0${65 + index}',
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
                    style:
                        TextStyle(color: FacultyColors.gray400, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
