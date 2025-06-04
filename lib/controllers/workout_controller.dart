import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:exercise_timer_app/models/user_workout.dart';
import 'package:exercise_timer_app/models/exercise.dart';
import 'package:exercise_timer_app/services/audio_service.dart';

// Helper class for alternating sets
class WorkoutSet {
  final Exercise exercise;
  final int setNumber;

  WorkoutSet({required this.exercise, required this.setNumber});
}

class WorkoutController extends ChangeNotifier {
  final UserWorkout _workout;
  final AudioService _audioService;
  Timer? _timer;
  DateTime? _workoutStartTime;

  int _currentIntervalTimeRemaining = 0;
  int _totalSetsCompleted = 0;
  int _totalWorkoutDuration = 0; // in seconds
  bool _isPaused = false;

  late List<WorkoutSet> _exercisesToPerform;
  int _currentOverallSetIndex = 0;
  late int _totalExpectedWorkoutDuration;
  late int _totalTimeRemaining;

  // Getters for UI to consume
  UserWorkout get workout => _workout;
  int get currentIntervalTimeRemaining => _currentIntervalTimeRemaining;
  int get totalSetsCompleted => _totalSetsCompleted;
  int get totalWorkoutDuration => _totalWorkoutDuration;
  bool get isPaused => _isPaused;
  List<WorkoutSet> get exercisesToPerform => _exercisesToPerform;
  int get currentOverallSetIndex => _currentOverallSetIndex;
  int get totalExpectedWorkoutDuration => _totalExpectedWorkoutDuration;
  int get totalTimeRemaining => _totalTimeRemaining;
  WorkoutSet? get currentWorkoutSet => _exercisesToPerform.isNotEmpty && _currentOverallSetIndex < _exercisesToPerform.length
      ? _exercisesToPerform[_currentOverallSetIndex]
      : null;
  int get totalSets => _workout.exercises.fold(0, (sum, exercise) => sum + exercise.sets);
  DateTime? get workoutStartTime => _workoutStartTime; // Expose workout start time

  // Callback for when workout finishes
  VoidCallback? onWorkoutFinished;

  WorkoutController({
    required UserWorkout workout,
    required AudioService audioService,
  })  : _workout = workout,
        _audioService = audioService {
    _workoutStartTime = DateTime.now();

    if (_workout.alternateSets) {
      _exercisesToPerform = _generateAlternatingWorkoutSequence();
    } else {
      _exercisesToPerform = _generateSequentialWorkoutSequence();
    }

    _totalExpectedWorkoutDuration = _exercisesToPerform.length * _workout.intervalTimeBetweenSets;
    _totalTimeRemaining = _totalExpectedWorkoutDuration;

    if (_exercisesToPerform.isNotEmpty) {
      _currentIntervalTimeRemaining = _workout.intervalTimeBetweenSets;
      _startTimer();
    } else {
      onWorkoutFinished?.call(); // Immediately finish if no exercises
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_isPaused) return;

      if (_currentIntervalTimeRemaining > 0) {
        _currentIntervalTimeRemaining--;
      } else {
        bool workoutContinues = await _moveToNextSetAndPrepareInterval();
        if (workoutContinues) {
          _currentIntervalTimeRemaining = _workout.intervalTimeBetweenSets;
          _audioService.playNextSet();
          _currentIntervalTimeRemaining--; // Decrement immediately for the first second of the new set
        } else {
          _timer?.cancel();
          onWorkoutFinished?.call();
          return;
        }
      }

      if (_totalTimeRemaining > 0) {
        _totalTimeRemaining--;
      }
      if (_totalTimeRemaining < 0) _totalTimeRemaining = 0;
      _totalWorkoutDuration++;

      notifyListeners();
    });
  }

  void pauseWorkout() {
    _isPaused = true;
    notifyListeners();
  }

  void resumeWorkout() {
    _isPaused = false;
    notifyListeners();
  }

  void finishWorkout() {
    _timer?.cancel();
    _isPaused = true; // Ensure UI reflects paused state
    _currentIntervalTimeRemaining = 0;
    _totalTimeRemaining = 0;
    notifyListeners();
    onWorkoutFinished?.call();
  }

  List<WorkoutSet> _generateAlternatingWorkoutSequence() {
    List<WorkoutSet> sequence = [];
    int maxSets = 0;
    for (var exercise in _workout.exercises) {
      if (exercise.sets > maxSets) {
        maxSets = exercise.sets;
      }
    }

    for (int s = 1; s <= maxSets; s++) {
      for (var exercise in _workout.exercises) {
        if (s <= exercise.sets) {
          sequence.add(WorkoutSet(exercise: exercise, setNumber: s));
        }
      }
    }
    return sequence;
  }

  List<WorkoutSet> _generateSequentialWorkoutSequence() {
    List<WorkoutSet> sequence = [];
    for (var exercise in _workout.exercises) {
      for (int s = 1; s <= exercise.sets; s++) {
        sequence.add(WorkoutSet(exercise: exercise, setNumber: s));
      }
    }
    return sequence;
  }

  Future<bool> _moveToNextSetAndPrepareInterval() async {
    _totalSetsCompleted++;

    if (_currentOverallSetIndex < _exercisesToPerform.length - 1) {
      _currentOverallSetIndex++;
      notifyListeners(); // Notify to update current exercise display
      return true;
    } else {
      _timer?.cancel();
      _currentIntervalTimeRemaining = 0;
      _totalTimeRemaining = 0;
      await _audioService.playSessionComplete();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    // _audioService.dispose(); // AudioService is a singleton, disposed by Provider at app shutdown
    super.dispose();
  }
}
