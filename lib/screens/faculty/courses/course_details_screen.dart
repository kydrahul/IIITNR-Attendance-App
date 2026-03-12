import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/faculty/faculty_colors.dart';
import '../../../constants/faculty/faculty_text_styles.dart';
import '../../../models/faculty/faculty_models.dart' as fm;
import '../../../utils/faculty/pdf_generator.dart';
import '../faculty_weekly_timetable_screen.dart';
import 'session_details_screen.dart';
import 'student_stats_screen.dart';
import 'start_session_screen.dart';
import 'widgets/join_code_dialog.dart';

import '../../../services/faculty/faculty_api_service.dart';

class CourseDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> course;
  final List<Map<String, dynamic>> allCourses;

  const CourseDetailsScreen({
    super.key,
    required this.course,
    required this.allCourses,
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  final FacultyApiService _apiService = FacultyApiService();
  bool _isLoading = true;
  List<dynamic> _sessions = [];
  List<dynamic> _students = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCourseData();
  }

  Future<void> _fetchCourseData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final courseId = widget.course['id']?.toString() ?? '';
      if (courseId.isEmpty) throw Exception('Course ID is missing');

      final gridData = await _apiService.getCourseAttendanceGrid(courseId);
      
      if (mounted) {
        setState(() {
          _sessions = gridData['sessions'] ?? [];
          // Sort sessions by date descending for activity/overview
          _sessions.sort((a, b) {
            final dateA = DateTime.parse(a['date'].toString());
            final dateB = DateTime.parse(b['date'].toString());
            return dateB.compareTo(dateA);
          });
          _students = gridData['students'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String filterTypeSelection = 'All Students';
        double customThresholdPerc = 75.0;
        final TextEditingController customController =
            TextEditingController(text: '75');

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Export Attendance',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('All Students',
                        style: TextStyle(fontSize: 14)),
                    value: 'All Students',
                    groupValue: filterTypeSelection,
                    onChanged: (val) => setDialogState(() => filterTypeSelection = val!),
                    activeColor: FacultyColors.primary,
                  ),
                  RadioListTile<String>(
                    title: const Text('Below 75%',
                        style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Defaulters list',
                        style: TextStyle(fontSize: 11)),
                    value: 'Below 75%',
                    groupValue: filterTypeSelection,
                    onChanged: (val) => setDialogState(() => filterTypeSelection = val!),
                    activeColor: FacultyColors.primary,
                  ),
                  RadioListTile<String>(
                    title: const Text('Custom Threshold',
                        style: TextStyle(fontSize: 14)),
                    value: 'Custom',
                    groupValue: filterTypeSelection,
                    onChanged: (val) => setDialogState(() => filterTypeSelection = val!),
                    activeColor: FacultyColors.primary,
                  ),
                  if (filterTypeSelection == 'Custom')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextField(
                        controller: customController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Percentage below...',
                          suffixText: '%',
                          isDense: true,
                        ),
                        onChanged: (val) {
                          customThresholdPerc = double.tryParse(val) ?? 75.0;
                        },
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: FacultyColors.gray500)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    AttendancePdfGenerator.generateAndShare(
                      courseName: widget.course['name'] ?? 'Course',
                      courseCode: widget.course['code'] ?? 'N/A',
                      students: _students,
                      filterType: filterTypeSelection,
                      customThreshold:
                          filterTypeSelection == 'Custom' ? customThresholdPerc : null,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FacultyColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Export PDF',
                      style: TextStyle(color: FacultyColors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
                widget.course['name']?.toString() ?? 'Unknown Course',
                style: GoogleFonts.montserrat(
                  color: FacultyColors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${widget.course['code']}  |  ${widget.course['degree'] ?? 'B.Tech'}  |  ${widget.course['academicYear']?.toString().toLowerCase().contains('year') == true ? widget.course['academicYear'] : "${widget.course['academicYear'] ?? 'N/A'} Year"}  |  ${widget.course['credits'] ?? '3'} Credits',
                style: GoogleFonts.roboto(
                  color: FacultyColors.gray500,
                  fontSize: 11,
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
            PopupMenuButton<String>(
              icon: const Icon(LucideIcons.moreVertical,
                  color: FacultyColors.gray500, size: 20),
              onSelected: (value) {
                if (value == 'join_code') {
                  JoinCodeDialog.show(
                    context,
                    widget.course['name']?.toString() ?? 'Course',
                    widget.course['code']?.toString() ?? '',
                    widget.course['joinCode']?.toString() ?? '',
                  );
                } else if (value == 'export_attendance') {
                  _showExportDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'join_code',
                  child: Row(
                    children: [
                      Icon(LucideIcons.key, size: 16, color: FacultyColors.gray600),
                      SizedBox(width: 8),
                      Text('Show Joining Code', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export_attendance',
                  child: Row(
                    children: [
                      Icon(LucideIcons.fileOutput, size: 16, color: FacultyColors.gray600),
                      SizedBox(width: 8),
                      Text('Export Attendance', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StartSessionScreen(course: widget.course),
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.alertCircle, color: FacultyColors.red600, size: 48),
                        const SizedBox(height: 16),
                        Text('Error: $_errorMessage', style: const TextStyle(color: FacultyColors.red600)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _fetchCourseData, child: const Text('Retry')),
                      ],
                    ),
                  )
                : TabBarView(
                    children: [
            _OverviewTab(
              course: widget.course,
              allCourses: widget.allCourses,
              sessions: _sessions,
              studentCount: _students.length,
            ),
            _AttendanceTab(
              course: widget.course,
              sessions: _sessions,
            ),
            _StudentsTab(
              course: widget.course,
              students: _students,
              allSessions: _sessions,
            ),
                    ],
                  ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> course;
  final List<Map<String, dynamic>> allCourses;
  final List<dynamic> sessions;
  final int studentCount;

  const _OverviewTab({
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
              onPressed: () {
                DefaultTabController.of(context).animateTo(1);
              },
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
              child: Text('No recent activity yet', style: TextStyle(color: FacultyColors.gray500)),
            ),
          )
        else
          ...sessions.take(5).map((session) {
            // Priority: startTimeIso -> date -> startTime
            final String? iso = session['startTimeIso'];
            final String? dateField = session['date']?.toString();
            DateTime localDateTime;
            
            if (iso != null && DateTime.tryParse(iso) != null) {
              localDateTime = DateTime.parse(iso).toLocal();
            } else if (dateField != null && DateTime.tryParse(dateField) != null) {
              localDateTime = DateTime.parse(dateField).toLocal();
            } else {
              localDateTime = DateTime.now();
            }

            final dateStr = '${localDateTime.day} ${_getMonth(localDateTime.month)}';
            return _buildActivityItem(
              context,
              dateStr,
              session,
            );
          }),
      ],
    );
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildQuickOverviewCard(BuildContext context) {
    final String acadYear = (course['academicYear']?.toString() ?? 'N/A');
    final String sem = _getOrdinal(course['semester']?.toString() ?? 'N/A');
    final String sessionStr = course['session']?.toString() ?? 'Autumn';

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
              _buildCompactMetric(LucideIcons.users, 'STUDENTS',
                  studentCount.toString(), FacultyColors.blue600),
              _buildVerticalDivider(),
              _buildCompactMetric(
                  LucideIcons.layers,
                   'SEMESTER',
                  sem,
                   FacultyColors.green600),
              _buildVerticalDivider(),
              _buildCompactMetric(
                  LucideIcons.briefcase,
                   'BRANCH',
                  course['department']?.toString() ?? course['branch']?.toString() ?? 'N/A',
                  FacultyColors.gray500),
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
                department: (course['department'] ?? course['branch'] ?? '').toString(),
                academicYear: acadYear,
                credits: int.tryParse(course['credits']?.toString() ?? '3') ?? 3,
                semester: (course['semester'] ?? '').toString(),
                session: sessionStr,
                timetable: (course['timetable'] as List?)
                    ?.map((t) => fm.TimetableSlot.fromJson(t))
                    .toList() ?? [],
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FacultyWeeklyTimetableScreen(
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
                    color: const Color(0xFFEFF6FF), // Very light blue
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(LucideIcons.calendar,
                      size: 24, color: Color(0xFF2563EB)), // Primary blue
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
                        final info = _getNextClassInfo(course);
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

  String _getOrdinal(String n) {
    if (n == 'N/A') return n;
    final i = int.tryParse(n);
    if (i == null) return n;
    if (i % 100 >= 11 && i % 100 <= 13) return '${i}th';
    switch (i % 10) {
      case 1:
        return '${i}st';
      case 2:
        return '${i}nd';
      case 3:
        return '${i}rd';
      default:
        return '${i}th';
    }
  }

  String _getNextClassInfo(Map<String, dynamic> courseData) {
    try {
      final timetable = courseData['timetable'] as List?;
      if (timetable == null || timetable.isEmpty) return 'No schedule set';

      final now = DateTime.now();
      final List<String> days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];

      for (int i = 0; i < 7; i++) {
        final checkDayIndex = (now.weekday - 1 + i) % 7;
        final checkDayName = days[checkDayIndex];
        final daySlots =
            timetable.where((s) => s['day'] == checkDayName).toList();

        if (daySlots.isNotEmpty) {
          final prefix = i == 0 ? 'Today' : (i == 1 ? 'Tomorrow' : checkDayName);
          return '$prefix|${daySlots.first['time'] ?? 'N/A'}';
        }
      }
      return 'No upcoming classes';
    } catch (e) {
      return 'Check schedule';
    }
  }

   Widget _buildVerticalDivider() {
    return Container(
      height: 32,
      width: 1,
      color: FacultyColors.gray100,
      margin: const EdgeInsets.symmetric(horizontal: 12),
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

  Widget _buildActivityItem(BuildContext context, String date, dynamic session) {
    // Priority: startTimeIso -> date -> startTime
    final String? iso = session['startTimeIso'];
    final String? dateField = session['date']?.toString();
    DateTime localDateTime;
    
    if (iso != null && DateTime.tryParse(iso) != null) {
      localDateTime = DateTime.parse(iso).toLocal();
    } else if (dateField != null && DateTime.tryParse(dateField) != null) {
      localDateTime = DateTime.parse(dateField).toLocal();
    } else {
      localDateTime = DateTime.now();
    }

    final String hour = localDateTime.hour > 12 ? (localDateTime.hour - 12).toString() : (localDateTime.hour == 0 ? "12" : localDateTime.hour.toString());
    final String minute = localDateTime.minute.toString().padLeft(2, '0');
    final String ampm = localDateTime.hour >= 12 ? "PM" : "AM";
    final String time = "$hour:$minute $ampm";
    
    final String attendance = '${session['presentCount'] ?? 0}/${session['totalStudents'] ?? 0}';
    final String type = (session['type'] ?? session['classType'] ?? 'Theory').toString();
    final String room = (session['roomNumber'] ?? session['room'] ?? 'N/A').toString();
    final bool isLab = type.toLowerCase().contains('lab');

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SessionDetailsScreen(
              course: course,
              dateStr: date,
              timeStr: time,
              totalStudents: session['totalStudents'] ?? 0,
              presentCount: session['presentCount'] ?? 0,
              sessionId: session['id']?.toString(),
              roomNumber: room,
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
                  Text('$time • $type • Room: $room',
                      style: FacultyTextStyles.bodySmall.copyWith(
                          color: FacultyColors.gray500, fontSize: 12),
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
  final List<dynamic> sessions;

  const _AttendanceTab({
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
      itemBuilder: (context, index) {
        return _buildSessionCard(context, sessions[index]);
      },
    );
  }

  Widget _buildSessionCard(BuildContext context, dynamic session) {
    // Priority: startTimeIso -> date -> startTime
    final String? iso = session['startTimeIso'];
    final String? dateField = session['date']?.toString();
    DateTime localDateTime;
    
    if (iso != null && DateTime.tryParse(iso) != null) {
      localDateTime = DateTime.parse(iso).toLocal();
    } else if (dateField != null && DateTime.tryParse(dateField) != null) {
      localDateTime = DateTime.parse(dateField).toLocal();
    } else {
      localDateTime = DateTime.now();
    }

    final String dateStr = '${localDateTime.day} ${_getMonth(localDateTime.month)} ${localDateTime.year}';
    
    final String hour = localDateTime.hour > 12 ? (localDateTime.hour - 12).toString() : (localDateTime.hour == 0 ? "12" : localDateTime.hour.toString());
    final String minute = localDateTime.minute.toString().padLeft(2, '0');
    final String ampm = localDateTime.hour >= 12 ? "PM" : "AM";
    final String startTime = "$hour:$minute $ampm";
    
    final String room = session['roomNumber']?.toString() ?? session['room']?.toString() ?? 'N/A';

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
                  Text('${session['type'] ?? session['classType'] ?? 'Theory'} Session',
                      style: const TextStyle(
                          color: FacultyColors.gray500, fontSize: 12)),
                ],
              ),
              // Note: Percentage and metrics would ideally come from the grid summary
              // For now, we show the room and time info clearly
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetric('Time', startTime, FacultyColors.blue600),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetric('Room', room, FacultyColors.gray600),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SessionDetailsScreen(
                        course: course,
                        dateStr: dateStr,
                        timeStr: startTime,
                        totalStudents: session['totalStudents'] ?? 0,
                        presentCount: session['presentCount'] ?? 0,
                        sessionId: session['id']?.toString(),
                        roomNumber: room,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _StudentsTab extends StatefulWidget {
  final Map<String, dynamic> course;
  final List<dynamic> students;
  final List<dynamic> allSessions;

  const _StudentsTab({
    required this.course,
    required this.students,
    required this.allSessions,
  });

  @override
  State<_StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<_StudentsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = widget.students.where((s) {
      final name = s['name']?.toString().toLowerCase() ?? '';
      final rollNo = s['rollNo']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || rollNo.contains(query);
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
          child: filteredStudents.isEmpty
              ? const Center(child: Text('No students found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    return _buildStudentTile(context, filteredStudents[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStudentTile(BuildContext context, dynamic student) {
    final attendance = student['attendancePercentage'] ?? 0;
    final name = student['name'] ?? 'Unknown';
    final rollNo = (student['rollNo'] ?? student['rollNumber'] ?? 'N/A').toString();
    final statusColor = attendance > 85
        ? FacultyColors.green600
        : (attendance > 75 ? FacultyColors.primary : FacultyColors.red600);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentStatsScreen(
              studentName: name,
              rollNo: rollNo,
              courseName: widget.course['name'] ?? 'Course',
              allSessions: widget.allSessions,
              studentSessions: student['sessions'],
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
                rollNo.length > 2 ? rollNo.substring(rollNo.length - 2) : rollNo,
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
