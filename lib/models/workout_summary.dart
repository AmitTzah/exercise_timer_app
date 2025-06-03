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
  Duration totalDuration;

  WorkoutSummary({
    required this.date,
    required this.exercises,
    required this.totalDuration,
  });
}
