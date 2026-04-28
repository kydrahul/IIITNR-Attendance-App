import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/faculty/faculty_colors.dart';
import '../../models/faculty/faculty_models.dart';

enum CellType { header, time, classCell, idle, breakCell }

class FacultyWeeklyTimetableScreen extends StatefulWidget {
  final List<Course> courses;
  final String? highlightCourseCode;

  const FacultyWeeklyTimetableScreen({
    super.key,
    required this.courses,
    this.highlightCourseCode,
  });

  @override
  State<FacultyWeeklyTimetableScreen> createState() =>
      _FacultyWeeklyTimetableScreenState();
}

class _FacultyWeeklyTimetableScreenState
    extends State<FacultyWeeklyTimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  File? _importedTimetableImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedTimetableImage();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedTimetableImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('faculty_timetable_image');
    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (await file.exists()) {
        setState(() {
          _importedTimetableImage = file;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('faculty_timetable_image', image.path);
        setState(() {
          _importedTimetableImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _removeImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('faculty_timetable_image');
    setState(() {
      _importedTimetableImage = null;
    });
  }

  String _abbreviate(String name) {
    if (name.length <= 8) return name;
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) return name.substring(0, 3).toUpperCase();
    return words.where((w) => w.isNotEmpty).map((w) => w[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FacultyColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                color: FacultyColors.white,
                border: Border(
                  bottom: BorderSide(color: FacultyColors.gray100),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0).copyWith(bottom: 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: FacultyColors.gray50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              LucideIcons.arrowLeft,
                              size: 20,
                              color: FacultyColors.gray600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Faculty Schedule",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: FacultyColors.gray900,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Manage your weekly classes",
                              style: TextStyle(
                                fontSize: 13,
                                color: FacultyColors.gray500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    labelColor: FacultyColors.primary,
                    unselectedLabelColor: FacultyColors.gray500,
                    indicatorColor: FacultyColors.primary,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: "System Schedule"),
                      Tab(text: "Imported Image"),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSystemTimetable(),
                  _buildImportedTimetable(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportedTimetable() {
    if (_importedTimetableImage == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "No Custom Timetable",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: FacultyColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Import a screenshot or photo\nof your weekly timetable.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: FacultyColors.gray500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: FacultyColors.black,
                foregroundColor: FacultyColors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Import Image"),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _removeImage,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text("Remove"),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FacultyColors.black,
                  foregroundColor: FacultyColors.white,
                ),
                child: const Text("Replace"),
              ),
            ],
          ),
        ),
        Expanded(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.file(
                _importedTimetableImage!,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemTimetable() {
    return Container(
      color: FacultyColors.white,
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _buildTimetableGrid(),
        ),
      ),
    );
  }

  Widget _buildTimetableGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(height: 8, color: FacultyColors.white),
        Container(
          color: FacultyColors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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
        ),
      ],
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 24,
          decoration: BoxDecoration(
            color: FacultyColors.gray100,
            border: Border.all(color: FacultyColors.gray300, width: 1),
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

  Widget _buildTimeRow(String timeSlot) {
    Map<String, String> getClassInfo(String day, String time) {
      final slotHour = time.split(':')[0].padLeft(2, '0');
      for (var course in widget.courses) {
        for (var slot in course.timetable) {
          if (slot.day == day) {
            final timeStr = slot.time.toString();
            final classHour =
                timeStr.split(' ')[0].split(':')[0].padLeft(2, '0');
            if (classHour == slotHour) {
              final abbr = _abbreviate(course.name);
              final sem = course.semester ?? '';
              final branch = course.department;
              return {
                "text": "$abbr\nSem $sem $branch\n${slot.room ?? ''}",
                "code": course.code,
              };
            }
          }
        }
      }
      return {"text": "", "code": ""};
    }

    final monInfo = getClassInfo("Monday", timeSlot);
    final tueInfo = getClassInfo("Tuesday", timeSlot);
    final wedInfo = getClassInfo("Wednesday", timeSlot);
    final thuInfo = getClassInfo("Thursday", timeSlot);
    final friInfo = getClassInfo("Friday", timeSlot);

    return Row(
      children: [
        _buildCell(timeSlot, CellType.time, width: 40, height: 64),
        _buildCell(monInfo["text"]!, CellType.classCell,
            width: 60,
            height: 64,
            isHighlighted: monInfo["code"] == widget.highlightCourseCode),
        _buildCell(tueInfo["text"]!, CellType.classCell,
            width: 60,
            height: 64,
            isHighlighted: tueInfo["code"] == widget.highlightCourseCode),
        _buildCell(wedInfo["text"]!, CellType.classCell,
            width: 60,
            height: 64,
            isHighlighted: wedInfo["code"] == widget.highlightCourseCode),
        _buildCell(thuInfo["text"]!, CellType.classCell,
            width: 60,
            height: 64,
            isHighlighted: thuInfo["code"] == widget.highlightCourseCode),
        _buildCell(friInfo["text"]!, CellType.classCell,
            width: 60,
            height: 64,
            isHighlighted: friInfo["code"] == widget.highlightCourseCode),
      ],
    );
  }

  Widget _buildLunchRow() {
    return Row(
      children: [
        _buildCell("1:00", CellType.time, width: 40, height: 64),
        _buildCell("Lunch", CellType.breakCell, width: 300, height: 64),
      ],
    );
  }

  Widget _buildCell(
    String text,
    CellType type, {
    required double width,
    double height = 24,
    bool isHighlighted = false,
  }) {
    Color bgColor;
    Color textColor;
    FontWeight fontWeight;
    double fontSize;
    TextStyle? textStyle;
    EdgeInsets padding;

    switch (type) {
      case CellType.header:
        bgColor = FacultyColors.gray100;
        textColor = FacultyColors.black;
        fontWeight = FontWeight.bold;
        fontSize = 10;
        padding = const EdgeInsets.symmetric(horizontal: 2, vertical: 4);
        textStyle = TextStyle(
          fontWeight: fontWeight,
          fontSize: fontSize,
          color: textColor,
          height: 1.0,
        );
        break;
      case CellType.time:
        bgColor = FacultyColors.white;
        textColor = FacultyColors.gray500;
        fontWeight = FontWeight.normal;
        fontSize = 9;
        padding = const EdgeInsets.symmetric(horizontal: 2, vertical: 8);
        textStyle = TextStyle(
          fontFamily: 'monospace',
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: textColor,
          height: 1.0,
        );
        break;
      case CellType.classCell:
        bgColor = text.isNotEmpty ? FacultyColors.white : FacultyColors.gray50;
        textColor = FacultyColors.black;
        fontWeight = FontWeight.normal;
        fontSize = 11;
        padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 6);
        textStyle = TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: textColor,
          height: 1.2,
        );
        break;
      case CellType.breakCell:
        bgColor = FacultyColors.gray200;
        textColor = FacultyColors.black;
        fontWeight = FontWeight.bold;
        fontSize = 10;
        padding = const EdgeInsets.symmetric(horizontal: 2, vertical: 8);
        textStyle = TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: 1.5,
          color: textColor,
          height: 1.0,
        );
        break;
      default:
        bgColor = FacultyColors.gray50;
        textColor = FacultyColors.gray400;
        fontWeight = FontWeight.w300;
        fontSize = 8;
        padding = const EdgeInsets.symmetric(horizontal: 2, vertical: 8);
        textStyle = TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: textColor,
          height: 1.0,
        );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isHighlighted ? FacultyColors.blue50 : bgColor,
        border: Border.all(
          color: isHighlighted ? FacultyColors.primary : FacultyColors.gray300,
          width: isHighlighted ? 1.5 : 1,
        ),
      ),
      padding: padding,
      alignment: Alignment.center,
      child: Text(
        text,
        style: isHighlighted
            ? textStyle.copyWith(
                color: FacultyColors.primary,
                fontWeight: FontWeight.bold,
              )
            : textStyle,
        textAlign: TextAlign.center,
        maxLines: 4,
        overflow: TextOverflow.visible,
      ),
    );
  }
}
