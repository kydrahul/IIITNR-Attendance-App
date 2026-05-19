import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/faculty/faculty_colors.dart';
import '../../../utils/faculty/pdf_generator.dart';
import '../../../services/faculty/faculty_api_service.dart';
import 'start_session_screen.dart';
import 'widgets/join_code_dialog.dart';
import 'tabs/overview_tab.dart';
import 'tabs/attendance_tab.dart';
import 'tabs/students_tab.dart';
import 'tabs/requests_tab.dart';

/// Displays detailed information for a single course split across 4 tabs:
/// Overview · Attendance · Students · Requests (summer-only).
///
/// All data fetching lives here; each tab receives plain data via constructor.
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
  List<Map<String, dynamic>> _joinRequests = [];
  String? _errorMessage;

  bool get _isSummerCourse => widget.course['session'] == 'Summer';

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchCourseData();
    if (_isSummerCourse) _fetchJoinRequests();
  }

  // ─── Data fetching ────────────────────────────────────────────────────────

  Future<void> _fetchCourseData() async {
    final courseId = widget.course['id']?.toString() ?? '';
    if (courseId.isEmpty) return;

    try {
      // 1. Cache-first render
      final cached =
          await _apiService.getCourseAttendanceGrid(courseId, forceRefresh: false);
      if (cached.isNotEmpty) _updateUI(cached);

      // 2. Fresh data in background
      final fresh =
          await _apiService.getCourseAttendanceGrid(courseId, forceRefresh: true);
      _updateUI(fresh);
    } catch (e) {
      if (mounted && _sessions.isEmpty) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _updateUI(Map<String, dynamic> gridData) {
    if (!mounted) return;
    final List<dynamic> sessions = gridData['sessions'] ?? [];
    sessions.sort((a, b) {
      try {
        return DateTime.parse(b['date'].toString())
            .compareTo(DateTime.parse(a['date'].toString()));
      } catch (_) {
        return 0;
      }
    });
    setState(() {
      _sessions = sessions;
      _students = gridData['students'] ?? [];
      _isLoading = false;
      _errorMessage = null;
    });
  }

  Future<void> _fetchJoinRequests() async {
    try {
      final courseId = widget.course['id']?.toString() ?? '';
      if (courseId.isEmpty) return;
      final requests = await _apiService.getJoinRequests(courseId);
      if (mounted) setState(() => _joinRequests = requests);
    } catch (e) {
      debugPrint('Failed to fetch join requests: $e');
    }
  }

  Future<void> _reviewRequest(String enrollmentId, String action) async {
    try {
      final courseId = widget.course['id']?.toString() ?? '';
      await _apiService.reviewJoinRequest(courseId, enrollmentId, action);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(action == 'approve' ? '✅ Intern approved!' : '❌ Request denied'),
          backgroundColor: action == 'approve' ? Colors.green : Colors.red,
        ));
        _fetchJoinRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── Export dialog ────────────────────────────────────────────────────────

  void _showExportDialog() {
    // Controller is created outside the builder so it can be properly disposed
    // when the dialog closes, regardless of which button is pressed.
    final customController = TextEditingController(text: '75');
    showDialog(
      context: context,
      builder: (context) {
        String filterType = 'All Students';
        double customThreshold = 75.0;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Export Attendance',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('All Students',
                      style: TextStyle(fontSize: 14)),
                  value: 'All Students',
                  groupValue: filterType,
                  onChanged: (v) => setDialogState(() => filterType = v!),
                  activeColor: FacultyColors.primary,
                ),
                RadioListTile<String>(
                  title: const Text('Below 75%',
                      style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Defaulters list',
                      style: TextStyle(fontSize: 11)),
                  value: 'Below 75%',
                  groupValue: filterType,
                  onChanged: (v) => setDialogState(() => filterType = v!),
                  activeColor: FacultyColors.primary,
                ),
                RadioListTile<String>(
                  title: const Text('Custom Threshold',
                      style: TextStyle(fontSize: 14)),
                  value: 'Custom',
                  groupValue: filterType,
                  onChanged: (v) => setDialogState(() => filterType = v!),
                  activeColor: FacultyColors.primary,
                ),
                if (filterType == 'Custom')
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
                      onChanged: (v) =>
                          customThreshold = double.tryParse(v) ?? 75.0,
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
                    filterType: filterType,
                    customThreshold:
                        filterType == 'Custom' ? customThreshold : null,
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
          ),
        );
      },
    ).whenComplete(customController.dispose);
  }


  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tabCount = _isSummerCourse ? 4 : 3;

    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        backgroundColor: FacultyColors.background,
        appBar: _buildAppBar(),
        floatingActionButton: _buildFab(),
        body: _buildBody(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: FacultyColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.chevronLeft, color: FacultyColors.black),
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
            widget.course['session'] == 'Summer'
                ? 'Summer 2026'
                : '${widget.course['code']}  |  '
                    '${widget.course['degree'] ?? 'B.Tech'}  |  '
                    '${widget.course['academicYear'] ?? 'N/A'}  |  '
                    '${widget.course['credits'] ?? '3'} Credits',
            style: GoogleFonts.roboto(
              color: FacultyColors.gray500,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      bottom: TabBar(
        labelColor: FacultyColors.primary,
        unselectedLabelColor: FacultyColors.gray500,
        indicatorColor: FacultyColors.primary,
        indicatorWeight: 3,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: [
          const Tab(text: 'Overview'),
          const Tab(text: 'Attendance'),
          const Tab(text: 'Students'),
          if (_isSummerCourse) _buildRequestsTab(),
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
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'join_code',
              child: Row(children: [
                Icon(LucideIcons.key, size: 16, color: FacultyColors.gray600),
                SizedBox(width: 8),
                Text('Show Joining Code', style: TextStyle(fontSize: 13)),
              ]),
            ),
            PopupMenuItem(
              value: 'export_attendance',
              child: Row(children: [
                Icon(LucideIcons.fileOutput,
                    size: 16, color: FacultyColors.gray600),
                SizedBox(width: 8),
                Text('Export Attendance', style: TextStyle(fontSize: 13)),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  Tab _buildRequestsTab() {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Requests'),
          if (_joinRequests.isNotEmpty) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_joinRequests.length}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StartSessionScreen(course: widget.course),
        ),
      ),
      backgroundColor: FacultyColors.black,
      icon: const Icon(LucideIcons.qrCode, color: FacultyColors.white, size: 20),
      label: const Text('Start Session',
          style: TextStyle(
              color: FacultyColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14)),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle,
                color: FacultyColors.red600, size: 48),
            const SizedBox(height: 16),
            Text('Error: $_errorMessage',
                style: const TextStyle(color: FacultyColors.red600)),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _fetchCourseData, child: const Text('Retry')),
          ],
        ),
      );
    }

    return TabBarView(
      children: [
        OverviewTab(
          course: widget.course,
          allCourses: widget.allCourses,
          sessions: _sessions,
          studentCount: _students.length,
        ),
        CourseAttendanceTab(
          course: widget.course,
          sessions: _sessions,
        ),
        StudentsTab(
          course: widget.course,
          students: _students,
          allSessions: _sessions,
        ),
        if (_isSummerCourse)
          RequestsTab(
            requests: _joinRequests,
            onReview: _reviewRequest,
            onRefresh: _fetchJoinRequests,
          ),
      ],
    );
  }
}
