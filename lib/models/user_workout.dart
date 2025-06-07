import 'package:hive/hive.dart';
import 'package:exercise_timer_app/models/workout_item.dart';
import 'package:exercise_timer_app/models/workout_type.dart';

part 'user_workout.g.dart';

@HiveType(typeId: 2) // Use a new unique typeId
class UserWorkout extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<WorkoutItem> items; // Changed from List<Exercise> to List<WorkoutItem>

  @HiveField(3)
  int totalWorkoutTime; // in seconds

  @HiveField(4)
  WorkoutType workoutType;

  @HiveField(5)
  int? selectedLevel; // Nullable, default to 1 if null

  @HiveField(6) // Re-using field 6
  bool? selectedSurvivalMode; // Nullable, default to false if null

  UserWorkout({
    required this.id,
    required this.name,
    required this.items,
    required this.totalWorkoutTime,
    this.workoutType = WorkoutType.sequential, // Default to sequential
    this.selectedLevel,
    this.selectedSurvivalMode,
  });
}
