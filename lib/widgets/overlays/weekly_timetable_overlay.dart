import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';

enum CellType { header, time, classCell, idle, breakCell }

class WeeklyTimetableOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const WeeklyTimetableOverlay({super.key, required this.onClose});

  @override
  State<WeeklyTimetableOverlay> createState() => _WeeklyTimetableOverlayState();
}

class _WeeklyTimetableOverlayState extends State<WeeklyTimetableOverlay> {
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
      if (mounted) {
        setState(() {
          _timetable = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _currentSessionLabel() {
    final now = DateTime.now();
    final session = now.month >= 7 ? 'Autumn' : 'Spring';
    return '$session ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.gray300),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Week Schedule",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentSessionLabel(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          border: Border.all(color: AppColors.gray200),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _currentSessionLabel(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.gray700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.gray100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.x,
                            size: 16,
                            color: AppColors.gray600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Timetable Grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Error: $_error',
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _fetchTimetable,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          color: AppColors.background,
                          padding: const EdgeInsets.all(4),
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
    // If no timetable data, show empty grid
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray300,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.gray300),
      ),
      child: Column(
        children: [
          _buildHeaderRow(),
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
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        _buildCell("Time", CellType.header, width: 30),
        _buildCell("Mon", CellType.header, width: 60),
        _buildCell("Tue", CellType.header, width: 60),
        _buildCell("Wed", CellType.header, width: 60),
        _buildCell("Thu", CellType.header, width: 60),
        _buildCell("Fri", CellType.header, width: 60),
      ],
    );
  }

  Widget _buildTimeRow(String time) {
    String getClassFor(String day, String timeSlot) {
      if (_timetable[day] == null) return "";
      final classes = _timetable[day] as List<dynamic>;
      final slotTime = timeSlot.split(':')[0].padLeft(2, '0');
      for (var cls in classes) {
        final classTime = cls['time']
            .toString()
            .split(' - ')[0]
            .split(':')[0]
            .padLeft(2, '0');
        if (classTime == slotTime) {
          return "${cls['courseName']}\n${cls['facultyName'] ?? ''}";
        }
      }
      return "";
    }

    return Row(
      children: [
        _buildCell(time, CellType.time, width: 30, height: 48),
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
        _buildCell("1:00", CellType.time, width: 30, height: 48),
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
        padding = const EdgeInsets.symmetric(horizontal: 2, vertical: 8);
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
        padding = const EdgeInsets.symmetric(horizontal: 2, vertical: 8);
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
        text.toUpperCase(),
        style: textStyle,
        textAlign: TextAlign.center,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
