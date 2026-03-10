import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../constants/colors.dart';
import '../../../constants/text_styles.dart';
import '../../../services/api_service.dart';
import '../../../widgets/cards/course_card.dart';
import '../course_detail_screen.dart';
import '../../../models/data_models.dart';

class CoursesTab extends StatefulWidget {
  const CoursesTab({super.key});

  @override
  State<CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends State<CoursesTab> {
  final ApiService _apiService = ApiService();
  final TextEditingController _joinCodeController = TextEditingController();

  bool showJoinInput = false;
  bool _isLoading = true;
  bool _isJoining = false;
  List<Course> _courses = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final coursesData = await _apiService.getCourses();
      setState(() {
        _courses = coursesData.map((json) => Course.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load courses: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _joinCourse() async {
    final joinCode = _joinCodeController.text.trim();
    if (joinCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a join code')),
      );
      return;
    }

    setState(() => _isJoining = true);

    try {
      await _apiService.joinCourse(joinCode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined course!'),
            backgroundColor: Colors.green,
          ),
        );
        _joinCodeController.clear();
        setState(() => showJoinInput = false);
        _loadCourses(); // Reload courses
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadCourses,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("My Courses",
                  style:
                      AppTextStyles.h1.copyWith(fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () {
                  setState(() {
                    showJoinInput = !showJoinInput;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: showJoinInput ? AppColors.gray200 : AppColors.black,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    showJoinInput ? LucideIcons.x : LucideIcons.plus,
                    color: showJoinInput ? AppColors.gray800 : AppColors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Join Input
          if (showJoinInput)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      child: TextField(
                        controller: _joinCodeController,
                        decoration: InputDecoration(
                          hintText: "Enter class code to join...",
                          hintStyle: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.gray400),
                          prefixIcon: const Icon(LucideIcons.search,
                              size: 16, color: AppColors.gray400),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isJoining ? null : _joinCourse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue600,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    child: _isJoining
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Join"),
                  ),
                ],
              ),
            ),

          // Error Message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ),

          // Loading State
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_courses.isEmpty)
            // Empty State
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(LucideIcons.bookOpen,
                        size: 48, color: AppColors.gray400),
                    const SizedBox(height: 16),
                    Text(
                      'No courses enrolled',
                      style:
                          AppTextStyles.h3.copyWith(color: AppColors.gray600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use the + button to join a course',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.gray400),
                    ),
                  ],
                ),
              ),
            )
          else
            // Enrolled List
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("ENROLLED",
                    style: AppTextStyles.label.copyWith(fontSize: 12)),
                const SizedBox(height: 12),
                ..._courses.map((course) => CourseCard(
                      course: course,
                      onClick: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CourseDetailScreen(course: course),
                          ),
                        );
                      },
                    )),
              ],
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }
}
