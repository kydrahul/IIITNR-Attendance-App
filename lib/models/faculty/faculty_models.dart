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
    String? status = json['status']?.toString();
    // If status is missing but 'present' boolean is there (from listCourseStudents)
    if (status == null && json['present'] != null) {
      status = (json['present'] == true) ? 'present' : 'absent';
    }

    return Student(
      id: (json['id'] ?? json['studentId'] ?? '').toString(),
      name: (json['name'] ?? json['studentName'] ?? 'Unknown').toString(),
      rollNo: (json['rollNo'] ?? json['roll'] ?? 'N/A').toString(),
      status: status,
      markedAt: json['markedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rollNo': rollNo,
      'status': status,
      'markedAt': markedAt,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'time': time,
      'type': type,
      'room': room,
    };
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
  final String? degree; // 'B.Tech', 'M.Tech'

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
    this.degree,
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
      department: json['department'] ?? json['branch'] ?? '',
      academicYear: json['year']?.toString() ?? json['academicYear']?.toString() ?? '',
      className: json['className'],
      credits: json['credits'] ?? 3,
      semester: json['semester']?.toString(),
      session: json['session'],
      degree: json['degree'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'section': section,
      'enrolledCount': enrolledCount,
      'timetable': timetable.map((t) => t.toJson()).toList(),
      'joinCode': joinCode,
      'department': department,
      'academicYear': academicYear,
      'className': className,
      'credits': credits,
      'semester': semester,
      'session': session,
      'degree': degree,
    };
  }
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
  final bool isLocationRequired;

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
    this.isLocationRequired = true,
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
      isLocationRequired: json['isLocationRequired'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'qrData': qrData,
      'qrVersion': qrVersion,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'classType': classType,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'isLocationRequired': isLocationRequired,
    };
  }
}

class FacultyProfile {
  final String id;
  final String facultyId;
  final String employeeId;
  final String name;
  final String email;
  final String department;
  final String position;
  final String designation;
  final String? photoUrl;
  final Map<String, dynamic> settings;

  FacultyProfile({
    required this.id,
    required this.facultyId,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.department,
    required this.position,
    required this.designation,
    this.photoUrl,
    this.settings = const {},
  });

  factory FacultyProfile.fromJson(Map<String, dynamic> json) {
    return FacultyProfile(
      id: json['_id'] ?? json['id'] ?? '',
      facultyId: json['facultyId'] ?? json['employeeId'] ?? '',
      employeeId: json['employeeId'] ?? json['facultyId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      department: json['department'] ?? '',
      position: json['position'] ?? json['designation'] ?? '',
      designation: json['designation'] ?? json['position'] ?? '',
      photoUrl: json['photoUrl'] as String?,
      settings: json['settings'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'facultyId': facultyId,
      'employeeId': employeeId,
      'name': name,
      'email': email,
      'department': department,
      'position': position,
      'designation': designation,
      'photoUrl': photoUrl,
      'settings': settings,
    };
  }
}
class RoomModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  RoomModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown Room').toString(),
      latitude: (json['latitude'] as num? ?? json['Latitude'] as num? ?? 0.0).toDouble(),
      longitude: (json['longitude'] as num? ?? 
                  json['Longitude'] as num? ?? 
                  json['longitute'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
