import 'package:intl/intl.dart';

class ScheduleItem {
  final int id;
  final String courseId; // Added courseId
  final int start;
  final int end;
  final String subject;
  final String faculty;
  final int credits;
  final int attendance;
  final String status; // "Present", "Absent", "Upcoming"

  ScheduleItem({
    required this.id,
    required this.courseId,
    required this.start,
    required this.end,
    required this.subject,
    required this.faculty,
    required this.credits,
    required this.attendance,
    required this.status,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    // Parse time string e.g. "09:30 - 10:30" or "09:00 AM - 10:00 AM"
    final timeStr = json['time'] as String? ?? '09:00 - 10:00';
    // Normalise AM/PM format to 24h before splitting
    String normalize(String t) {
      t = t.trim();
      if (t.contains('AM') || t.contains('PM')) {
        final isPm = t.contains('PM');
        t = t.replaceAll(RegExp(r'[AaPp][Mm]'), '').trim();
        final parts = t.split(':');
        int h = int.tryParse(parts[0]) ?? 0;
        if (isPm && h != 12) h += 12;
        if (!isPm && h == 12) h = 0;
        return '$h:${parts.length > 1 ? parts[1] : '00'}';
      }
      return t;
    }

    final timeParts = timeStr.split(' - ');
    final startNorm = normalize(timeParts[0]);
    final endRaw    = timeParts.length > 1 ? timeParts[1] : '';
    final endNorm   = endRaw.isNotEmpty ? normalize(endRaw) : '';

    final startHour = int.tryParse(startNorm.split(':')[0]) ?? 9;
    final endHour   = endNorm.isNotEmpty
        ? (int.tryParse(endNorm.split(':')[0]) ?? (startHour + 1))
        : startHour + 1;

    return ScheduleItem(
      id: json['id'] is String
          ? int.tryParse(json['id']) ?? 0
          : json['id'] ?? 0,
      courseId: json['courseId']?.toString() ?? '',
      start: startHour,
      end: endHour,
      subject: json['courseName'] ?? '',
      faculty: json['facultyName'] ?? json['faculty'] ?? '',
      credits: json['credits'] ?? 3,
      attendance: json['attendance'] ?? 0,
      status: json['status'] ?? 'Upcoming',
    );
  }
}

class Course {
  final String id;
  final String name;
  final String faculty;
  final int credits;
  final double attendance;
  final int totalClasses;
  final int attended;
  final int missed;
  final ContactInfo contact;
  final List<ClassSchedule> schedule;
  final String status; // 'approved', 'pending', 'denied'

  Course({
    required this.id,
    required this.name,
    required this.faculty,
    required this.credits,
    required this.attendance,
    required this.totalClasses,
    required this.attended,
    required this.missed,
    required this.contact,
    required this.schedule,
    this.status = 'approved',
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      faculty: json['facultyName'] ?? json['faculty'] ?? '',
      credits: json['credits'] ?? 0,
      attendance: (json['attendance'] as num?)?.toDouble() ?? 0.0,
      totalClasses: json['totalClasses'] ?? 0,
      attended: json['attended'] ?? 0,
      missed: json['missed'] ?? 0,
      contact: ContactInfo.fromJson(json['contact'] ?? {}),
      schedule: ((json['schedule'] ?? json['timetable']) as List<dynamic>?)
              ?.map((e) => ClassSchedule.fromJson(e))
              .toList() ??
          [],
      status: json['status'] ?? 'approved',
    );
  }
}

class ContactInfo {
  final String phone;
  final String email;

  ContactInfo({required this.phone, required this.email});

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      phone: (json['phone'] ?? json['mobile'] ?? '').toString(),
      email: json['email'] ?? '',
    );
  }
}

class ClassSchedule {
  final String day;
  final String time;
  final String room;
  final String type; // 'Theory' or 'Lab'

  ClassSchedule({
    required this.day,
    required this.time,
    required this.room,
    this.type = 'Theory',
  });

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      day: json['day'] ?? '',
      time: json['time'] ?? '',
      room: json['room'] ?? '',
      type: json['type'] ?? 'Theory',
    );
  }
}

class AttendanceRecord {
  final String id;
  final String date;
  final String day; // Added day
  final String time;
  final String type; // Added type
  final String status; // "Present", "Absent"
  final String room; // Added room

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.day,
    required this.time,
    required this.type,
    required this.status,
    required this.room,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    String dateStr = '';
    String timeStr = '';
    DateTime? dateTime;

    if (json['markedAt'] != null) {
      dateTime = DateTime.parse(json['markedAt']).toLocal();
      dateStr = dateTime.toString().split(' ')[0];
      timeStr = DateFormat('hh:mm a').format(dateTime);
    } else {
      dateStr = json['date'] ?? '';
      timeStr = json['time'] ?? '';
      if (dateStr.isNotEmpty) {
        try {
          dateTime = DateTime.parse(dateStr);
        } catch (_) {}
      }
    }

    // Derive day name from date if not provided
    String dayStr = json['day'] ?? '';
    if (dayStr.isEmpty && dateTime != null) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      dayStr = days[dateTime.weekday - 1];
    }

    return AttendanceRecord(
      id: json['id']?.toString() ?? '',
      date: dateStr,
      day: dayStr,
      time: timeStr,
      type: json['type'] ?? 'Theory', // Default to Theory if missing
      status: json['status'] == 'present' ? 'Present' : 'Absent',
      room: (json['roomNumber'] ?? json['room'] ?? 'N/A').toString(),
    );
  }
}
