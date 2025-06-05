import 'package:hive/hive.dart';
import 'package:exercise_timer_app/models/exercise.dart';

part 'workout_set.g.dart';

@HiveType(typeId: 4) // Changed typeId to 4 to avoid collision
class WorkoutSet extends HiveObject {
  @HiveField(0)
  Exercise exercise;

  @HiveField(1)
  int setNumber;

  @HiveField(2)
  bool isRestSet; // New field to indicate if this is a rest set

  WorkoutSet({required this.exercise, required this.setNumber, this.isRestSet = false});
}
