import 'package:flutter_test/flutter_test.dart';
import 'package:exercise_timer_app/main.dart';
import 'package:exercise_timer_app/services/database_service.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive for testing

void main() {
  // Initialize Hive for tests
  setUpAll(() async {
    // Use a temporary directory for Hive during tests
    Hive.init('test_hive_path');
    await DatabaseService.init();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  testWidgets('ExerciseTimerApp builds and displays SetupScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ExerciseTimerApp());

    // Verify that SetupScreen is displayed.
    expect(find.text('Exercise Timer Setup'), findsOneWidget);
  });
}
