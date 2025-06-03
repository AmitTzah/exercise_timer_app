import 'package:hive_flutter/hive_flutter.dart';
import 'package:exercise_timer_app/models/exercise.dart';
import 'package:exercise_timer_app/models/workout_summary.dart';
import 'package:exercise_timer_app/models/goal.dart';

class DatabaseService {
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ExerciseAdapter());
    Hive.registerAdapter(WorkoutSummaryAdapter());
    Hive.registerAdapter(GoalAdapter());

    await Hive.openBox<WorkoutSummary>('workoutSummaries');
    await Hive.openBox<Goal>('goals');
    // No need to open a box for Exercise directly as it's embedded in WorkoutSummary
  }
}
