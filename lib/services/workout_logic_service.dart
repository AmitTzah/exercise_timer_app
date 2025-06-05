import 'package:exercise_timer_app/models/user_workout.dart';
import 'package:exercise_timer_app/models/exercise.dart';
import 'package:exercise_timer_app/models/workout_set.dart';

/// Manages the core logic of workout structure and progression.
/// This service is independent of UI or specific timer implementations.
class WorkoutLogicService {
  final UserWorkout _baseWorkout;
  final bool _isAlternateMode;
  final dynamic _selectedLevelOrMode; // int for level, String for "survival"

  late List<WorkoutSet> _exercisesToPerform;
  int _currentOverallSetIndex = 0;
  int _totalSetsCompleted = 0;
  late List<Exercise> _currentLoopExercises; // Exercises after level modification

  // Public getters for previously private members
  dynamic get selectedLevelOrMode => _selectedLevelOrMode;
  bool get isAlternateMode => _isAlternateMode;

  WorkoutLogicService({
    required UserWorkout baseWorkout,
    required bool isAlternateMode,
    required dynamic selectedLevelOrMode,
  })  : _baseWorkout = baseWorkout,
        _isAlternateMode = isAlternateMode,
        _selectedLevelOrMode = selectedLevelOrMode {
    _initializeWorkoutSequence();
  }

  // Public Getters
  List<WorkoutSet> get exercisesToPerform => _exercisesToPerform;
  int get currentOverallSetIndex => _currentOverallSetIndex;
  int get totalSetsCompleted => _totalSetsCompleted;
  bool get isSurvivalMode => _selectedLevelOrMode == "survival";

  WorkoutSet? get currentWorkoutSet =>
      _exercisesToPerform.isNotEmpty &&
              _currentOverallSetIndex < _exercisesToPerform.length
          ? _exercisesToPerform[_currentOverallSetIndex]
          : null;

  int get totalSetsInSequence => _exercisesToPerform.length;

  /// Initializes the workout sequence based on level/mode and alternation.
  void _initializeWorkoutSequence() {
    _applyLevelModifier(); // Adjust sets based on level

    if (_isAlternateMode) {
      _exercisesToPerform = _generateAlternatingWorkoutSequence();
    } else {
      _exercisesToPerform = _generateSequentialWorkoutSequence();
    }
  }

  /// Advances to the next set in the workout sequence.
  /// Returns true if the workout continues, false if it has naturally completed.
  bool moveToNextSet() {
    _totalSetsCompleted++; // Increment for the set that just finished
    bool workoutContinues = true;

    if (_currentOverallSetIndex < _exercisesToPerform.length - 1) {
      _currentOverallSetIndex++;
    } else {
      if (isSurvivalMode) {
        _currentOverallSetIndex = 0; // Loop back for survival mode
      } else {
        workoutContinues = false; // End workout for non-survival modes
      }
    }
    return workoutContinues;
  }

  /// Applies level modifiers to the workout exercises.
  void _applyLevelModifier() {
    _currentLoopExercises = [];
    if (_selectedLevelOrMode is int && _selectedLevelOrMode >= 1 && _selectedLevelOrMode <= 10) {
      final int level = _selectedLevelOrMode;
      int originalTotalSets = _baseWorkout.exercises.fold(0, (sum, exercise) => sum + exercise.sets);
      if (originalTotalSets == 0) {
        _currentLoopExercises = List.from(_baseWorkout.exercises);
        return;
      }

      int targetTotalSets = _calculateTotalSetsForLevelStatic(level, originalTotalSets);

      int currentSumOfAdjustedSets = 0;
      List<Exercise> tempAdjustedExercises = [];

      for (var exercise in _baseWorkout.exercises) {
        double proportion = exercise.sets / originalTotalSets;
        int adjustedSets = (proportion * targetTotalSets).round();

        if (exercise.sets > 0 && adjustedSets == 0) {
          adjustedSets = 1;
        }
        tempAdjustedExercises.add(Exercise(name: exercise.name, sets: adjustedSets, reps: exercise.reps));
        currentSumOfAdjustedSets += adjustedSets;
      }

      int difference = targetTotalSets - currentSumOfAdjustedSets;
      if (difference != 0 && tempAdjustedExercises.isNotEmpty) {
        int largestSetIndex = 0;
        for (int i = 1; i < tempAdjustedExercises.length; i++) {
          if (tempAdjustedExercises[i].sets > tempAdjustedExercises[largestSetIndex].sets) {
            largestSetIndex = i;
          }
        }

        Exercise exerciseToAdjust = tempAdjustedExercises[largestSetIndex];
        tempAdjustedExercises[largestSetIndex] = Exercise(
          name: exerciseToAdjust.name,
          sets: (exerciseToAdjust.sets + difference).clamp(1, double.infinity).toInt(),
          reps: exerciseToAdjust.reps,
        );
      }
      _currentLoopExercises = tempAdjustedExercises;
    } else {
      _currentLoopExercises = List.from(_baseWorkout.exercises);
    }
  }

  /// Generates the workout sequence for alternating sets.
  List<WorkoutSet> _generateAlternatingWorkoutSequence() {
    List<WorkoutSet> sequence = [];
    int maxSets = 0;
    for (var exercise in _currentLoopExercises) {
      if (exercise.sets > maxSets) {
        maxSets = exercise.sets;
      }
    }

    for (int s = 1; s <= maxSets; s++) {
      for (var exercise in _currentLoopExercises) {
        if (s <= exercise.sets) {
          sequence.add(WorkoutSet(exercise: exercise, setNumber: s));
        }
      }
    }
    return sequence;
  }

  /// Generates the workout sequence for sequential sets.
  List<WorkoutSet> _generateSequentialWorkoutSequence() {
    List<WorkoutSet> sequence = [];
    for (var exercise in _currentLoopExercises) {
      for (int s = 1; s <= exercise.sets; s++) {
        sequence.add(WorkoutSet(exercise: exercise, setNumber: s));
      }
    }
    return sequence;
  }

  /// Helper to calculate total sets for a given level, ensuring strict increase.
  static int _calculateTotalSetsForLevelStatic(int level, int originalTotalSets) {
    if (originalTotalSets == 0) return 0;

    double multiplier;
    if (level == 1) {
      multiplier = 1.0;
    } else {
      multiplier = 1.0 + ((level - 1) * 20) / 100.0;
    }

    int calculatedSets = (originalTotalSets * multiplier).ceil();

    if (level > 1) {
      int previousLevelSets = _calculateTotalSetsForLevelStatic(level - 1, originalTotalSets);
      if (calculatedSets <= previousLevelSets) {
        calculatedSets = previousLevelSets + 1;
      }
    }
    return calculatedSets;
  }
}
