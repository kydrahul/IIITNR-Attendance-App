import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../models/data_models.dart';
import '../../services/api_service.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final ApiService _apiService = ApiService();
  bool showContact = false;
  String filter = 'All';
  bool sortAsc = false;
  List<AttendanceRecord> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      // In a real app, you might have a specific endpoint for course history
      // For now, we'll use the general attendance history and filter by course
      // Or if the backend supports it, pass the course ID.
      // Assuming getAttendanceHistory returns all history for the student.
      final historyData = await _apiService.getAttendanceHistory();

      // Filter for this course if needed, or just show all if the API returns course-specific data
      // Since the API service method is generic, let's assume it returns all.
      // We might need to filter by course name or ID if the record contains it.
      // However, the current AttendanceRecord model doesn't have course ID.
      // Let's assume for now we show all history or the API needs an update to filter.
      // Given the current constraints, we will display what we get.

      if (mounted) {
        setState(() {
          _history = historyData
              .map((json) => AttendanceRecord.fromJson(json))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching history: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter Logic
    final filteredHistory = _history.where((item) {
      if (filter == 'All') return true;
      return item.status == filter;
    }).toList();

    // Sort Logic
    filteredHistory.sort((a, b) {
      return sortAsc ? a.date.compareTo(b.date) : b.date.compareTo(a.date);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Header
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: const Icon(LucideIcons.chevronLeft,
                        size: 20, color: AppColors.gray600),
                  ),
                ),
                const SizedBox(width: 16),
                Text("Course Details",
                    style:
                        AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 24),

            // Stats Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.gray100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        color: AppColors.blue50.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.course.name,
                          style: AppTextStyles.h1
                              .copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),

                      // Faculty Dropdown
                      GestureDetector(
                        onTap: () => setState(() => showContact = !showContact),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(widget.course.faculty,
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.blue600,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(width: 4),
                            Icon(
                                showContact
                                    ? LucideIcons.chevronUp
                                    : LucideIcons.chevronDown,
                                size: 16,
                                color: AppColors.blue600),
                          ],
                        ),
                      ),

                      if (showContact)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.blue50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildContactRow(LucideIcons.phone,
                                  widget.course.contact.phone),
                              const SizedBox(height: 8),
                              _buildContactRow(LucideIcons.mail,
                                  widget.course.contact.email),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("ATTENDANCE", style: AppTextStyles.label),
                              Text(
                                "${widget.course.attendance}%",
                                style: AppTextStyles.h1.copyWith(
                                  fontSize: 32,
                                  color: widget.course.attendance >= 75
                                      ? AppColors.green600
                                      : AppColors.red500,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildStatRow(
                                  "Total",
                                  widget.course.totalClasses.toString(),
                                  AppColors.gray800),
                              _buildStatRow(
                                  "Present",
                                  widget.course.attended.toString(),
                                  AppColors.green600),
                              _buildStatRow(
                                  "Missed",
                                  widget.course.missed.toString(),
                                  AppColors.red500),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Weekly Schedule
            Text("Weekly Schedule",
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gray100),
              ),
              child: Column(
                children: widget.course.schedule
                    .map((slot) => Container(
                          padding: const EdgeInsets.only(bottom: 12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: AppColors.gray50)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.blue50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  slot.day.substring(0, 3),
                                  style: AppTextStyles.label
                                      .copyWith(color: AppColors.blue600),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(slot.time,
                                      style: AppTextStyles.bodySmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.gray800)),
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.doorOpen,
                                          size: 12, color: AppColors.gray500),
                                      const SizedBox(width: 4),
                                      Text(slot.room,
                                          style: AppTextStyles.label.copyWith(
                                              color: AppColors.gray500)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 24),

            // History Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Class History",
                    style:
                        AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => sortAsc = !sortAsc),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.gray200),
                        ),
                        child: const Icon(LucideIcons.arrowUpDown,
                            size: 16, color: AppColors.gray600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      child: DropdownButton<String>(
                        value: filter,
                        underline: const SizedBox(),
                        icon: const Icon(LucideIcons.chevronDown,
                            size: 16, color: AppColors.gray600),
                        style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray600),
                        onChanged: (val) => setState(() => filter = val!),
                        items: ["All", "Present", "Absent"]
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // History List
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filteredHistory.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                    child: Text("No records found",
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.gray400,
                            fontStyle: FontStyle.italic))),
              )
            else
              ...filteredHistory.map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gray100),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.date,
                                style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.gray800)),
                            const SizedBox(height: 2),
                            Text("${item.day} • ${item.time}",
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.gray500)),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.gray100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.type,
                                style: AppTextStyles.label.copyWith(
                                    color: AppColors.gray600, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.status == 'Present'
                                ? AppColors.green100
                                : AppColors.red100,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            item.status.toUpperCase(),
                            style: AppTextStyles.label.copyWith(
                              color: item.status == 'Present'
                                  ? AppColors.green700
                                  : AppColors.red700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12, color: AppColors.blue600),
        ),
        const SizedBox(width: 8),
        Text(text,
            style:
                AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
          children: [
            TextSpan(text: "$label: "),
            TextSpan(
                text: value,
                style:
                    TextStyle(color: valueColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
