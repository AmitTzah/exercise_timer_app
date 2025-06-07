import 'package:hive/hive.dart';
import 'package:exercise_timer_app/models/exercise.dart';
// Import WorkoutItem

part 'workout_set.g.dart';

@HiveType(typeId: 6) // Changed typeId to 6
class WorkoutSet extends HiveObject {
  @HiveField(0)
  Exercise exercise; // Keep for now, will be refactored to WorkoutItem later

  @HiveField(1)
  int setNumber;

  @HiveField(2)
  bool isRestSet;

  @HiveField(3) // New field to indicate if this is a dedicated rest block
  bool isRestBlock;

  @HiveField(4) // New field for rest block duration
  int? restBlockDuration;

  WorkoutSet({
    required this.exercise,
    required this.setNumber,
    this.isRestSet = false,
    this.isRestBlock = false,
    this.restBlockDuration,
  });
}
