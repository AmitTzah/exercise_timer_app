// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseItemAdapter extends TypeAdapter<ExerciseItem> {
  @override
  final int typeId = 3;

  @override
  ExerciseItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseItem(
      exercise: fields[0] as Exercise,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseItem obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.exercise);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RestBlockItemAdapter extends TypeAdapter<RestBlockItem> {
  @override
  final int typeId = 4;

  @override
  RestBlockItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RestBlockItem(
      durationInSeconds: fields[0] as int,
    );
  }

  @override
  void write(BinaryWriter writer, RestBlockItem obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.durationInSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RestBlockItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
