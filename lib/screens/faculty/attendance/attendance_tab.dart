import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/faculty/faculty_colors.dart';
import '../../../constants/faculty/faculty_text_styles.dart';
import '../../../models/faculty/faculty_models.dart';
import '../../../services/faculty/faculty_api_service.dart';
import '../../../services/report_service.dart';
import '../courses/start_session_screen.dart';
import 'widgets/course_selector.dart';
import 'widgets/session_history_list.dart';
import 'widgets/enrolled_students_list.dart';

/// Attendance Hub tab — lets faculty search/select a course, then view its
/// session history and enrolled students via an inner tab bar.
///
/// Sub-widgets: [CourseSelector], [SessionHistoryList], [EnrolledStudentsList].
class FacultyAttendanceTab extends StatefulWidget {
  final Course? initialCourse;
  const FacultyAttendanceTab({super.key, this.initialCourse});

  @override
  State<FacultyAttendanceTab> createState() => _FacultyAttendanceTabState();
}

class _FacultyAttendanceTabState extends State<FacultyAttendanceTab>
    with SingleTickerProviderStateMixin {
  final FacultyApiService _apiService = FacultyApiService();
  late TabController _tabController;

  Course? _selectedCourse;
  List<Course> _courses = [];

  bool _isLoadingGrid = false;
  List<dynamic> _gridSessions = [];
  List<dynamic> _gridStudents = [];

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedCourse = widget.initialCourse;
    _loadCourses();
    if (_selectedCourse != null) _loadAttendanceGrid(_selectedCourse!.id);
  }

  @override
  void didUpdateWidget(FacultyAttendanceTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCourse != null &&
        widget.initialCourse != _selectedCourse) {
      setState(() => _selectedCourse = widget.initialCourse);
      _loadAttendanceGrid(widget.initialCourse!.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Data loading ─────────────────────────────────────────────────────────

  Future<void> _loadCourses() async {
    try {
      final courses = await _apiService.listCourses();
      if (mounted) setState(() => _courses = courses);
    } catch (e) {
      debugPrint('Error loading courses: $e');
      if (mounted) setState(() => _courses = []);
    }
  }

  Future<void> _loadAttendanceGrid(String courseId) async {
    if (!mounted) return;
    setState(() => _isLoadingGrid = true);
    try {
      final response = await _apiService.getCourseAttendanceGrid(courseId);
      if (mounted) {
        setState(() {
          _gridSessions = response['sessions'] is List ? response['sessions'] : [];
          _gridStudents = response['students'] is List ? response['students'] : [];
          _isLoadingGrid = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading attendance grid: $e');
      if (mounted) setState(() => _isLoadingGrid = false);
    }
  }

  // ─── Event handlers ───────────────────────────────────────────────────────

  void _onCourseChanged(Course? course) {
    if (course == null) return;
    setState(() => _selectedCourse = course);
    _loadAttendanceGrid(course.id);
  }

  void _onClearCourse() => setState(() => _selectedCourse = null);

  void _navigateToStartSession() {
    if (_selectedCourse == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StartSessionScreen(course: {
          'id': _selectedCourse!.id,
          'code': _selectedCourse!.code,
          'name': _selectedCourse!.name,
          'semester': _selectedCourse!.semester,
          'students': _gridStudents,
        }),
      ),
    ).then((_) {
      if (_selectedCourse != null) _loadAttendanceGrid(_selectedCourse!.id);
    });
  }

  // ─── Today's quick picks ──────────────────────────────────────────────────

  String _todayName() {
    const days = [
      'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return days[DateTime.now().weekday - 1];
  }

  List<Course> _todayCourses() {
    final today = _todayName();
    return _courses.where((c) => c.timetable.any((t) => t.day == today)).toList();
  }

  String _todayTiming(Course course) {
    if (course.timetable.isEmpty) return 'No timing';
    final today = _todayName();
    return course.timetable
        .firstWhere((t) => t.day == today, orElse: () => course.timetable.first)
        .time;
  }

  // ─── Export ───────────────────────────────────────────────────────────────

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Export Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.users),
              title: const Text('All Students'),
              onTap: () { Navigator.pop(context); _exportReport('All'); },
            ),
            ListTile(
              leading: const Icon(LucideIcons.userX, color: Colors.red),
              title: const Text('Below 75%'),
              onTap: () { Navigator.pop(context); _exportReport('Below 75%'); },
            ),
            ListTile(
              leading: const Icon(LucideIcons.filter),
              title: const Text('Custom Percentage'),
              onTap: () { Navigator.pop(context); _showCustomThresholdDialog(); },
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomThresholdDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Custom Threshold'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Threshold (%)',
            hintText: 'e.g. 60',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                Navigator.pop(context);
                _exportReport('Custom', val);
              }
            },
            child: const Text('Export'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }


  Future<void> _exportReport(String filterType, [double? customVal]) async {
    if (_selectedCourse == null) return;
    try {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Generating PDF...')));
      final profile = await _apiService.getProfile();
      await ReportService.generateAttendanceReport(
        courseName: _selectedCourse!.name,
        courseCode: _selectedCourse!.code,
        facultyName: profile.name,
        students: _gridStudents,
        totalSessions: _gridSessions.length,
        filterType: filterType,
        customPercentage: customVal,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report generated successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to generate report: $e'),
            backgroundColor: FacultyColors.red600));
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: FacultyColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _selectedCourse == null
                    ? _buildIdleState()
                    : _buildCourseView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header (title + course selector) ─────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24).copyWith(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_selectedCourse != null)
                IconButton(
                  icon: const Icon(LucideIcons.arrowLeft,
                      color: FacultyColors.gray900),
                  padding: const EdgeInsets.only(right: 16),
                  constraints: const BoxConstraints(),
                  onPressed: _onClearCourse,
                ),
              Text('Attendance Hub',
                  style: FacultyTextStyles.h1
                      .copyWith(color: FacultyColors.gray900)),
              const Spacer(),
              if (_selectedCourse != null)
                PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.moreVertical,
                      color: FacultyColors.gray900),
                  onSelected: (v) {
                    if (v == 'export') _showExportDialog();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'export',
                      child: Row(children: [
                        Icon(LucideIcons.fileText,
                            size: 18, color: FacultyColors.gray700),
                        SizedBox(width: 12),
                        Text('Export Attendance'),
                      ]),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCourse != null
                ? 'Manage sessions for this course'
                : 'Select a course to start a QR session',
            style: FacultyTextStyles.bodyMedium.copyWith(
                color: FacultyColors.gray500, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          CourseSelector(
            selectedCourse: _selectedCourse,
            courses: _courses,
            onCourseChanged: _onCourseChanged,
            onClear: _onClearCourse,
          ),
        ],
      ),
    );
  }

  // ─── Idle state (no course selected) ─────────────────────────────────────

  Widget _buildIdleState() {
    if (_courses.isEmpty) return _buildNoCoursesState();
    final quickPicks = _todayCourses();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        if (quickPicks.isNotEmpty) ...[
          Text("Today's Classes",
              style:
                  FacultyTextStyles.h3.copyWith(color: FacultyColors.gray800)),
          const SizedBox(height: 12),
          ...quickPicks.map(_buildQuickPickCard),
          const SizedBox(height: 32),
        ],
        _buildLastSessionPlaceholder(),
      ],
    );
  }

  Widget _buildNoCoursesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                  color: FacultyColors.gray50, shape: BoxShape.circle),
              child: const Icon(LucideIcons.book,
                  size: 48, color: FacultyColors.gray400),
            ),
            const SizedBox(height: 24),
            Text('No Courses Available',
                style: FacultyTextStyles.h3
                    .copyWith(color: FacultyColors.gray900)),
            const SizedBox(height: 12),
            Text(
              "You haven't created any courses yet. Switch to the Courses tab to add your first course.",
              textAlign: TextAlign.center,
              style: FacultyTextStyles.bodyMedium.copyWith(
                  color: FacultyColors.gray500, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastSessionPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's Last Session",
            style:
                FacultyTextStyles.h3.copyWith(color: FacultyColors.gray800)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                    color: FacultyColors.gray50, shape: BoxShape.circle),
                child: const Icon(LucideIcons.history,
                    size: 32, color: FacultyColors.gray400),
              ),
              const SizedBox(height: 16),
              Text('No sessions conducted today',
                  style: FacultyTextStyles.bodyMedium
                      .copyWith(color: FacultyColors.gray500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickPickCard(Course course) {
    final yearDisplay =
        (course.academicYear.toLowerCase().contains('year'))
            ? course.academicYear
            : '${course.academicYear} Year';

    return GestureDetector(
      onTap: () => _onCourseChanged(course),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.name,
                      style: FacultyTextStyles.h4.copyWith(
                          color: FacultyColors.gray900,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    '${course.degree ?? 'B.Tech'}  |  $yearDisplay  |  Sem ${course.semester ?? 'N/A'}',
                    style: FacultyTextStyles.bodySmall.copyWith(
                        color: FacultyColors.gray500,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(_todayTiming(course),
                      style: FacultyTextStyles.bodySmall.copyWith(
                          color: FacultyColors.gray400,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: FacultyColors.gray900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Start Now',
                  style: FacultyTextStyles.bodySmall.copyWith(
                      color: FacultyColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Course selected view ─────────────────────────────────────────────────

  Widget _buildCourseView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: _buildStartSessionCard(),
        ),
        if (!_isLoadingGrid)
          TabBar(
            controller: _tabController,
            labelColor: FacultyColors.primary,
            unselectedLabelColor: FacultyColors.gray500,
            indicatorColor: FacultyColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Session History'),
              Tab(text: 'Enrolled Students'),
            ],
          ),
        Expanded(
          child: _isLoadingGrid
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    SessionHistoryList(
                      sessions: _gridSessions,
                      selectedCourse: _selectedCourse!,
                      students: _gridStudents,
                    ),
                    EnrolledStudentsList(
                      students: _gridStudents,
                      totalSessions: _gridSessions.length,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildStartSessionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FacultyColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FacultyColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.radio,
                  size: 28, color: FacultyColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Live Session capabilities available',
                  style: FacultyTextStyles.h3
                      .copyWith(color: FacultyColors.gray800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _navigateToStartSession,
              icon: const Icon(LucideIcons.play),
              label: const Text('Start New QR Session',
                  style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: FacultyColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
