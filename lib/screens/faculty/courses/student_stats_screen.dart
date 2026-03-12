import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/faculty/faculty_colors.dart';
import '../../../constants/faculty/faculty_text_styles.dart';
import 'dart:math';

class StudentStatsScreen extends StatefulWidget {
  final String studentName;
  final String rollNo;
  final String courseName;
  final List<dynamic>? allSessions;
  final Map<String, dynamic>? studentSessions;

  const StudentStatsScreen({
    super.key,
    required this.studentName,
    required this.rollNo,
    required this.courseName,
    this.allSessions,
    this.studentSessions,
  });

  @override
  State<StudentStatsScreen> createState() => _StudentStatsScreenState();
}

class _StudentStatsScreenState extends State<StudentStatsScreen> {
  String _selectedFilter = 'All'; // 'All', 'Present', 'Absent'

  // Mock data
  int _totalClasses = 0;
  int _presentCount = 0;
  int _absentCount = 0;

  List<Map<String, dynamic>> _classHistory = [];

  @override
  void initState() {
    super.initState();
    if (widget.allSessions != null && widget.studentSessions != null) {
      _processRealHistory();
    } else {
      _generateMockHistory();
    }
  }

  void _processRealHistory() {
    List<Map<String, dynamic>> history = [];
    final sessions = widget.allSessions!;
    final attendanceMap = widget.studentSessions!;

    for (var session in sessions) {
      final sessionId = session['id'];
      final status = attendanceMap[sessionId] ?? 'absent';
      
      DateTime date;
      try {
        if (session['date'] is String) {
          date = DateTime.parse(session['date']);
        } else if (session['date'] != null) {
          date = (session['date'] as dynamic).toDate();
        } else {
          date = DateTime.now();
        }
      } catch (e) {
        date = DateTime.now();
      }

      history.add({
        'id': sessionId,
        'date': _formatDate(date),
        'time': session['startTime'] ?? 'N/A',
        'type': session['type'] ?? 'Theory Session',
        'isPresent': status == 'present',
      });
    }

    // Sort history by date descending
    // We already sorted them in CourseDetailsScreen, but safe to do again if needed
    // Actually the widget.allSessions is already sorted descending in CourseDetailsScreen

    setState(() {
      _classHistory = history;
      _presentCount = history.where((c) => c['isPresent']).length;
      _absentCount = history.where((c) => !c['isPresent']).length;
      _totalClasses = history.length;
    });
  }

  void _generateMockHistory() {
    Random random = Random(widget.rollNo.hashCode);

    List<Map<String, dynamic>> history = [];
    DateTime now = DateTime.now();

    for (int i = 0; i < 42; i++) {
      DateTime classDate =
          now.subtract(Duration(days: i * 2, hours: random.nextInt(5)));
      // deterministic mock presentation based on seed
      bool isPresent = random.nextDouble() > 0.15;

      history.add({
        'id': i,
        'date': _formatDate(classDate),
        'time':
            '${9 + random.nextInt(6)}:00 ${random.nextBool() ? 'AM' : 'PM'}',
        'type': random.nextBool() ? 'Theory Session' : 'Lab Session',
        'isPresent': isPresent,
      });
    }

    setState(() {
      _classHistory = history;
      _presentCount = history.where((c) => c['isPresent']).length;
      _absentCount = history.where((c) => !c['isPresent']).length;
      _totalClasses = history.length;
    });
  }

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Filter history
    List<Map<String, dynamic>> filteredHistory = _classHistory;
    if (_selectedFilter == 'Present') {
      filteredHistory = _classHistory.where((c) => c['isPresent']).toList();
    } else if (_selectedFilter == 'Absent') {
      filteredHistory = _classHistory.where((c) => !c['isPresent']).toList();
    }

