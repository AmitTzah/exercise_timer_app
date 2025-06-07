import 'package:hive/hive.dart';
import 'package:exercise_timer_app/models/workout_item.dart'; // Import the new workout_item.dart

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

  @HiveField(4) // Re-using field 4
  bool? selectedAlternateSets; // Nullable, default to false if null

  @HiveField(5) // Re-using field 5
  int? selectedLevel; // Nullable, default to 1 if null

  @HiveField(6) // Re-using field 6
  bool? selectedSurvivalMode; // Nullable, default to false if null

  UserWorkout({
    required this.id,
    required this.name,
    required this.items, // Changed from exercises to items
    required this.totalWorkoutTime,
    this.selectedAlternateSets,
    this.selectedLevel,
    this.selectedSurvivalMode,
  });
}
