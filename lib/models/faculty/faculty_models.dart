class Student {
  final String id;
  final String name;
  final String rollNo;
  final String? status; // 'present', 'absent', null
  final String? markedAt;

  Student({
    required this.id,
    required this.name,
    required this.rollNo,
    this.status,
    this.markedAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id']?.toString() ?? json['studentId']?.toString() ?? '',
      name: json['name'] ?? json['studentName'] ?? '',
      rollNo: json['rollNo'] ?? json['roll'] ?? '',
      status: json['status'],
      markedAt: json['markedAt']?.toString(),
    );
  }
}

class TimetableSlot {
  final String day;
  final String time;
  final String type; // 'theory', 'lab'
  final String? room;

  TimetableSlot({
    required this.day,
    required this.time,
    required this.type,
    this.room,
  });

  factory TimetableSlot.fromJson(Map<String, dynamic> json) {
    return TimetableSlot(
      day: json['day'] ?? '',
      time: json['time'] ?? '',
      type: json['type'] ?? 'theory',
      room: json['room'],
    );
  }
}

class Course {
  final String id;
  final String code;
  final String name;
  final String section;
  final int enrolledCount;
  final List<TimetableSlot> timetable;
  final String joinCode;
  final String department;
  final String academicYear;
  final String? className;
  final int credits;
  final String? semester;
  final String? session; // 'Spring', 'Autumn'

  Course({
    required this.id,
    required this.code,
    required this.name,
    required this.section,
    required this.enrolledCount,
    required this.timetable,
    required this.joinCode,
    required this.department,
    required this.academicYear,
    this.className,
    required this.credits,
    this.semester,
    this.session,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      section: json['section'] ?? 'A',
      enrolledCount: json['enrolledCount'] ?? 0,
      timetable: (json['timetable'] as List?)
              ?.map((t) => TimetableSlot.fromJson(t))
              .toList() ??
          [],
      joinCode: json['joinCode'] ?? '',
      department: json['department'] ?? '',
      academicYear: json['academicYear'] ?? '',
      className: json['className'],
      credits: json['credits'] ?? 3,
      semester: json['semester'],
      session: json['session'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class AttendanceSession {
  final String id;
  final String courseId;
  final String qrData;
  final int qrVersion;
  final DateTime startTime;
  final DateTime? endTime;
  final String? classType;
  final double? latitude;
  final double? longitude;
  final int radius;

  AttendanceSession({
    required this.id,
    required this.courseId,
    required this.qrData,
    required this.qrVersion,
    required this.startTime,
    this.endTime,
    this.classType,
    this.latitude,
    this.longitude,
    required this.radius,
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    return AttendanceSession(
      id: json['sessionId'] ?? json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      qrData: json['qrData'] ?? '',
      qrVersion: json['qrVersion'] ?? 1,
      startTime: DateTime.tryParse(json['startTime'] ?? '') ?? DateTime.now(),
      endTime:
          json['endTime'] != null ? DateTime.tryParse(json['endTime']) : null,
      classType: json['classType'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      radius: json['radius'] ?? 1100,
    );
  }
}
