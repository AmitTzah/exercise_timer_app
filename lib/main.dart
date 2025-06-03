import 'package:flutter/material.dart';
import 'package:exercise_timer_app/services/database_service.dart';
import 'package:exercise_timer_app/screens/home_screen.dart'; // Import the new home screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
  runApp(const ExerciseTimerApp());
}

class ExerciseTimerApp extends StatelessWidget {
  const ExerciseTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exercise Timer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(), // Set HomeScreen as the new entry point
    );
  }
}
