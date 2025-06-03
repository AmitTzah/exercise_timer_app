// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_summary.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutSummaryAdapter extends TypeAdapter<WorkoutSummary> {
  @override
  final int typeId = 1;

  @override
  WorkoutSummary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutSummary(
      date: fields[0] as DateTime,
      exercises: (fields[1] as List).cast<Exercise>(),
      totalDuration: fields[2] as Duration,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSummary obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.exercises)
      ..writeByte(2)
      ..write(obj.totalDuration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSummaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
