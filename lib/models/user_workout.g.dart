// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_workout.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserWorkoutAdapter extends TypeAdapter<UserWorkout> {
  @override
  final int typeId = 2;

  @override
  UserWorkout read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserWorkout(
      id: fields[0] as String,
      name: fields[1] as String,
      exercises: (fields[2] as List).cast<Exercise>(),
      intervalTimeBetweenSets: fields[3] as int,
      totalWorkoutTime: fields[4] as int,
      selectedAlternateSets: fields[5] as bool?,
      selectedLevel: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, UserWorkout obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.exercises)
      ..writeByte(3)
      ..write(obj.intervalTimeBetweenSets)
      ..writeByte(4)
      ..write(obj.totalWorkoutTime)
      ..writeByte(5)
      ..write(obj.selectedAlternateSets)
      ..writeByte(6)
      ..write(obj.selectedLevel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserWorkoutAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
