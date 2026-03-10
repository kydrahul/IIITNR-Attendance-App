import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/faculty/faculty_colors.dart';
import '../../../constants/faculty/faculty_text_styles.dart';
import '../../../widgets/faculty/search_bar.dart';
import 'add_course_dialog.dart';
import 'course_details_screen.dart';

class FacultyCoursesTab extends StatefulWidget {
  const FacultyCoursesTab({super.key});

  @override
  State<FacultyCoursesTab> createState() => _FacultyCoursesTabState();
}

class _FacultyCoursesTabState extends State<FacultyCoursesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _yearOptions = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    'M.Tech',
    'PhD'
  ];
  final Set<String> _selectedYears = {};
  bool _showAllYears = true;
  String _activeYearFilter = 'All';

  final List<Map<String, dynamic>> _mockCourses = [
    {
      'name': 'Intro to AI',
      'code': 'AI201',
      'branch': 'DSAI',
      'year': '1st Year',
      'credits': 3,
      'semester': '1',
      'students': 80,
      'academicYear': '2023-24',
      'session': 'Autumn 2023'
    },
    {
      'name': 'Data Structures & Algorithms',
      'code': 'CS301',
      'branch': 'CSE',
      'year': '2nd Year',
      'credits': 4,
      'semester': '3',
      'students': 68,
      'academicYear': '2023-24',
      'session': 'Autumn 2023'
    },
    {
      'name': 'Digital Signal Processing',
      'code': 'EC305',
      'branch': 'ECE',
      'year': '2nd Year',
      'credits': 3,
      'semester': '4',
      'students': 45,
      'academicYear': '2023-24',
      'session': 'Spring 2024'
    },
    {
      'name': 'Machine Learning',
      'code': 'AI402',
      'branch': 'DSAI',
      'year': '3rd Year',
      'credits': 4,
      'semester': '5',
      'students': 52,
      'academicYear': '2024-25',
      'session': 'Autumn 2024'
    },
    {
      'name': 'Operating Systems',
      'code': 'CS401',
      'branch': 'CSE',
      'year': '3rd Year',
      'credits': 4,
      'semester': '5',
      'students': 72,
      'academicYear': '2024-25',
      'session': 'Autumn 2024'
    },
    {
      'name': 'Computer Networks',
      'code': 'CS501',
      'branch': 'CSE',
      'year': '4th Year',
      'credits': 4,
      'semester': '7',
      'students': 60,
      'academicYear': '2024-25',
      'session': 'Autumn 2024'
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _toggleYear(String year) {
    setState(() {
      if (_selectedYears.contains(year)) {
        _selectedYears.remove(year);
      } else {
        _selectedYears.add(year);
        _showAllYears = false;
      }
      if (_selectedYears.isEmpty) {
        _showAllYears = true;
      }
    });
  }

  void _toggleAllYears(bool? value) {
    setState(() {
      _showAllYears = value ?? true;
      if (_showAllYears) {
        _selectedYears.clear();
      }
    });
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

  Widget _buildFilterChip(String label) {
    final bool isSelected = _activeYearFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeYearFilter = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? FacultyColors.black : FacultyColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? FacultyColors.black : FacultyColors.gray200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? FacultyColors.white : FacultyColors.gray600,
          ),
        ),
      ),
    );
  }

  void _showFilterMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: FacultyColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filter by Batch', style: FacultyTextStyles.h3),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllYears = true;
                        _selectedYears.clear();
                      });
                      setModalState(() {});
                    },
                    child: const Text('Reset',
                        style: TextStyle(color: FacultyColors.black)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('All Years'),
                value: _showAllYears,
                activeColor: FacultyColors.black,
                onChanged: (val) {
                  _toggleAllYears(val);
                  setModalState(() {});
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              ..._yearOptions.map((year) => CheckboxListTile(
                    title: Text(year),
                    value: _selectedYears.contains(year),
                    activeColor: FacultyColors.black,
                    onChanged: (val) {
                      _toggleYear(year);
                      setModalState(() {});
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  )),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FacultyColors.black,
                    foregroundColor: FacultyColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCourseDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddCourseDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Courses',
                    style: FacultyTextStyles.h1
                        .copyWith(color: FacultyColors.gray900)),
                Row(
                  children: [
                    _buildIconButton(LucideIcons.plus, _showAddCourseDialog),
                    const SizedBox(width: 8),
                    _buildIconButton(
                        LucideIcons.filter, () => _showFilterMenu(context),
                        active: _selectedYears.isNotEmpty),
                  ],
                ),
              ],
            ),
          ),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All'),
                ..._yearOptions.take(4).map((year) => _buildFilterChip(year)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              children: _mockCourses.where((course) {
                final matchesSearch = course['name']
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ||
                    course['code']
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
                final matchesYear = _activeYearFilter == 'All' ||
                    course['year'] == _activeYearFilter;
                return matchesSearch && matchesYear;
              }).map((course) {
                return _CourseCard(
                  courseName: course['name'],
                  courseCode: course['code'],
                  branch: course['branch'],
                  year: course['year'],
                  credits: course['credits'],
                  semester: course['semester'],
                  studentCount: course['students'],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseDetailsScreen(
                            course: course, allCourses: _mockCourses),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final String courseName;
  final String courseCode;
  final String branch;
  final String year;
  final int credits;
  final String semester;
  final int studentCount;
  final VoidCallback onTap;

  const _CourseCard({
    required this.courseName,
    required this.courseCode,
    required this.branch,
    required this.year,
    required this.credits,
    required this.semester,
    required this.studentCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: FacultyColors.gray100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        courseCode,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: FacultyColors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Icon(LucideIcons.moreVertical,
                        size: 16, color: FacultyColors.gray400),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  courseName,
                  style: FacultyTextStyles.h3.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  '$branch • $year • Semester $semester',
                  style: FacultyTextStyles.bodySmall.copyWith(
                    color: FacultyColors.gray500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildMeta(
                        LucideIcons.graduationCap, '$studentCount Students'),
                    const SizedBox(width: 16),
                    _buildMeta(LucideIcons.award, '$credits Credits'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: FacultyColors.gray400),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: FacultyColors.gray600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
