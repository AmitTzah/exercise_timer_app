import 'package:hive/hive.dart';
import 'package:exercise_timer_app/models/workout_set.dart';
import 'package:exercise_timer_app/models/workout_type.dart';

part 'workout_summary.g.dart';

@HiveType(typeId: 1)
class WorkoutSummary extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  List<WorkoutSet> performedSets; // Changed from exercises to performedSets

  @HiveField(2)
  int totalDurationInSeconds;

  @HiveField(3, defaultValue: '')
  String workoutName;

  @HiveField(4, defaultValue: 1) // Default level to 1
  int workoutLevel;

  @HiveField(5, defaultValue: false)
  bool isSurvivalMode;

  @HiveField(6)
  WorkoutType workoutType;

  @HiveField(7, defaultValue: false) // New field for whether workout was stopped prematurely
  bool wasStoppedPrematurely;

  @HiveField(8) // Re-using field 8
  int totalSets;

  WorkoutSummary({
    required this.date,
    required this.performedSets,
    required this.totalDurationInSeconds,
    required this.workoutName,
    required this.workoutLevel,
    required this.isSurvivalMode,
    required this.workoutType,
    required this.wasStoppedPrematurely,
    required this.totalSets,
  });

  // Helper to get Duration object
  Duration get totalDuration => Duration(seconds: totalDurationInSeconds);
}
