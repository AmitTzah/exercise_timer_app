import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:exercise_timer_app/models/user_workout.dart';
import 'package:exercise_timer_app/models/exercise.dart';
import 'package:exercise_timer_app/services/audio_service.dart';
import 'package:exercise_timer_app/models/workout_summary.dart';
import 'package:exercise_timer_app/models/workout_set.dart'; // Import WorkoutSet
import 'package:stop_watch_timer/stop_watch_timer.dart'; // Import stop_watch_timer

class WorkoutController extends ChangeNotifier {
  final UserWorkout _workout;
  final AudioService _audioService;
  DateTime? _workoutStartTime;

  int _totalSetsCompleted = 0;
  bool _workoutCompletedAudioPlayed = false;

  late List<WorkoutSet> _exercisesToPerform;
  int _currentOverallSetIndex = 0;
  late double _totalExpectedWorkoutDuration;

  // StopWatchTimer instance
  final StopWatchTimer _stopWatchTimer = StopWatchTimer(
    mode: StopWatchMode.countUp,
  );
  StreamSubscription<int>? _rawTimeSubscription; // New: Subscription for rawTime stream

  // Getters for UI to consume
  UserWorkout get workout => _workout;
  int get totalSetsCompleted => _totalSetsCompleted;
  bool get isPaused => !_stopWatchTimer.isRunning; // Use stop_watch_timer's isRunning
  List<WorkoutSet> get exercisesToPerform => _exercisesToPerform;
  int get currentOverallSetIndex => _currentOverallSetIndex;
  double get totalExpectedWorkoutDuration => _totalExpectedWorkoutDuration;

  // Calculated getters for time using StopWatchTimer's rawTime stream
  Stream<int> get currentIntervalTimeRemainingStream => _stopWatchTimer.rawTime.map((value) {
    final int elapsedInCurrentIntervalMs = value - (_currentOverallSetIndex * _workout.intervalTimeBetweenSets * 1000);
    final int remainingMs = (_workout.intervalTimeBetweenSets * 1000) - elapsedInCurrentIntervalMs;
    return remainingMs > 0 ? remainingMs : 0;
  });

  Stream<int> get totalTimeRemainingStream => _stopWatchTimer.rawTime.map((value) {
    if (_selectedLevelOrMode == "survival") return 0; // Not applicable for survival
    final int remainingMs = (_totalExpectedWorkoutDuration * 1000).round() - value;
    return remainingMs > 0 ? remainingMs : 0;
  });

  Stream<int> get totalWorkoutDurationStream => _stopWatchTimer.rawTime;
  DateTime? get workoutStartTime => _workoutStartTime; // Expose workout start time
  Stream<int> get elapsedSurvivalTimeStream => _stopWatchTimer.rawTime;

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
      debugPrint('StopWatchTimer started.');
      _stopWatchTimer.onExecute.add(StopWatchExecute.start);
      _startTimerListener(); // Start listening to the timer
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

  void _startTimerListener() {
    // Cancel any existing subscription to be safe, though unlikely here
    _rawTimeSubscription?.cancel(); 
    _rawTimeSubscription = _stopWatchTimer.rawTime.listen((value) async {
      if (!_stopWatchTimer.isRunning) return; // Guard against late events after explicit stop

      final int elapsedInCurrentIntervalMs = value - (_currentOverallSetIndex * _workout.intervalTimeBetweenSets * 1000);

      if (elapsedInCurrentIntervalMs >= _workout.intervalTimeBetweenSets * 1000) {
        bool workoutContinues = await _moveToNextSetAndPrepareInterval();
        if (workoutContinues) {
          notifyListeners(); 
          await _audioService.playExerciseAnnouncement(_exercisesToPerform[_currentOverallSetIndex].exercise.name);
        } else {
          // Workout finished naturally
          await _rawTimeSubscription?.cancel(); // Cancel subscription first
          _rawTimeSubscription = null; // Clear the reference
          
          if (_stopWatchTimer.isRunning) { // Check if timer is still running before stopping
              _stopWatchTimer.onExecute.add(StopWatchExecute.stop);
              debugPrint('Workout finished naturally. StopWatchTimer stopped.');
          } else {
              debugPrint('Workout finished naturally. StopWatchTimer was already stopped.');
          }
          _finishWorkoutInternal();
        }
      }
      // Only notify if the subscription is still active, to prevent calls during disposal
      if (_rawTimeSubscription != null) {
          notifyListeners(); 
      }
    });
  }

  void pauseWorkout() {
    _stopWatchTimer.onExecute.add(StopWatchExecute.stop);
    notifyListeners();
  }

  void resumeWorkout() {
    _stopWatchTimer.onExecute.add(StopWatchExecute.start);
    notifyListeners();
  }

  void finishWorkout() async { // Make async to await cancellation
    await _rawTimeSubscription?.cancel();
    _rawTimeSubscription = null;
    
    if (_stopWatchTimer.isRunning) {
        _stopWatchTimer.onExecute.add(StopWatchExecute.stop);
        debugPrint('Workout manually finished. StopWatchTimer stopped.');
    } else {
        debugPrint('Workout manually finished. StopWatchTimer was already stopped.');
    }
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
        // Reset the timer to simulate continuous looping for survival mode
        _stopWatchTimer.onExecute.add(StopWatchExecute.reset);
        _stopWatchTimer.onExecute.add(StopWatchExecute.start);
      } else {
        // End workout for non-survival modes
        if (!_workoutCompletedAudioPlayed) {
          _workoutCompletedAudioPlayed = true;
          await _audioService.playSessionComplete();
        }
        workoutContinues = false;
      }
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

    debugPrint('Creating WorkoutSummary. totalWorkoutDuration: ${_stopWatchTimer.rawTime.value / 1000.0} seconds');
    final summary = WorkoutSummary(
      date: _workoutStartTime!,
      performedSets: finalPerformedSets,
      totalDurationInSeconds: (_stopWatchTimer.rawTime.value / 1000.0).round(), // Use rawTime.value
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
  void dispose() async {
    await _rawTimeSubscription?.cancel(); // Cancel subscription
    _rawTimeSubscription = null; // Clear the reference
    await _stopWatchTimer.dispose();
    super.dispose();
  }
}
