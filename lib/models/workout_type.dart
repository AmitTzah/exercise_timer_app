import 'package:hive/hive.dart';

part 'workout_type.g.dart';

@HiveType(typeId: 7) // Changed typeId to 7
enum WorkoutType {
  @HiveField(0)
  sequential,

  @HiveField(1)
  alternating,
}
