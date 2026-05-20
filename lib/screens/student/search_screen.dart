import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../models/data_models.dart';
import '../../services/api_service.dart';
import '../../widgets/common/search_bar.dart';
import 'course_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    if (mounted) setState(() { _hasError = false; _errorMessage = null; _isLoading = true; });
    try {
      final rawCourses = await _apiService.getCourses();
      final courses = rawCourses.map((json) => Course.fromJson(json)).toList();

      if (mounted) {
        setState(() {
          _allCourses = courses;
          _filteredCourses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching courses: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _filterCourses(String query) {
    setState(() {
      _query = query;
      if (query.isEmpty) {
        _filteredCourses = _allCourses;
      } else {
        _filteredCourses = _allCourses.filter((course) {
          final q = query.toLowerCase();
          return course.name.toLowerCase().contains(q) ||
              course.id
                  .toLowerCase()
                  .contains(q) || // Assuming ID is code or similar
              course.faculty.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Back Button and Search Bar
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeft,
                        color: AppColors.gray800),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: CustomSearchBar(
                      onChanged: _filterCourses,
                      readOnly: false,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.wifiOff,
                                    size: 48, color: AppColors.gray400),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage ?? 'Failed to load courses',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(color: AppColors.gray500),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _fetchCourses,
                                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _filteredCourses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.searchX,
                                  size: 48, color: AppColors.gray400),
                              const SizedBox(height: 16),
                              Text(
                                _query.isEmpty
                                    ? "No courses found"
                                    : "No results for '$_query'",
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.gray500),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredCourses.length,
                          itemBuilder: (context, index) {
                            final course = _filteredCourses[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                              color: AppColors.white,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CourseDetailScreen(course: course),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.blue50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(LucideIcons.bookOpen,
                                            color: AppColors.blue600, size: 20),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              course.name,
                                              style: AppTextStyles.h4.copyWith(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(LucideIcons.user,
                                                    size: 14,
                                                    color: AppColors.gray500),
                                                const SizedBox(width: 4),
                                                Text(
                                                  course.faculty,
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(
                                                          color: AppColors
                                                              .gray600),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(LucideIcons.chevronRight,
                                          size: 20, color: AppColors.gray400),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

extension ListFilter<E> on List<E> {
  List<E> filter(bool Function(E) test) => where(test).toList();
}
