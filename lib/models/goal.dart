import 'package:hive/hive.dart';

part 'goal.g.dart';

@HiveType(typeId: 2)
class Goal extends HiveObject {
  @HiveField(0)
  String description;

  @HiveField(1)
  DateTime targetDate;

  @HiveField(2)
  double progress; // e.g., 0.0 to 1.0 or specific value

  Goal({
    required this.description,
    required this.targetDate,
    this.progress = 0.0,
  });
}
