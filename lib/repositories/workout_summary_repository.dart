import 'package:hive_flutter/hive_flutter.dart'; // For Box
import 'package:flutter/foundation.dart'; // For ValueListenable
import 'package:exercise_timer_app/models/workout_summary.dart';

class WorkoutSummaryRepository {
  final Box<WorkoutSummary> _workoutSummariesBox;

  WorkoutSummaryRepository(this._workoutSummariesBox);

  Future<void> addWorkoutSummary(WorkoutSummary summary) async {
    await _workoutSummariesBox.add(summary);
  }

  List<WorkoutSummary> getAllWorkoutSummaries() {
    return _workoutSummariesBox.values.toList();
  }

  Future<void> deleteWorkoutSummary(int key) async {
    await _workoutSummariesBox.delete(key);
  }

  ValueListenable<Box<WorkoutSummary>> get listenable => _workoutSummariesBox.listenable();
}
