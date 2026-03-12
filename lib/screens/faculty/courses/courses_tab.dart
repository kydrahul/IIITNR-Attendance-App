import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import '../../../constants/faculty/faculty_colors.dart';
import '../../../constants/faculty/faculty_text_styles.dart';
import 'add_course_dialog.dart';
import 'course_details_screen.dart';
import '../../../services/faculty/faculty_api_service.dart';
import '../../../models/faculty/faculty_models.dart';
import 'widgets/join_code_dialog.dart';

class FacultyCoursesTab extends StatefulWidget {
  const FacultyCoursesTab({super.key});

  @override
  State<FacultyCoursesTab> createState() => _FacultyCoursesTabState();
}

class _FacultyCoursesTabState extends State<FacultyCoursesTab> {
  final FacultyApiService _apiService = FacultyApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Course> _allCourses = [];
  bool _isLoading = true;
  String _searchQuery = '';

  final List<String> _yearOptions = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    'M.Tech'
  ];
  final Set<String> _selectedYears = {};
  bool _showAllYears = true;
  String _activeYearFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoading = true);
    try {
      final courses = await _apiService.listCourses();
      if (mounted) {
        setState(() {
          _allCourses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
          if (isSelected) {
            _activeYearFilter = 'All';
            _selectedYears.clear();
            _showAllYears = true;
          } else {
            _activeYearFilter = label;
            if (label == 'All') {
              _selectedYears.clear();
              _showAllYears = true;
            } else {
              _selectedYears.clear();
              _selectedYears.add(label);
              _showAllYears = false;
            }
          }
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
                  Text('Filter by Year', style: FacultyTextStyles.h3),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllYears = true;
                        _selectedYears.clear();
                        _activeYearFilter = 'All';
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
                  if (val == true) setState(() => _activeYearFilter = 'All');
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
                      if (val == true) setState(() => _activeYearFilter = year);
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
    ).then((_) => _fetchCourses());
  }

  Widget _buildEmptyState({required bool isSearch}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: FacultyColors.gray50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSearch ? LucideIcons.searchX : LucideIcons.book,
                  size: 48,
                  color: FacultyColors.gray300,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isSearch ? "No courses found" : "No courses created",
                style:
                    FacultyTextStyles.h3.copyWith(color: FacultyColors.gray900),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  isSearch
                      ? "We couldn't find any courses matching your search or filter."
                      : "You haven't created any courses yet. Add your first course to start tracking attendance.",
                  textAlign: TextAlign.center,
                  style: FacultyTextStyles.bodyMedium
                      .copyWith(color: FacultyColors.gray500),
                ),
              ),
              if (!isSearch) ...[
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _showAddCourseDialog,
                  icon: const Icon(LucideIcons.plus, size: 20),
                  label: const Text('Add Course'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FacultyColors.black,
                    foregroundColor: FacultyColors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
          if (!_isLoading && _allCourses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: "Search courses...",
                  prefixIcon: const Icon(LucideIcons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: FacultyColors.gray50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          if (!_isLoading && _allCourses.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  ..._yearOptions.map((year) => _buildFilterChip(year)),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchCourses,
                    child: _allCourses.isEmpty
                        ? _buildEmptyState(isSearch: false)
                        : Builder(builder: (context) {
                            final filteredCourses = _allCourses.where((course) {
                              final matchesSearch = course.name
                                      .toLowerCase()
                                      .contains(_searchQuery.toLowerCase()) ||
                                  course.code
                                      .toLowerCase()
                                      .contains(_searchQuery.toLowerCase());
                              final matchesYear = _activeYearFilter == 'All' ||
                                  (_activeYearFilter == 'M.Tech' &&
                                      (course.degree == 'M.Tech' ||
                                          course.academicYear
                                              .toLowerCase()
                                              .contains('m.tech'))) ||
                                  (course.degree != 'M.Tech' &&
                                      (_activeYearFilter.toLowerCase().contains(
                                              course.academicYear
                                                  .toLowerCase()
                                                  .replaceAll(' year', '')
                                                  .trim()) ||
                                          course.academicYear
                                              .toLowerCase()
                                              .contains(_activeYearFilter
                                                  .toLowerCase()
                                                  .replaceAll(' year', '')
                                                  .trim())));
                              return matchesSearch && matchesYear;
                            }).toList();

                            if (filteredCourses.isEmpty) {
                              return _buildEmptyState(isSearch: true);
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              itemCount: filteredCourses.length,
                              itemBuilder: (context, index) {
                                final course = filteredCourses[index];
                                return _CourseCard(
                                  course: course,
                                  onRefresh: _fetchCourses,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CourseDetailsScreen(
                                          course: course.toJson(),
                                          allCourses: _allCourses
                                              .map((e) => e.toJson())
                                              .toList(),
                                        ),
                                      ),
                                    ).then((_) => _fetchCourses());
                                  },
                                );
                              },
                            );
                          }),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;
  final VoidCallback onRefresh;

  const _CourseCard({
    required this.course,
    required this.onTap,
    required this.onRefresh,
  });

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

  void _showJoinCodeDialog(BuildContext context) {
    JoinCodeDialog.show(context, course.name, course.code, course.joinCode);
  }

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
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.name,
                          style: GoogleFonts.montserrat(
                            color: FacultyColors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${course.code}  |  ${course.degree ?? 'B.Tech'}  |  ${course.academicYear.toLowerCase().contains('year') ? course.academicYear : "${course.academicYear} Year"}  |  ${course.credits} Credits',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            color: FacultyColors.gray500,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(LucideIcons.moreHorizontal,
                        size: 16, color: FacultyColors.gray400),
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'join_code') {
                        _showJoinCodeDialog(context);
                      } else if (value == 'edit_schedule') {
                        showGeneralDialog(
                          context: context,
                          barrierDismissible: false,
                          barrierLabel: "Edit Schedule",
                          pageBuilder: (context, _, __) =>
                              AddCourseDialog(editCourse: course),
                        ).then((_) => onRefresh());
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit_schedule',
                        child: Row(
                          children: [
                            Icon(LucideIcons.calendar,
                                size: 16, color: FacultyColors.gray600),
                            SizedBox(width: 8),
                            Text('Edit Schedule',
                                style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'join_code',
                        child: Row(
                          children: [
                            Icon(LucideIcons.key,
                                size: 16, color: FacultyColors.gray600),
                            SizedBox(width: 8),
                            Text('Show Joining Code',
                                style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: FacultyColors.gray100)),
                ),
                child: Row(
                  children: [
                    Expanded(
                        child: _buildStat(
                            "STUDENTS", course.enrolledCount.toString())),
                    Container(
                        height: 24, width: 1, color: FacultyColors.gray100),
                    Expanded(
                        child: _buildStat(
                            "SEMESTER", _getOrdinal(course.semester ?? 'N/A'))),
                    Container(
                        height: 24, width: 1, color: FacultyColors.gray100),
                    Expanded(child: _buildStat("BRANCH", course.department)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 10,
            color: FacultyColors.gray400,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: FacultyColors.gray800,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
