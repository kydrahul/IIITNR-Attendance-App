import 'package:flutter_test/flutter_test.dart';

import 'package:iiitnr_attendance/main.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    // Verify the app widget can be created without errors
    expect(() => const StudentApp(initialRoute: '/login'), returnsNormally);
  });
}
