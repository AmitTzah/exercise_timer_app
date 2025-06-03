import 'package:hive/hive.dart';

part 'exercise.g.dart';

@HiveType(typeId: 0)
class Exercise extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int sets;

  Exercise({required this.name, required this.sets});
}
