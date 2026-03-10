import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../widgets/faculty/profile_popup.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/faculty/faculty_colors.dart';
import '../../../constants/faculty/faculty_text_styles.dart';
import '../../../models/faculty/faculty_models.dart';
import '../../../services/faculty/faculty_api_service.dart';
import '../../../widgets/faculty/search_bar.dart';
import '../../../widgets/faculty/cards/class_item_card.dart';
import '../../../widgets/faculty/cards/idle_item_card.dart';
import '../faculty_weekly_timetable_screen.dart';

class FacultyHomeTab extends StatefulWidget {
  final Function(Course) onStartSession;

  const FacultyHomeTab({super.key, required this.onStartSession});

  @override
  State<FacultyHomeTab> createState() => _FacultyHomeTabState();
}

class _FacultyHomeTabState extends State<FacultyHomeTab> {
  final FacultyApiService _apiService = FacultyApiService();
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];
  bool _isLoading = true;
  bool _showProfilePopup = false;
  Map<String, dynamic>? _profileData;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  int currentDayIndex = 0;
  final List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    final now = DateTime.now();
    if (now.weekday >= 1 && now.weekday <= 5) {
      currentDayIndex = now.weekday - 1;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Temporary Dummy Data
      final List<Course> dummyCourses = [
        Course(
          id: '1',
          name: 'Computer Networks',
          code: 'CS401',
          section: 'A',
          enrolledCount: 64,
          timetable: [
            TimetableSlot(
                day: 'Monday',
                time: '10:00 AM',
                type: 'Theory',
                room: 'LHC-101'),
            TimetableSlot(
                day: 'Wednesday',
                time: '11:00 AM',
                type: 'Theory',
                room: 'LHC-101'),
            TimetableSlot(
                day: 'Friday',
                time: '10:00 AM',
                type: 'Theory',
                room: 'LHC-102'),
          ],
          joinCode: 'NET-2024',
          department: 'CSE',
          academicYear: '2023-24',
          credits: 4,
          className: 'B.Tech CSE 3rd Year',
        ),
        Course(
          id: '2',
          name: 'Operating Systems',
          code: 'CS402',
          section: 'B',
          enrolledCount: 58,
          timetable: [
            TimetableSlot(
                day: 'Tuesday',
                time: '12:00 PM',
                type: 'Theory',
                room: 'LHC-201'),
            TimetableSlot(
                day: 'Thursday', time: '02:00 PM', type: 'Lab', room: 'Lab-1'),
            TimetableSlot(
                day: 'Friday',
                time: '02:00 PM',
                type: 'Theory',
                room: 'LHC-203'),
          ],
          joinCode: 'OS-CORE',
          department: 'CSE',
          academicYear: '2023-24',
          credits: 4,
          className: 'B.Tech CSE 3rd Year',
        ),
        Course(
          id: '3',
          name: 'AI & Machine Learning',
          code: 'CS501',
          section: 'A',
          enrolledCount: 72,
          timetable: [
            TimetableSlot(
                day: 'Wednesday',
                time: '10:00 AM',
                type: 'Theory',
                room: 'LHC-105'),
          ],
          joinCode: 'AI-ML',
          department: 'CSE',
          academicYear: '2023-24',
          credits: 3,
          className: 'B.Tech CSE 4th Year',
        ),
      ];

      // Simulate delay
      await Future.delayed(const Duration(milliseconds: 600));

      final results = await Future.wait([
        _apiService.listCourses(),
        _apiService.getProfile(),
      ]);

      final courses = results[0] as List<Course>;
      final profile = results[1] as Map<String, dynamic>;

      setState(() {
        _allCourses = courses.isEmpty ? dummyCourses : courses;
        _filteredCourses = _allCourses;
        _profileData = profile;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCourses = _allCourses;
      } else {
        _filteredCourses = _allCourses.where((course) {
          final q = query.toLowerCase();
          return course.name.toLowerCase().contains(q) ||
              course.code.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  void _changeDay(String direction) {
    setState(() {
      if (direction == 'next') {
        currentDayIndex = (currentDayIndex + 1) % daysOfWeek.length;
      } else {
        currentDayIndex =
            (currentDayIndex - 1 + daysOfWeek.length) % daysOfWeek.length;
      }
    });
  }

  String _getDateString(int index) {
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1 = Mon
    final targetWeekday = index + 1;
    final diff = targetWeekday - currentWeekday;
    final date = now.add(Duration(days: diff));

    return DateFormat('MMM dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final content = GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          _buildHeader(),
          FacultySearchBar(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onClear: _searchQuery.isNotEmpty
                ? () {
                    _searchController.clear();
                    _onSearchChanged('');
                  }
                : null,
          ),
          Expanded(
            child: _searchQuery.isNotEmpty
                ? _buildSearchResults()
                : _buildDashboardContent(),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: FacultyColors.background,
      body: Stack(
        children: [
          content,
          if (_showProfilePopup)
            ProfilePopup(
              profileData: _profileData,
              onClose: () => setState(() => _showProfilePopup = false),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      color: FacultyColors.background,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/logo.png',
            height: 40,
            errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.school_rounded,
                color: FacultyColors.black,
                size: 40),
          ),
          GestureDetector(
            onTap: () => setState(() => _showProfilePopup = true),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: FacultyColors.green600,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                _profileData?['name'] != null
                    ? _profileData!['name'][0].toUpperCase()
                    : 'R',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredCourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.searchX,
                size: 48, color: FacultyColors.gray400),
            const SizedBox(height: 16),
            Text(
              "No results for '$_searchQuery'",
              style: FacultyTextStyles.bodyMedium
                  .copyWith(color: FacultyColors.gray500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredCourses.length,
      itemBuilder: (context, index) {
        final course = _filteredCourses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          color: FacultyColors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: FacultyColors.blue50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.bookOpen,
                  color: FacultyColors.black, size: 20),
            ),
            title: Text(course.name,
                style:
                    FacultyTextStyles.h4.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text(course.code,
                style: FacultyTextStyles.bodySmall
                    .copyWith(color: FacultyColors.gray500)),
            trailing: const Icon(LucideIcons.chevronRight,
                size: 20, color: FacultyColors.gray400),
            onTap: () {
              // Handle course detail navigation if needed
            },
          ),
        );
      },
    );
  }

  Widget _buildDashboardContent() {
    final currentDayName = daysOfWeek[currentDayIndex];
    final todaysClasses = _getSlotsForDay(currentDayName);
    final hours = List.generate(10, (i) => i + 9); // 9 AM to 6 PM

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          _buildTimelineHeader(currentDayName),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Stack(
              children: [
                Positioned(
                  left: 29,
                  top: 8,
                  bottom: 0,
                  child: Container(width: 2, color: FacultyColors.gray100),
                ),
                Column(
                  children: hours.map((hour) {
                    final slotItem = todaysClasses.firstWhere(
                      (item) {
                        final slot = item['slot'] as TimetableSlot;
                        // Basic check: "10:00 AM" starts with "10"
                        final timeParts = slot.time.split(' ');
                        final timeH =
                            int.tryParse(timeParts[0].split(':')[0]) ?? 0;
                        final isPM = timeParts.last == 'PM';
                        final actualHour =
                            (isPM && timeH != 12) ? timeH + 12 : timeH;
                        return actualHour == hour;
                      },
                      orElse: () => {},
                    );

                    final timeStr = "$hour:00";
                    final endTimeStr = "${hour + 1}:00";

                    if (slotItem.isNotEmpty) {
                      final Course course = slotItem['course'];
                      final TimetableSlot slot = slotItem['slot'];
                      return ClassItemCard(
                        startTime: slot.time,
                        endTime: endTimeStr, // Mock end time
                        subject: course.name,
                        status: "Upcoming",
                        instructor: "Rahul Barma", // Match screenshot
                        credits: course.credits,
                        attendance: 25, // Mock attendance
                        onTap: () => widget.onStartSession(course),
                      );
                    } else {
                      return IdleItemCard(time: timeStr);
                    }
                  }).toList(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineHeader(String dayName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Classes",
                style:
                    FacultyTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("$dayName, ${_getDateString(currentDayIndex)}",
                style: FacultyTextStyles.bodySmall.copyWith(
                    color: FacultyColors.gray500, fontWeight: FontWeight.w500)),
          ],
        ),
        Row(
          children: [
            _buildIconButton(
              LucideIcons.calendar,
              () {
                final now = DateTime.now();
                if (now.weekday >= 1 && now.weekday <= 5) {
                  setState(() => currentDayIndex = now.weekday - 1);
                }
              },
              active: (DateTime.now().weekday >= 1 &&
                  DateTime.now().weekday <= 5 &&
                  currentDayIndex == DateTime.now().weekday - 1),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: FacultyColors.white,
                border: Border.all(color: FacultyColors.gray100),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildIconButton(
                      LucideIcons.chevronLeft, () => _changeDay('prev'),
                      size: 20, padding: 6),
                  Container(
                      width: 1,
                      height: 16,
                      color: FacultyColors.gray100,
                      margin: const EdgeInsets.symmetric(horizontal: 4)),
                  _buildIconButton(
                      LucideIcons.chevronRight, () => _changeDay('next'),
                      size: 20, padding: 6),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildIconButton(LucideIcons.maximize2, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FacultyWeeklyTimetableScreen(courses: _allCourses),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap,
      {bool active = false, double size = 16, double padding = 8}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: active ? FacultyColors.gray100 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: size,
            color: active ? FacultyColors.black : FacultyColors.gray600),
      ),
    );
  }

  List<Map<String, dynamic>> _getSlotsForDay(String day) {
    List<Map<String, dynamic>> slots = [];
    for (var course in _allCourses) {
      for (var slot in course.timetable) {
        if (slot.day == day) {
          slots.add({
            'course': course,
            'slot': slot,
          });
        }
      }
    }
    return slots;
  }
}
