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

  @HiveField(3) // New field for custom audio file name
  String? audioFileName; // Optional: custom audio file for this exercise

  Exercise({required this.name, required this.sets, this.reps, this.audioFileName}); // Added reps and audioFileName to constructor
}
