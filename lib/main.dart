import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:exercise_timer_app/services/database_service.dart';
import 'package:exercise_timer_app/screens/home_screen.dart';
import 'package:exercise_timer_app/repositories/user_workout_repository.dart';
import 'package:exercise_timer_app/repositories/workout_summary_repository.dart';
import 'package:exercise_timer_app/services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();

  final userWorkoutsBox = await DatabaseService.openUserWorkoutsBox();
  final workoutSummariesBox = await DatabaseService.openWorkoutSummariesBox();
  // final goalsBox = await DatabaseService.openGoalsBox(); // For future use

  runApp(
    MultiProvider(
      providers: [
        Provider<UserWorkoutRepository>(
          create: (_) => UserWorkoutRepository(userWorkoutsBox),
          dispose: (_, repo) => repo.listenable.removeListener(() {}), // Dispose listener if any
        ),
        Provider<WorkoutSummaryRepository>(
          create: (_) => WorkoutSummaryRepository(workoutSummariesBox),
          dispose: (_, repo) => repo.listenable.removeListener(() {}), // Dispose listener if any
        ),
        Provider<AudioService>(
          create: (_) => AudioService(),
          dispose: (_, audioService) => audioService.dispose(),
        ),
      ],
      child: const ExerciseTimerApp(),
    ),
  );
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
      home: const HomeScreen(),
    );
  }
}
