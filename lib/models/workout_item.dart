import 'package:hive/hive.dart';
import 'package:exercise_timer_app/models/exercise.dart';

part 'workout_item.g.dart';

abstract class WorkoutItem extends HiveObject {
  WorkoutItem();
}

@HiveType(typeId: 3) // Changed typeId for ExerciseItem
class ExerciseItem extends WorkoutItem {
  @HiveField(0)
  Exercise exercise;

  ExerciseItem({required this.exercise});
}

@HiveType(typeId: 4) // Changed typeId for RestBlockItem
class RestBlockItem extends WorkoutItem {
  @HiveField(0)
  int durationInSeconds;

  RestBlockItem({required this.durationInSeconds});
}
