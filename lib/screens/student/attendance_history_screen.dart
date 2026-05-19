import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../services/api_service.dart';
import '../../widgets/common/skeleton_loaders.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _attendanceHistory = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAttendanceHistory();
  }

  Future<void> _loadAttendanceHistory() async {
    try {
      // 1. Load from cache first
      final cachedHistory = await _apiService.getAttendanceHistory(forceRefresh: false);
      if (cachedHistory.isNotEmpty) {
        if (mounted) _updateUI(cachedHistory);
      } else {
        if (mounted) setState(() => _isLoading = true);
      }

      // 2. Fetch fresh data in the background
      final freshHistory = await _apiService.getAttendanceHistory(forceRefresh: true);
      if (mounted) _updateUI(freshHistory);
    } catch (e) {
      if (mounted && _attendanceHistory.isEmpty) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _updateUI(List<dynamic> history) {
    if (!mounted) return;
    setState(() {
      _attendanceHistory = history;
      _isLoading = false;
      _errorMessage = null;
    });
  }

  Color _getAttendanceColor(int percentage) {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance History'),
        backgroundColor: AppColors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAttendanceHistory,
        child: _isLoading
            ? const HistorySkeleton()
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.alertCircle,
                              size: 48, color: Colors.red.shade300),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: Colors.red.shade700),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadAttendanceHistory,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _attendanceHistory.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.clipboardList,
                                  size: 48, color: AppColors.gray400),
                              const SizedBox(height: 16),
                              Text(
                                'No attendance records',
                                style: AppTextStyles.h3
                                    .copyWith(color: AppColors.gray600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start scanning QR codes to mark attendance',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.gray400),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: _attendanceHistory.length,
                        itemBuilder: (context, index) {
                          final record = _attendanceHistory[index];
                          final courseName =
                              record['courseName'] ?? 'Unknown Course';
                          final attended = record['attended'] ?? 0;
                          final total = record['total'] ?? 0;
                          final percentage = total > 0
                              ? ((attended / total) * 100).round()
                              : 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.gray100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        courseName,
                                        style: AppTextStyles.h3.copyWith(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getAttendanceColor(percentage)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$percentage%',
                                        style:
                                            AppTextStyles.bodyMedium.copyWith(
                                          color:
                                              _getAttendanceColor(percentage),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(LucideIcons.checkCircle2,
                                        size: 16, color: AppColors.gray500),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Attended: $attended / $total classes',
                                      style: AppTextStyles.bodySmall
                                          .copyWith(color: AppColors.gray600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: total > 0 ? attended / total : 0,
                                    backgroundColor: AppColors.gray100,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _getAttendanceColor(percentage),
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
