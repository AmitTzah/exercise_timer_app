import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:exercise_timer_app/models/exercise.dart';

class SettingsService {
  static const String _exercisesKey = 'exercises';
  static const String _intervalTimeKey = 'intervalTime';

  Future<List<Exercise>> loadExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final String? exercisesJson = prefs.getString(_exercisesKey);
    if (exercisesJson == null) {
      return [];
    }
    final List<dynamic> decoded = json.decode(exercisesJson);
    return decoded.map((e) => Exercise(name: e['name'], sets: e['sets'])).toList();
  }

  Future<void> saveExercises(List<Exercise> exercises) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> exercisesMap = exercises
        .map((e) => {'name': e.name, 'sets': e.sets})
        .toList();
    await prefs.setString(_exercisesKey, json.encode(exercisesMap));
  }

  Future<int> loadIntervalTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_intervalTimeKey) ?? 60; // Default to 60 seconds
  }

  Future<void> saveIntervalTime(int intervalTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_intervalTimeKey, intervalTime);
  }
}
