import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../widgets/faculty/profile_popup.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/faculty/faculty_colors.dart';
import '../../../constants/faculty/faculty_text_styles.dart';
import '../../../models/faculty/faculty_models.dart';
import '../../../services/faculty/faculty_api_service.dart';
import '../../../services/auth_service.dart';
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
  final AuthService _authService = AuthService();
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];
  bool _isLoading = true;
  bool _showProfilePopup = false;
  FacultyProfile? _profileData;
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
    // 1. Try to load cached data first for instant UI response
    try {
      final cachedCourses = await _apiService.listCourses(forceRefresh: false);
      final cachedProfile = await _apiService.getProfile(forceRefresh: false);
      
      if (mounted) {
        setState(() {
          _allCourses = cachedCourses;
          _filteredCourses = _allCourses;
          _profileData = cachedProfile;
          if (_allCourses.isNotEmpty) {
            _isLoading = false;
          }
        });
      }
    } catch (_) {
      // Ignore cache errors
    }

    // 2. Fetch fresh data in the background
    try {
      // Reload auth user for fresh metadata
      await _authService.currentUser?.reload();

      final results = await Future.wait([
        _apiService.listCourses(forceRefresh: true),
        _apiService.getProfile(forceRefresh: true),
      ]);

      final courses = results[0] is List<Course>
          ? results[0] as List<Course>
          : (results[0] as List).map((e) => e as Course).toList();
      final profile = results[1] is FacultyProfile
          ? results[1] as FacultyProfile
          : null;
      if (profile == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (mounted) {
        setState(() {
          _allCourses = courses;
          _filteredCourses = _allCourses;
          _profileData = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('FacultyHomeTab: Background refresh error: $e');
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
              profileData: _profileData?.toJson(),
              photoUrl: _authService.currentUser?.photoURL,
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
                color: FacultyColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: FacultyColors.gray100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Builder(builder: (context) {
                  final String? photoUrl = _authService.currentUser?.photoURL ?? _profileData?.photoUrl;
                  
                  if (photoUrl != null && photoUrl.isNotEmpty) {
                    return Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildFallbackInitial(),
                    );
                  }
                  return _buildFallbackInitial();
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackInitial() {
    return Container(
      color: FacultyColors.blue600,
      alignment: Alignment.center,
      child: Text(
        _profileData?.name != null && _profileData!.name.isNotEmpty
            ? _profileData!.name[0].toUpperCase()
            : 'F',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildNoCoursesMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: FacultyColors.white,
        borderRadius: BorderRadius.circular(24),
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
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: FacultyColors.gray50,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.book, size: 40, color: FacultyColors.gray400),
          ),
          const SizedBox(height: 24),
          Text(
            "No Courses Created",
            style: FacultyTextStyles.h3.copyWith(color: FacultyColors.gray900),
          ),
          const SizedBox(height: 12),
          Text(
            "You haven't added any courses to your profile yet. Switch to the Courses tab to add your first course.",
            textAlign: TextAlign.center,
            style: FacultyTextStyles.bodyMedium.copyWith(
              color: FacultyColors.gray500,
              height: 1.5,
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
            onTap: () => widget.onStartSession(course),
          ),
        );
      },
    );
  }

  Widget _buildDashboardContent() {
    final currentDayName = daysOfWeek[currentDayIndex];
    final todaysClasses = _getSlotsForDay(currentDayName);
    final hours = [9, 10, 11, 12, 13, 14, 15, 16, 17]; // 9 AM to 6 PM
    final now = DateTime.now();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          _buildTimelineHeader(currentDayName),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_allCourses.isEmpty)
            _buildNoCoursesMessage()
          else
            Column(
              children: hours.map((hour) {
                final isLunch = hour == 13;
                final isLast = hour == 17;

                // Template Logic: Find if there's a class scheduled for this hour
                final slotItem = isLunch
                    ? {}
                    : todaysClasses.firstWhere(
                        (item) {
                          final slot = item['slot'] as TimetableSlot;
                          final timeParts = slot.time.toUpperCase().split(' ');
                          final timeH =
                              int.tryParse(timeParts[0].split(':')[0]) ?? 0;
                          final isPM = timeParts.contains('PM');
                          
                          // Convert to 24h for comparison
                          int actualHour = timeH;
                          if (isPM && timeH != 12) actualHour += 12;
                          if (!isPM && timeH == 12) actualHour = 0;
                          
                          return actualHour == hour;
                        },
                        orElse: () => {},
                      );

                // Dynamic Status Template
                String status = "Upcoming";
                if (slotItem.isNotEmpty) {
                  final currentHour = now.hour;
                  if (currentHour > hour) {
                    status = "Done";
                  } else if (currentHour == hour) {
                    status = "Live";
                  }
                }

                // Time Display Template
                final timeLabel = "${hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)}:00 ${hour >= 12 ? 'PM' : 'AM'}";
                final endHour = hour + 1;
                final endTimeLabel = "${endHour > 12 ? endHour - 12 : (endHour == 0 ? 12 : endHour)}:00 ${endHour >= 12 ? 'PM' : 'AM'}";

                return SizedBox(
                  height: 95,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Time Sidebar
                      SizedBox(
                        width: 80,
                        child: Column(
                          children: [
                            Text(
                              timeLabel,
                              style: FacultyTextStyles.label.copyWith(
                                color: FacultyColors.gray500,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 1.5,
                                  decoration: BoxDecoration(
                                    color: FacultyColors.gray100,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              )
                            else
                              const Spacer(),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Card Content Template
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: isLunch
                              ? _buildLunchBreakCard()
                              : slotItem.isNotEmpty
                                  ? ClassItemCard(
                                      startTime: slotItem['slot'].time,
                                      endTime: endTimeLabel,
                                      subject: slotItem['course'].name,
                                      status: status,
                                      instructor: _profileData?.name ?? "Faculty Member",
                                      credits: slotItem['course'].credits,
                                      attendance: slotItem['course'].enrolledCount,
                                      degree: slotItem['course'].degree,
                                      year: slotItem['course'].academicYear,
                                      semester: slotItem['course'].semester,
                                      onTap: () => widget.onStartSession(slotItem['course']),
                                    )
                                  : const IdleItemCard(time: "Free Slot"),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildLunchBreakCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: FacultyColors.gray50.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FacultyColors.gray100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Lunch",
            style: FacultyTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: FacultyColors.gray600,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
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
