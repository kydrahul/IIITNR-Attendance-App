/// Shared data model used across all Add-Course wizard steps.
library;

class BranchTimeSlot {
  final String day;
  final String time;
  final String type;
  final String branch;

  const BranchTimeSlot({
    required this.day,
    required this.time,
    required this.type,
    required this.branch,
  });

  Map<String, dynamic> toJson() => {
        'day': day,
        'time': time,
        'type': type,
        'branch': branch,
      };
}

const List<String> kWizardDays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

const List<String> kWizardTimeSlots = [
  '09:00 AM - 10:00 AM',
  '10:00 AM - 11:00 AM',
  '11:00 AM - 12:00 PM',
  '12:00 PM - 01:00 PM',
  '02:00 PM - 03:00 PM',
  '03:00 PM - 04:00 PM',
  '04:00 PM - 05:00 PM',
  '05:00 PM - 06:00 PM',
];

const List<String> kWizardBranches = ['CSE', 'DSAI', 'ECE'];
