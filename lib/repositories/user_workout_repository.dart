import 'package:hive_flutter/hive_flutter.dart'; // For ValueListenable and Box
import 'package:exercise_timer_app/models/user_workout.dart';
import 'package:flutter/foundation.dart'; // For ValueListenable

class UserWorkoutRepository {
  final Box<UserWorkout> _userWorkoutsBox;

  UserWorkoutRepository(this._userWorkoutsBox);

  Future<void> saveUserWorkout(UserWorkout workout) async {
    await _userWorkoutsBox.put(workout.id, workout);
  }

  UserWorkout? getUserWorkout(String id) {
    return _userWorkoutsBox.get(id);
  }

  List<UserWorkout> getAllUserWorkouts() {
    return _userWorkoutsBox.values.toList();
  }

  Future<void> deleteUserWorkout(String id) async {
    await _userWorkoutsBox.delete(id);
  }

  ValueListenable<Box<UserWorkout>> get listenable => _userWorkoutsBox.listenable();
}
