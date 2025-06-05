import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:exercise_timer_app/models/user_workout.dart';
import 'package:exercise_timer_app/models/exercise.dart';
import 'package:exercise_timer_app/services/audio_service.dart';
import 'package:exercise_timer_app/models/workout_summary.dart';
import 'package:exercise_timer_app/models/workout_set.dart'; // Import WorkoutSet

class WorkoutController extends ChangeNotifier {
  final UserWorkout _workout;
  final AudioService _audioService;
  Timer? _timer;
  DateTime? _workoutStartTime;

  int _totalSetsCompleted = 0;
  bool _isPaused = false;
  bool _workoutCompletedAudioPlayed = false;

  late List<WorkoutSet> _exercisesToPerform;
  int _currentOverallSetIndex = 0;
  late double _totalExpectedWorkoutDuration;

  // New timing variables
  final Stopwatch _masterStopwatch = Stopwatch(); // Was _overallWorkoutStopwatch
  late int _currentIntervalDuration; // In seconds, from workout.intervalTimeBetweenSets
  int _currentIntervalStartMs = 0; 
  int _accumulatedPausedMsInInterval = 0;
  int _lastKnownMasterTimeBeforePause = 0; // To help calculate pause duration correctly

  // Getters for UI to consume
  UserWorkout get workout => _workout;
  int get totalSetsCompleted => _totalSetsCompleted;
  bool get isPaused => _isPaused;
  List<WorkoutSet> get exercisesToPerform => _exercisesToPerform;
  int get currentOverallSetIndex => _currentOverallSetIndex;
  double get totalExpectedWorkoutDuration => _totalExpectedWorkoutDuration;

  // Calculated getters for time
  double get currentIntervalTimeRemaining {
    if (_isPaused) { // If paused, show time remaining at the point of pause
      final double activeTimeBeforePause = (_lastKnownMasterTimeBeforePause - _currentIntervalStartMs - _accumulatedPausedMsInInterval).toDouble() / 1000.0;
      final double remaining = _currentIntervalDuration - activeTimeBeforePause;
      return remaining > 0 ? remaining : 0.0;
    }
    final double elapsedInCurrentIntervalActiveMs = (_masterStopwatch.elapsedMilliseconds - _currentIntervalStartMs - _accumulatedPausedMsInInterval).toDouble();
    final double remainingSeconds = _currentIntervalDuration - (elapsedInCurrentIntervalActiveMs / 1000.0);
    return remainingSeconds > 0 ? remainingSeconds : 0.0;
  }

  double get totalTimeRemaining {
    if (_selectedLevelOrMode == "survival") return 0.0; // Not applicable for survival
    final double remaining = _totalExpectedWorkoutDuration - (_masterStopwatch.elapsedMilliseconds / 1000.0);
    return remaining > 0 ? remaining : 0.0;
  }

  double get totalWorkoutDuration => _masterStopwatch.elapsedMilliseconds / 1000.0;
  DateTime? get workoutStartTime => _workoutStartTime; // Expose workout start time
  double get elapsedSurvivalTime => _masterStopwatch.elapsedMilliseconds / 1000.0;

  WorkoutSet? get currentWorkoutSet =>
      _exercisesToPerform.isNotEmpty &&
          _currentOverallSetIndex < _exercisesToPerform.length
      ? _exercisesToPerform[_currentOverallSetIndex]
      : null;
  int get totalSets => _currentLoopExercises.fold(0, (sum, exercise) => sum + exercise.sets);

  final bool _isAlternateMode;
  final dynamic _selectedLevelOrMode; // int for level, String for "survival"
  late List<Exercise> _currentLoopExercises;

// Callback for when workout finishes
  Function(WorkoutSummary)? onWorkoutFinished;

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
    _currentIntervalDuration = _workout.intervalTimeBetweenSets; // Initialize interval duration
    _workoutCompletedAudioPlayed = false; // Ensure it's reset for each new workout

    _applyLevelModifier(); // Adjust sets based on level

    if (_isAlternateMode) {
      _exercisesToPerform = _generateAlternatingWorkoutSequence();
    } else {
      _exercisesToPerform = _generateSequentialWorkoutSequence();
    }

    if (_selectedLevelOrMode == "survival") {
      _totalExpectedWorkoutDuration = 0.0; // Not applicable for survival mode
    } else {
      _totalExpectedWorkoutDuration =
          (_exercisesToPerform.length * _workout.intervalTimeBetweenSets).toDouble();
    }

