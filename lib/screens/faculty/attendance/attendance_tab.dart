import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/faculty/faculty_colors.dart';
import '../../../constants/faculty/faculty_text_styles.dart';
import '../../../models/faculty/faculty_models.dart';
import '../../../services/faculty/faculty_api_service.dart';
import '../../../services/report_service.dart';
import '../courses/start_session_screen.dart';
import '../courses/session_details_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedCourse = widget.initialCourse;
    _loadCourses();
    if (_selectedCourse != null) {
      _loadAttendanceGrid(_selectedCourse!.id);
    }
  }

  @override
  void didUpdateWidget(FacultyAttendanceTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCourse != null &&
        widget.initialCourse != _selectedCourse) {
      setState(() {
        _selectedCourse = widget.initialCourse;
      });
      _loadAttendanceGrid(widget.initialCourse!.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await _apiService.listCourses();
      if (mounted) {
        setState(() => _courses = courses);
      }
    } catch (e) {
      debugPrint('Error loading courses: $e');
      if (mounted) {
        setState(() => _courses = []);
      }
    }
  }

  Future<void> _loadAttendanceGrid(String courseId) async {
    if (!mounted) return;
    setState(() => _isLoadingGrid = true);
    try {
      final response = await _apiService.getCourseAttendanceGrid(courseId);
      if (mounted) {
        setState(() {
          final sessionsData = response['sessions'];
          final studentsData = response['students'];
          _gridSessions = (sessionsData is List) ? sessionsData : [];
          _gridStudents = (studentsData is List) ? studentsData : [];
          _isLoadingGrid = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading attendance grid: $e');
      if (mounted) {
        setState(() => _isLoadingGrid = false);
      }
    }
  }

  void _onCourseChanged(Course? course) {
    if (course == null) return;
    setState(() {
      _selectedCourse = course;
    });
    _loadAttendanceGrid(course.id);
  }

  void _navigateToStartSession() {
    if (_selectedCourse == null) return;

    final courseMap = {
      'id': _selectedCourse!.id,
      'code': _selectedCourse!.code,
      'name': _selectedCourse!.name,
      'semester': _selectedCourse!.semester,
      'students': _gridStudents,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartSessionScreen(course: courseMap),
      ),
    ).then((_) {
      // Reload history on return in case new session was made
      if (_selectedCourse != null) {
        _loadAttendanceGrid(_selectedCourse!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: FacultyColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0).copyWith(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_selectedCourse != null) ...[
                          IconButton(
                            icon: const Icon(LucideIcons.arrowLeft,
                                color: FacultyColors.gray900),
                            padding: const EdgeInsets.only(right: 16),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _selectedCourse = null;
                              });
                            },
                          ),
                        ],
                        Text('Attendance Hub',
                            style: FacultyTextStyles.h1
                                .copyWith(color: FacultyColors.gray900)),
                        const Spacer(),
                        if (_selectedCourse != null)
                          PopupMenuButton<String>(
                            icon: const Icon(LucideIcons.moreVertical,
                                color: FacultyColors.gray900),
                            onSelected: (value) {
                              if (value == 'export') {
                                _showExportDialog();
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'export',
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.fileText,
                                        size: 18, color: FacultyColors.gray700),
                                    SizedBox(width: 12),
                                    Text('Export Attendance'),
                                  ],
                                ),
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
                          color: FacultyColors.gray500,
                          fontWeight: FontWeight.w500,
                        )),
                    const SizedBox(height: 24),
                    _buildCourseSelector(),
                  ],
                ),
              ),
              Expanded(
                child: _selectedCourse == null
                    ? _buildDisabledState()
                    : _buildCourseDetailsView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseSelector() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<Course>(
          key: ValueKey(_selectedCourse?.id),
          initialValue: _selectedCourse != null
              ? TextEditingValue(
                  text: [
                  if (_selectedCourse!.department.isNotEmpty)
                    _selectedCourse!.department,
                  if (_selectedCourse!.semester != null &&
                      _selectedCourse!.semester!.isNotEmpty)
                    'Sem ${_selectedCourse!.semester}',
                  _selectedCourse!.name
                ].join(' - '))
              : TextEditingValue.empty,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return _courses;
            }
            return _courses.where((Course option) {
              final query = textEditingValue.text.toLowerCase();
              return option.name.toLowerCase().contains(query) ||
                  option.code.toLowerCase().contains(query);
            });
          },
          displayStringForOption: (Course option) => [
            if (option.department.isNotEmpty) option.department,
            if (option.semester != null && option.semester!.isNotEmpty)
              'Sem ${option.semester}',
            option.name
          ].join(' - '),
          onSelected: _onCourseChanged,
          fieldViewBuilder: (BuildContext context,
              TextEditingController textEditingController,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted) {
            if (_selectedCourse == null &&
                textEditingController.text.isNotEmpty &&
                !focusNode.hasFocus) {
              textEditingController.text = '';
            } else if (_selectedCourse != null && !focusNode.hasFocus) {
              final expectedText = [
                if (_selectedCourse!.department.isNotEmpty)
                  _selectedCourse!.department,
                if (_selectedCourse!.semester != null &&
                    _selectedCourse!.semester!.isNotEmpty)
                  'Sem ${_selectedCourse!.semester}',
                _selectedCourse!.name
              ].join(' - ');
              if (textEditingController.text != expectedText) {
                textEditingController.text = expectedText;
              }
            }

            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              onFieldSubmitted: (String value) {
                onFieldSubmitted();
              },
              decoration: InputDecoration(
                hintText: 'Search for a course...',
                hintStyle: FacultyTextStyles.bodyMedium
                    .copyWith(color: FacultyColors.gray400),
                prefixIcon: const Icon(LucideIcons.search,
                    color: FacultyColors.gray400, size: 20),
                suffixIcon: _selectedCourse != null ||
                        textEditingController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        color: FacultyColors.gray500,
                        onPressed: () {
                          setState(() {
                            _selectedCourse = null;
                            textEditingController.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: FacultyColors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: FacultyColors.gray200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: FacultyColors.primary),
                ),
              ),
              style: FacultyTextStyles.bodyMedium
                  .copyWith(color: FacultyColors.gray900, fontSize: 16),
            );
          },
          optionsViewBuilder: (BuildContext context,
              AutocompleteOnSelected<Course> onSelected,
              Iterable<Course> options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Material(
                  elevation: 4.0,
                  shadowColor: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  color: FacultyColors.white,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth,
                      maxHeight: 300,
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (context, index) => const Divider(
                          height: 1, color: FacultyColors.gray100),
                      itemBuilder: (BuildContext context, int index) {
                        final Course option = options.elementAt(index);
                        return InkWell(
                          onTap: () {
                            onSelected(option);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  [
                                    if (option.department.isNotEmpty)
                                      option.department,
                                    if (option.semester != null &&
                                        option.semester!.isNotEmpty)
                                      'Semester ${option.semester}'
                                  ].join(' - '),
                                  style: FacultyTextStyles.bodyMedium.copyWith(
                                      color: FacultyColors.gray900,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  [
                                    if (option.academicYear.isNotEmpty)
                                      option.academicYear,
                                    if (option.session != null &&
                                        option.session!.isNotEmpty)
                                      option.session
                                  ].join(' - '),
                                  style: FacultyTextStyles.bodySmall
                                      .copyWith(color: FacultyColors.gray500),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  option.name,
                                  style: FacultyTextStyles.bodySmall
                                      .copyWith(color: FacultyColors.gray500),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getCurrentDayString() {
    final now = DateTime.now();
    switch (now.weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  List<Course> _getTodayCourses() {
    final today = _getCurrentDayString();
    return _courses.where((c) {
      return c.timetable.any((t) => t.day == today);
    }).toList();
  }

  Widget _buildDisabledState() {
    if (_courses.isEmpty) {
      return _buildNoCoursesState();
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      children: [
        _buildQuickPicks(),
        const SizedBox(height: 32),
        _buildLastSession(),
      ],
    );
  }

  Widget _buildNoCoursesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: FacultyColors.gray50,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.book,
                  size: 48, color: FacultyColors.gray400),
            ),
            const SizedBox(height: 24),
            Text("No Courses Available",
                style:
                    FacultyTextStyles.h3.copyWith(color: FacultyColors.gray900)),
            const SizedBox(height: 12),
            Text(
              "You haven't created any courses yet. Switch to the Courses tab to add your first course and start tracking attendance.",
              textAlign: TextAlign.center,
              style: FacultyTextStyles.bodyMedium.copyWith(
                color: FacultyColors.gray500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastSession() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's Last Session",
            style: FacultyTextStyles.h3.copyWith(color: FacultyColors.gray800)),
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
                  color: FacultyColors.gray50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.history,
                    size: 32, color: FacultyColors.gray400),
              ),
              const SizedBox(height: 16),
              Text(
                'No sessions conducted today',
                style: FacultyTextStyles.bodyMedium
                    .copyWith(color: FacultyColors.gray500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickPicks() {
    if (_courses.isEmpty) return const SizedBox.shrink();

    final quickPicks = _getTodayCourses();
    if (quickPicks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's Classes",
            style: FacultyTextStyles.h3.copyWith(color: FacultyColors.gray800)),
        const SizedBox(height: 12),
        ...quickPicks.map((c) => _buildQuickPickCard(c)),
      ],
    );
  }

  String _getTodayTiming(Course course) {
    final today = _getCurrentDayString();
    try {
      final slot = course.timetable.firstWhere((t) => t.day == today);
      return slot.time;
    } catch (_) {
      return course.timetable.isNotEmpty ? course.timetable.first.time : 'No timing';
    }
  }

  Widget _buildQuickPickCard(Course course) {
    final String yearDisplay = (course.academicYear.toLowerCase().contains('year') == true)
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
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    style: FacultyTextStyles.h4.copyWith(
                      color: FacultyColors.gray900,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${course.degree ?? 'B.Tech'}  |  $yearDisplay  |  Sem ${course.semester ?? 'N/A'}',
                    style: FacultyTextStyles.bodySmall.copyWith(
                      color: FacultyColors.gray500,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getTodayTiming(course),
                    style: FacultyTextStyles.bodySmall.copyWith(
                      color: FacultyColors.gray400,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: FacultyColors.gray900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Start Now',
                style: FacultyTextStyles.bodySmall.copyWith(
                  color: FacultyColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseDetailsView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: _buildStartAction(),
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
              Tab(text: "Session History"),
              Tab(text: "Enrolled Students"),
            ],
          ),
        Expanded(
          child: _isLoadingGrid
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHistoryTab(),
                    _buildStudentsTab(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildStartAction() {
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

  Widget _buildHistoryTab() {
    if (_gridSessions.isEmpty) {
      return const Center(child: Text("No session history found."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _gridSessions.length,
      itemBuilder: (context, index) {
        final session = _gridSessions[index];
        
        // Localize session time
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

        final String date = '${localDateTime.day}/${localDateTime.month}/${localDateTime.year}';
        final String hour = localDateTime.hour > 12 ? (localDateTime.hour - 12).toString() : (localDateTime.hour == 0 ? "12" : localDateTime.hour.toString());
        final String minute = localDateTime.minute.toString().padLeft(2, '0');
        final String ampm = localDateTime.hour >= 12 ? "PM" : "AM";
        final String time = "$hour:$minute $ampm";
                           
        final String type = session['type'] ?? session['classType'] ?? 'Theory';
        final String room = session['roomNumber']?.toString() ?? session['room']?.toString() ?? 'N/A';
        final int totalStudents = session['totalStudents'] ?? 0;
        final int presentCount = session['presentCount'] ?? 0;
        final num attPerc = totalStudents > 0
            ? ((presentCount / totalStudents) * 100).round()
            : 0;

        return InkWell(
          onTap: () {
            final courseMap = {
              'id': _selectedCourse!.id,
              'code': _selectedCourse!.code,
              'name': _selectedCourse!.name,
              'semester': _selectedCourse!.semester,
              'students': _gridStudents,
            };

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SessionDetailsScreen(
                  course: courseMap,
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
                    Text('${attPerc.toStringAsFixed(1)}%',
                        style: FacultyTextStyles.h2.copyWith(
                            color: attPerc >= 75
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
      },
    );
  }

  Widget _buildStudentsTab() {
    if (_gridStudents.isEmpty) {
      return const Center(child: Text("No students enrolled for this course."));
    }
    // Handle sessions correctly even if it's empty
    int totalSessions = _gridSessions.length;
    
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _gridStudents.length,
      itemBuilder: (context, index) {
        final student = _gridStudents[index];
        final String name = (student['name'] ?? 'Unknown').toString();
        final String roll = (student['rollNumber'] ?? student['rollNo'] ?? 'N/A').toString();
        final num attPerc = student['attendancePercentage'] ?? 0;
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
              Column(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${attPerc.toStringAsFixed(1)}%',
                      style: FacultyTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: attPerc >= 75
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
      },
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.users),
              title: const Text('All Students'),
              onTap: () {
                Navigator.pop(context);
                _exportReport('All');
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.userX, color: Colors.red),
              title: const Text('Below 75%'),
              onTap: () {
                Navigator.pop(context);
                _exportReport('Below 75%');
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.filter),
              title: const Text('Custom Percentage'),
              onTap: () {
                Navigator.pop(context);
                _showCustomPercentageDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomPercentageDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Threshold'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Threshold (%)',
            hintText: 'Enter percentage (e.g. 60)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
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
    );
  }

  Future<void> _exportReport(String filterType, [double? customVal]) async {
    if (_selectedCourse == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF...')),
      );

      // Fetch faculty details for report
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
          const SnackBar(content: Text('Report generated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: $e'),
            backgroundColor: FacultyColors.red600,
          ),
        );
      }
    }
  }
}