    return Scaffold(
      backgroundColor: FacultyColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Stats',
              style: FacultyTextStyles.h3.copyWith(
                color: FacultyColors.black,
              ),
            ),
            Text(
              widget.courseName,
              style: FacultyTextStyles.bodySmall.copyWith(
                color: FacultyColors.gray500,
              ),
            ),
          ],
        ),
        backgroundColor: FacultyColors.white,
        foregroundColor: FacultyColors.gray800,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: FacultyColors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student Info Header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: FacultyColors.blue50,
                        radius: 32,
                        child: Text(
                          widget.studentName[0].toUpperCase(),
                          style: FacultyTextStyles.h2.copyWith(
                            color: FacultyColors.blue600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.studentName,
                              style: FacultyTextStyles.h3,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Roll No: ${widget.rollNo}',
                              style: FacultyTextStyles.bodyMedium.copyWith(
                                color: FacultyColors.gray600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_totalClasses > 0 ? ((_presentCount / _totalClasses) * 100).toStringAsFixed(1) : 0}%',
                            style: FacultyTextStyles.h2.copyWith(
                              color: _totalClasses > 0 &&
                                      ((_presentCount / _totalClasses) * 100) >=
                                          75
                                  ? FacultyColors.green600
                                  : FacultyColors.red600,
                            ),
                          ),
                          Text(
                            'Attendance',
                            style: FacultyTextStyles.label.copyWith(
                              color: FacultyColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total Classes',
                          value: _totalClasses.toString(),
                          icon: LucideIcons.calendarDays,
                          color: FacultyColors.blue600,
                          bgColor: FacultyColors.blue50,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Present',
                          value: _presentCount.toString(),
                          icon: LucideIcons.checkCircle2,
                          color: FacultyColors.green600,
                          bgColor: FacultyColors.green50,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Absent',
                          value: _absentCount.toString(),
                          icon: LucideIcons.xCircle,
                          color: FacultyColors.red600,
                          bgColor: FacultyColors.red50,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Class Stats Header
                  Text(
                    'Class History',
                    style: FacultyTextStyles.h4,
                  ),
                  const SizedBox(height: 16),

                  // Filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', _classHistory.length),
                        const SizedBox(width: 8),
                        _buildFilterChip('Present', _presentCount),
                        const SizedBox(width: 8),
                        _buildFilterChip('Absent', _absentCount),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // List of classes
          SliverPadding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final session = filteredHistory[index];
                  return _buildClassHistoryTile(session);
                },
                childCount: filteredHistory.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: FacultyTextStyles.h3.copyWith(color: FacultyColors.black),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: FacultyTextStyles.label.copyWith(
              color: FacultyColors.gray500,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? FacultyColors.primary : FacultyColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? FacultyColors.primary : FacultyColors.gray200,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: FacultyTextStyles.bodyMedium.copyWith(
                color: isSelected ? FacultyColors.white : FacultyColors.gray700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? FacultyColors.white.withOpacity(0.2)
                    : FacultyColors.gray100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: FacultyTextStyles.label.copyWith(
                  color:
                      isSelected ? FacultyColors.white : FacultyColors.gray600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassHistoryTile(Map<String, dynamic> session) {
    bool isPresent = session['isPresent'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FacultyColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FacultyColors.gray100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon part
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FacultyColors.gray50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              session['type'] == 'Theory Session'
                  ? LucideIcons.bookOpen
                  : LucideIcons.flaskConical,
              size: 20,
              color: FacultyColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          // Info part
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session['type'],
                  style: FacultyTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: FacultyColors.gray800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.calendarDays,
                        size: 14, color: FacultyColors.gray500),
                    const SizedBox(width: 4),
                    Text(
                      session['date'],
                      style: FacultyTextStyles.bodySmall.copyWith(
                        color: FacultyColors.gray600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(LucideIcons.clock,
                        size: 14, color: FacultyColors.gray500),
                    const SizedBox(width: 4),
                    Text(
                      session['time'],
                      style: FacultyTextStyles.bodySmall.copyWith(
                        color: FacultyColors.gray600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Status Part
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isPresent ? FacultyColors.green50 : FacultyColors.red50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isPresent ? 'Present' : 'Absent',
              style: FacultyTextStyles.label.copyWith(
                color:
                    isPresent ? FacultyColors.green700 : FacultyColors.red700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
