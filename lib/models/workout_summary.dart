import 'package:hive/hive.dart';
import 'package:exercise_timer_app/models/exercise.dart';

part 'workout_summary.g.dart';

@HiveType(typeId: 1)
class WorkoutSummary extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  List<Exercise> exercises;

  @HiveField(2)
  int totalDurationInSeconds;

  WorkoutSummary({
    required this.date,
    required this.exercises,
    required this.totalDurationInSeconds,
  });

  // Helper to get Duration object
  Duration get totalDuration => Duration(seconds: totalDurationInSeconds);
}
