import 'package:hive_flutter/hive_flutter.dart';
import 'package:exercise_timer_app/models/exercise.dart';
import 'package:exercise_timer_app/models/workout_summary.dart';
import 'package:exercise_timer_app/models/goal.dart';
import 'package:exercise_timer_app/models/user_workout.dart';
import 'package:exercise_timer_app/models/workout_set.dart';
import 'package:exercise_timer_app/models/workout_item.dart'; // Import WorkoutItem and its concrete types
import 'package:exercise_timer_app/models/workout_type.dart'; // Import WorkoutType

class DatabaseService {
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ExerciseAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(WorkoutSummaryAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(UserWorkoutAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(ExerciseItemAdapter()); // ExerciseItem typeId
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(RestBlockItemAdapter()); // RestBlockItem typeId
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(GoalAdapter()); // Goal typeId
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(WorkoutSetAdapter()); // WorkoutSet typeId
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(WorkoutTypeAdapter()); // WorkoutType typeId

    _isInitialized = true;
  }

  static Future<Box<UserWorkout>> openUserWorkoutsBox() async {
    return await Hive.openBox<UserWorkout>('userWorkouts');
  }

  static Future<Box<WorkoutSummary>> openWorkoutSummariesBox() async {
    return await Hive.openBox<WorkoutSummary>('workoutSummaries');
  }

  static Future<Box<Goal>> openGoalsBox() async {
    return await Hive.openBox<Goal>('goals');
  }
}
