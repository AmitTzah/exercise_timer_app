import 'package:hive_flutter/hive_flutter.dart';
import 'package:exercise_timer_app/models/exercise.dart';
import 'package:exercise_timer_app/models/workout_summary.dart';
import 'package:exercise_timer_app/models/goal.dart';
import 'package:exercise_timer_app/models/user_workout.dart'; // Import new model

class DatabaseService {
  static late Box<UserWorkout> _userWorkoutsBox;
  static bool _isInitialized = false; // Flag to track initialization

  static Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    await Hive.initFlutter();

    // Register adapters only if not already registered
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ExerciseAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(WorkoutSummaryAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(UserWorkoutAdapter()); // UserWorkout uses typeId 2
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(GoalAdapter()); // Assuming GoalAdapter uses typeId 3

    await Hive.openBox<WorkoutSummary>('workoutSummaries');
    await Hive.openBox<Goal>('goals');
    _userWorkoutsBox = await Hive.openBox<UserWorkout>('userWorkouts');

    _isInitialized = true;
  }

  // CRUD operations for UserWorkout
  static Future<void> saveUserWorkout(UserWorkout workout) async {
    await _userWorkoutsBox.put(workout.id, workout);
  }

  static UserWorkout? getUserWorkout(String id) {
    return _userWorkoutsBox.get(id);
  }

  static List<UserWorkout> getAllUserWorkouts() {
    final workouts = _userWorkoutsBox.values.toList();
    return workouts;
  }

  static Future<void> deleteUserWorkout(String id) async {
    await _userWorkoutsBox.delete(id);
  }
}
