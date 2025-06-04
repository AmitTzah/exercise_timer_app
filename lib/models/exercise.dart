import 'package:hive/hive.dart';

part 'exercise.g.dart';

@HiveType(typeId: 0)
class Exercise extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int sets;

  @HiveField(2) // New field for reps
  int? reps; // Reps can be optional

  Exercise({required this.name, required this.sets, this.reps}); // Added reps to constructor
}
