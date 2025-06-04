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
  WorkoutSet? get currentWorkoutSet =>
      _exercisesToPerform.isNotEmpty &&
          _currentOverallSetIndex < _exercisesToPerform.length
      ? _exercisesToPerform[_currentOverallSetIndex]
      : null;
  int get totalSets => _currentLoopExercises.fold(0, (sum, exercise) => sum + exercise.sets);
  DateTime? get workoutStartTime => _workoutStartTime; // Expose workout start time
  int get elapsedSurvivalTime => _elapsedSurvivalTime;

  final bool _isAlternateMode;
  final dynamic _selectedLevelOrMode; // int for level, String for "survival"
  int _elapsedSurvivalTime = 0;
  late List<Exercise> _currentLoopExercises;

  // Callback for when workout finishes
  VoidCallback? onWorkoutFinished;

  WorkoutController({
    required UserWorkout workout,
    required AudioService audioService,
    required bool isAlternateMode,
    required dynamic selectedLevelOrMode,
  }) : _workout = workout,
       _audioService = audioService,
       _isAlternateMode = isAlternateMode,
       _selectedLevelOrMode = selectedLevelOrMode {
    _workoutStartTime = DateTime.now();

    _applyLevelModifier(); // Adjust sets based on level

    if (_isAlternateMode) {
      _exercisesToPerform = _generateAlternatingWorkoutSequence();
    } else {
      _exercisesToPerform = _generateSequentialWorkoutSequence();
    }

    if (_selectedLevelOrMode == "survival") {
      _totalExpectedWorkoutDuration = 0; // Not applicable for survival mode
      _totalTimeRemaining = 0; // Not applicable for survival mode
    } else {
      _totalExpectedWorkoutDuration =
          _exercisesToPerform.length * _workout.intervalTimeBetweenSets;
      _totalTimeRemaining = _totalExpectedWorkoutDuration;
    }

    if (_exercisesToPerform.isNotEmpty) {
      _currentIntervalTimeRemaining = _workout.intervalTimeBetweenSets;
      _startTimer();
    } else {
      onWorkoutFinished?.call(); // Immediately finish if no exercises
    }
  }

  void _applyLevelModifier() {
    _currentLoopExercises = [];
    if (_selectedLevelOrMode is int && _selectedLevelOrMode >= 1 && _selectedLevelOrMode <= 10) { // Changed to 10 levels
      final int level = _selectedLevelOrMode;
      int originalTotalSets = _workout.exercises.fold(0, (sum, exercise) => sum + exercise.sets);
      if (originalTotalSets == 0) {
        _currentLoopExercises = List.from(_workout.exercises); // No exercises, no change
        return;
      }

      // Calculate the target total sets for this level, ensuring strict increase
      int targetTotalSets = _calculateTotalSetsForLevelStatic(level, originalTotalSets);

      // Distribute the targetTotalSets proportionally among exercises
      int currentSumOfAdjustedSets = 0;
      List<Exercise> tempAdjustedExercises = [];

      for (var exercise in _workout.exercises) {
        double proportion = exercise.sets / originalTotalSets;
        int adjustedSets = (proportion * targetTotalSets).round(); // Use round for distribution

        // Ensure at least 1 set if original was > 0 and adjusted became 0 due to rounding
        if (exercise.sets > 0 && adjustedSets == 0) {
          adjustedSets = 1;
        }
        tempAdjustedExercises.add(Exercise(name: exercise.name, sets: adjustedSets, reps: exercise.reps));
        currentSumOfAdjustedSets += adjustedSets;
      }

      // Adjust for any discrepancy due to rounding in distribution
      // Add/subtract remaining sets to the first exercise (or largest)
      int difference = targetTotalSets - currentSumOfAdjustedSets;
      if (difference != 0 && tempAdjustedExercises.isNotEmpty) {
        // Find the exercise with the largest number of sets to adjust
        int largestSetIndex = 0;
        for (int i = 1; i < tempAdjustedExercises.length; i++) {
          if (tempAdjustedExercises[i].sets > tempAdjustedExercises[largestSetIndex].sets) {
            largestSetIndex = i;
          }
        }

        Exercise exerciseToAdjust = tempAdjustedExercises[largestSetIndex];
        tempAdjustedExercises[largestSetIndex] = Exercise(
          name: exerciseToAdjust.name,
          sets: (exerciseToAdjust.sets + difference).clamp(1, double.infinity).toInt(), // Ensure sets >= 1
          reps: exerciseToAdjust.reps,
        );
      }
      _currentLoopExercises = tempAdjustedExercises;

    } else {
      // For survival mode or if level is not an int (e.g., "survival"), use original exercises
      _currentLoopExercises = List.from(_workout.exercises);
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
          // Play "Next Set" sound followed by the next exercise name
          await _audioService.playExerciseAnnouncement(_exercisesToPerform[_currentOverallSetIndex].exercise.name);
          _currentIntervalTimeRemaining--; // Decrement immediately for the first second of the new set
        } else {
          _timer?.cancel();
          onWorkoutFinished?.call();
          return;
        }
      }

      if (_selectedLevelOrMode == "survival") {
        _elapsedSurvivalTime++; // Count up for survival mode
      } else {
        if (_totalTimeRemaining > 0) {
          _totalTimeRemaining--;
        }
        if (_totalTimeRemaining < 0) _totalTimeRemaining = 0;
      }
      _totalWorkoutDuration++; // This still tracks total elapsed time for summary

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
    for (var exercise in _currentLoopExercises) { // Use adjusted exercises
      if (exercise.sets > maxSets) {
        maxSets = exercise.sets;
      }
    }

    for (int s = 1; s <= maxSets; s++) {
      for (var exercise in _currentLoopExercises) { // Use adjusted exercises
        if (s <= exercise.sets) {
          sequence.add(WorkoutSet(exercise: exercise, setNumber: s));
        }
      }
    }
    return sequence;
  }

  List<WorkoutSet> _generateSequentialWorkoutSequence() {
    List<WorkoutSet> sequence = [];
    for (var exercise in _currentLoopExercises) { // Use adjusted exercises
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
      if (_selectedLevelOrMode == "survival") {
        // Loop back to the beginning for survival mode
        _currentOverallSetIndex = 0;
        notifyListeners();
        return true;
      } else {
        // End workout for non-survival modes
        _timer?.cancel();
        _currentIntervalTimeRemaining = 0;
        _totalTimeRemaining = 0;
        await _audioService.playSessionComplete();
        notifyListeners();
        return false;
      }
    }
  }

  // Helper to calculate total sets for a given level, ensuring strict increase
  // This is a static method to avoid dependency on _workout instance
  static int _calculateTotalSetsForLevelStatic(int level, int originalTotalSets) {
    if (originalTotalSets == 0) return 0;

    double multiplier;
    if (level == 1) {
      multiplier = 1.0;
    } else {
      multiplier = 1.0 + ((level - 1) * 20) / 100.0; // Changed to 20% increment
    }

    int calculatedSets = (originalTotalSets * multiplier).ceil();

    // Ensure strict increase for total sets compared to previous level
    if (level > 1) {
      int previousLevelSets = _calculateTotalSetsForLevelStatic(level - 1, originalTotalSets);
      if (calculatedSets <= previousLevelSets) {
        calculatedSets = previousLevelSets + 1; // Force an increment
      }
    }
    return calculatedSets;
  }

  @override
  void dispose() {
    _timer?.cancel();
    // _audioService.dispose(); // AudioService is a singleton, disposed by Provider at app shutdown
    super.dispose();
  }
}
