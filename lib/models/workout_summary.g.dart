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
      performedSets: (fields[1] as List).cast<WorkoutSet>(),
      totalDurationInSeconds: fields[2] as int,
      workoutName: fields[3] == null ? '' : fields[3] as String,
      workoutLevel: fields[4] == null ? 1 : fields[4] as int,
      isSurvivalMode: fields[5] == null ? false : fields[5] as bool,
      isAlternatingSets: fields[6] == null ? false : fields[6] as bool,
      wasStoppedPrematurely: fields[7] == null ? false : fields[7] as bool,
      totalSets: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSummary obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.performedSets)
      ..writeByte(2)
      ..write(obj.totalDurationInSeconds)
      ..writeByte(3)
      ..write(obj.workoutName)
      ..writeByte(4)
      ..write(obj.workoutLevel)
      ..writeByte(5)
      ..write(obj.isSurvivalMode)
      ..writeByte(6)
      ..write(obj.isAlternatingSets)
      ..writeByte(7)
      ..write(obj.wasStoppedPrematurely)
      ..writeByte(8)
      ..write(obj.totalSets);
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
