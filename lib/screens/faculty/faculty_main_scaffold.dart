import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/faculty/faculty_colors.dart';
import 'home/faculty_home_tab.dart';
import 'attendance/attendance_tab.dart';
import 'courses/courses_tab.dart';
import 'profile/faculty_profile_tab.dart';
import '../../models/faculty/faculty_models.dart';

class FacultyMainScaffold extends StatefulWidget {
  const FacultyMainScaffold({super.key});

  @override
  State<FacultyMainScaffold> createState() => _FacultyMainScaffoldState();
}

class _FacultyMainScaffoldState extends State<FacultyMainScaffold> {
  int _selectedIndex = 0;
  Course? _selectedCourseForAttendance;

  void _onStartSession(Course course) {
    setState(() {
      _selectedCourseForAttendance = course;
      _selectedIndex = 1; // Switch to Attendance tab
    });
  }

  List<Widget> get _pages => [
        FacultyHomeTab(onStartSession: _onStartSession),
        FacultyAttendanceTab(initialCourse: _selectedCourseForAttendance),
        const FacultyCoursesTab(),
        const FacultyProfileTab(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: FacultyColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, LucideIcons.home, "Home"),
                _buildNavItem(1, LucideIcons.qrCode, "Attendance"),
                _buildNavItem(2, LucideIcons.bookOpen, "Courses"),
                _buildNavItem(3, LucideIcons.settings, "Settings"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? FacultyColors.black : FacultyColors.gray400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? FacultyColors.black : FacultyColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
