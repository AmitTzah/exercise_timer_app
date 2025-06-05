import 'package:hive/hive.dart';
import 'package:exercise_timer_app/models/workout_set.dart';

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

  @HiveField(6, defaultValue: false)
  bool isAlternatingSets;

  @HiveField(7, defaultValue: 60) // Default interval time to 60 seconds
  int intervalTime;

  @HiveField(8, defaultValue: false) // New field for whether workout was stopped prematurely
  bool wasStoppedPrematurely;

  @HiveField(9)
  int totalSets;

  WorkoutSummary({
    required this.date,
    required this.performedSets, // Changed parameter name
    required this.totalDurationInSeconds,
    required this.workoutName,
    required this.workoutLevel,
    required this.isSurvivalMode,
    required this.isAlternatingSets,
    required this.intervalTime,
    required this.wasStoppedPrematurely, // New required parameter
    required this.totalSets,
  });

  // Helper to get Duration object
  Duration get totalDuration => Duration(seconds: totalDurationInSeconds);
}
