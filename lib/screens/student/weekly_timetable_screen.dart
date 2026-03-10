import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';

enum CellType { header, time, classCell, idle, breakCell }

class WeeklyTimetableScreen extends StatefulWidget {
  const WeeklyTimetableScreen({super.key});

  @override
  State<WeeklyTimetableScreen> createState() => _WeeklyTimetableScreenState();
}

class _WeeklyTimetableScreenState extends State<WeeklyTimetableScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _timetable = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTimetable();
  }

  Future<void> _fetchTimetable() async {
    try {
      final data = await _apiService.getTimetable();
      setState(() {
        _timetable = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              ElevatedButton(
                onPressed: _fetchTimetable,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header - Simplified
            Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.gray300),
                ),
              ),
              padding: const EdgeInsets.all(4), // p-1
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.arrowLeft,
                        size: 20,
                        color: AppColors.gray600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Week Schedule",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Spring / 3rd / DSAI / 2025",
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Timetable Grid - Full screen
            Expanded(
              child: Container(
                color: AppColors.white,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildTimetableGrid(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableGrid() {
    return Column(
      children: [
        // Padding between header and grid
        Container(
          height: 8,
          color: AppColors.white,
        ),
        Container(
          color: AppColors.white,
          child: Column(
            children: [
              // Header Row
              _buildHeaderRow(),

              // Time Rows
              _buildTimeRow("9:00"),
              _buildTimeRow("10:00"),
              _buildTimeRow("11:00"),
              _buildTimeRow("12:00"),
              _buildLunchRow(),
              _buildTimeRow("2:00"),
              _buildTimeRow("3:00"),
              _buildTimeRow("4:00"),
              _buildTimeRow("5:00"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        // Empty cell for time column
        Container(
          width: 40,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.gray100,
            border: Border.all(color: AppColors.gray300, width: 1),
          ),
        ),
        _buildCell("Mon", CellType.header, width: 60),
        _buildCell("Tue", CellType.header, width: 60),
        _buildCell("Wed", CellType.header, width: 60),
        _buildCell("Thu", CellType.header, width: 60),
        _buildCell("Fri", CellType.header, width: 60),
      ],
    );
  }

  Widget _buildTimeRow(String time) {
    // Helper to find class for a specific day and time
    String getClassFor(String day, String timeSlot) {
      if (_timetable[day] == null) {
        print("DEBUG: No data for $day");
        return "";
      }

      final classes = _timetable[day] as List<dynamic>;
      // Normalize time strings for comparison (e.g., "9:00" vs "09:00 - 10:00")
      final slotTime = timeSlot.split(':')[0].padLeft(2, '0');

      for (var cls in classes) {
        print(
            "DEBUG: Checking class ${cls['courseName']} at ${cls['time']} against slot $slotTime");
        final classTime = cls['time']
            .toString()
            .split(' - ')[0]
            .split(':')[0]
            .padLeft(2, '0');

        if (classTime == slotTime) {
          print("DEBUG: MATCH FOUND for $day $timeSlot: ${cls['courseName']}");
          return "${cls['courseName']}\n${cls['facultyName']}";
        }
      }
      return "";
    }

    return Row(
      children: [
        _buildCell(time, CellType.time, width: 40, height: 48),
        _buildCell(getClassFor("Monday", time), CellType.classCell,
            width: 60, height: 48),
        _buildCell(getClassFor("Tuesday", time), CellType.classCell,
            width: 60, height: 48),
        _buildCell(getClassFor("Wednesday", time), CellType.classCell,
            width: 60, height: 48),
        _buildCell(getClassFor("Thursday", time), CellType.classCell,
            width: 60, height: 48),
        _buildCell(getClassFor("Friday", time), CellType.classCell,
            width: 60, height: 48),
      ],
    );
  }

  Widget _buildLunchRow() {
    return Row(
      children: [
        _buildCell("1:00", CellType.time, width: 40, height: 48),
        _buildCell("Lunch", CellType.breakCell, width: 300, height: 48),
      ],
    );
  }

  Widget _buildCell(
    String text,
    CellType type, {
    required double width,
    double height = 24,
  }) {
    Color bgColor;
    Color textColor;
    FontWeight fontWeight;
    double fontSize;
    TextStyle? textStyle;
    EdgeInsets padding;

    switch (type) {
      case CellType.header:
        bgColor = AppColors.gray100;
        textColor = AppColors.black;
        fontWeight = FontWeight.bold;
        fontSize = 7;
        padding =
            const EdgeInsets.symmetric(horizontal: 2, vertical: 12); // py-3
        textStyle = TextStyle(
          fontWeight: fontWeight,
          fontSize: fontSize,
          letterSpacing: 0.5,
          color: textColor,
          height: 1.0,
        );
        break;
      case CellType.time:
        bgColor = AppColors.white;
        textColor = AppColors.gray500;
        fontWeight = FontWeight.normal;
        fontSize = 7;
        padding = const EdgeInsets.symmetric(horizontal: 2, vertical: 24);
        textStyle = TextStyle(
          fontFamily: 'monospace',
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: textColor,
          height: 1.0,
        );
        break;
      case CellType.classCell:
        bgColor = text.isNotEmpty ? AppColors.white : AppColors.gray50;
        textColor = AppColors.black;
        fontWeight = FontWeight.normal;
        fontSize = 8;
        padding = const EdgeInsets.symmetric(
            horizontal: 2, vertical: 12); // Adjusted padding
        textStyle = TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: textColor,
          height: 1.2,
        );
        break;
      case CellType.idle:
        bgColor = AppColors.gray50;
        textColor = AppColors.gray400;
        fontWeight = FontWeight.w300;
        fontSize = 8;
        padding = const EdgeInsets.symmetric(horizontal: 2, vertical: 24);
        textStyle = TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontStyle: FontStyle.italic,
          color: textColor,
          height: 1.0,
        );
        break;
      case CellType.breakCell:
        bgColor = AppColors.gray200;
        textColor = AppColors.black;
        fontWeight = FontWeight.bold;
        fontSize = 7;
        padding = const EdgeInsets.symmetric(horizontal: 2, vertical: 24);
        textStyle = TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: 1.5,
          color: textColor,
          height: 1.0,
        );
        break;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: AppColors.gray300, width: 1),
      ),
      padding: padding,
      alignment: Alignment.center,
      child: Text(
        text, // Removed toUpperCase()
        style: textStyle,
        textAlign: TextAlign.center,
        maxLines: 4,
        overflow: TextOverflow.visible,
      ),
    );
  }
}