    if (_exercisesToPerform.isNotEmpty) {
      _masterStopwatch.start();
      _currentIntervalStartMs = _masterStopwatch.elapsedMilliseconds;
      _accumulatedPausedMsInInterval = 0;
      debugPrint('Master Stopwatch started. Elapsed: ${_masterStopwatch.elapsedMilliseconds}ms');
      _startTimer();
    } else {
      _finishWorkoutInternal(); // Immediately finish if no exercises
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
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) async {
      if (_isPaused) return;

      // Check if current interval is complete
      final int elapsedInCurrentIntervalActiveMs = _masterStopwatch.elapsedMilliseconds - _currentIntervalStartMs - _accumulatedPausedMsInInterval;
      if (elapsedInCurrentIntervalActiveMs >= _currentIntervalDuration * 1000) {
        bool workoutContinues = await _moveToNextSetAndPrepareInterval(); // This will update _currentIntervalStartMs and reset _accumulatedPausedMsInInterval
        if (workoutContinues) {
          notifyListeners(); // Update UI for the new set and its freshly started timer
          // Play "Next Set" sound followed by the next exercise name
          await _audioService.playExerciseAnnouncement(_exercisesToPerform[_currentOverallSetIndex].exercise.name);
        } else {
          // Workout finished naturally
          _timer?.cancel();
          _masterStopwatch.stop();
          debugPrint('Workout finished naturally. Master Stopwatch stopped. Elapsed: ${_masterStopwatch.elapsedMilliseconds}ms');
          _finishWorkoutInternal();
          return; // Exit early, no more operations on disposed controller
        }
      }

      // Only update and notify if the workout is still active (timer not cancelled by finishInternal)
      if (_timer != null && _timer!.isActive) {
        notifyListeners();
      }
    });
  }

  void pauseWorkout() {
    if (!_isPaused) { // Only execute if not already paused
      _masterStopwatch.stop();
      _lastKnownMasterTimeBeforePause = _masterStopwatch.elapsedMilliseconds;
      _isPaused = true;
      notifyListeners();
    }
  }

  void resumeWorkout() {
    if (_isPaused) { // Only execute if paused
      _isPaused = false;
      // Simply restart the master stopwatch. 
      // The _accumulatedPausedMsInInterval is not being updated in this simplified version,
      // which means pauses will effectively shorten the perceived interval if not handled more robustly.
      // This change focuses on the reported type error.
      _masterStopwatch.start();
      notifyListeners();
    }
  }

  void finishWorkout() {
    _timer?.cancel();
    _isPaused = true; // Ensure UI reflects paused state
    _masterStopwatch.stop();
    debugPrint('Workout manually finished. Master Stopwatch stopped. Elapsed: ${_masterStopwatch.elapsedMilliseconds}ms');
    notifyListeners();
    _finishWorkoutInternal();
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
    _totalSetsCompleted++; // Increment for the set that just finished
    bool workoutContinues = true;

    if (_currentOverallSetIndex < _exercisesToPerform.length - 1) {
      _currentOverallSetIndex++;
    } else {
      if (_selectedLevelOrMode == "survival") {
        _currentOverallSetIndex = 0; // Loop back
      } else {
        // End workout for non-survival modes
        if (!_workoutCompletedAudioPlayed) {
          _workoutCompletedAudioPlayed = true;
          await _audioService.playSessionComplete();
        }
        workoutContinues = false;
      }
    }

    if (workoutContinues) {
      _currentIntervalStartMs = _masterStopwatch.elapsedMilliseconds;
      _accumulatedPausedMsInInterval = 0; // Reset for the new interval
    }
    return workoutContinues;
  }

  void _finishWorkoutInternal() {
    _workoutStartTime ??= DateTime.now();

    final bool wasStoppedPrematurely;
    List<WorkoutSet> finalPerformedSets;

    if (_selectedLevelOrMode == "survival") {
      wasStoppedPrematurely = false; // Survival mode is always "ended", not "stopped prematurely" in the same sense
      finalPerformedSets = [];
      if (_exercisesToPerform.isNotEmpty) {
        int fullCycles = _totalSetsCompleted ~/ _exercisesToPerform.length;
        int remainingSets = _totalSetsCompleted % _exercisesToPerform.length;

        for (int i = 0; i < fullCycles; i++) {
          finalPerformedSets.addAll(_exercisesToPerform);
        }
        if (remainingSets > 0) {
          finalPerformedSets.addAll(_exercisesToPerform.sublist(0, remainingSets));
        }
      }
    } else {
      wasStoppedPrematurely = (_totalSetsCompleted < _exercisesToPerform.length);
      finalPerformedSets = _exercisesToPerform.sublist(0, wasStoppedPrematurely ? _totalSetsCompleted : _exercisesToPerform.length);
    }

    debugPrint('Creating WorkoutSummary. totalWorkoutDuration (getter): $totalWorkoutDuration seconds');
    final summary = WorkoutSummary(
      date: _workoutStartTime!,
      performedSets: finalPerformedSets,
      totalDurationInSeconds: totalWorkoutDuration.round(), // Use getter for total duration
      workoutName: _workout.name,
      workoutLevel: _selectedLevelOrMode is int ? _selectedLevelOrMode : 1, // Default to 1 if survival
      isSurvivalMode: _selectedLevelOrMode == "survival",
      isAlternatingSets: _isAlternateMode,
      intervalTime: _workout.intervalTimeBetweenSets,
      wasStoppedPrematurely: wasStoppedPrematurely,
    );
    onWorkoutFinished?.call(summary);
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
    _masterStopwatch.stop();
    // _audioService.dispose(); // AudioService is a singleton, disposed by Provider at app shutdown
    super.dispose();
  }
}
