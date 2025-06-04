import 'package:hive/hive.dart';
import 'package:exercise_timer_app/models/exercise.dart';

part 'user_workout.g.dart';

@HiveType(typeId: 2) // Use a new unique typeId
class UserWorkout extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<Exercise> exercises;

  @HiveField(3)
  int intervalTimeBetweenSets;

  @HiveField(4)
  int totalWorkoutTime; // in seconds

  @HiveField(5) // Re-using field 5, previously alternateSets
  bool? selectedAlternateSets; // Nullable, default to false if null

  @HiveField(6) // New field for selected level
  int? selectedLevel; // Nullable, default to 1 if null

  UserWorkout({
    required this.id,
    required this.name,
    required this.exercises,
    required this.intervalTimeBetweenSets,
    required this.totalWorkoutTime,
    this.selectedAlternateSets,
    this.selectedLevel,
  });
}
