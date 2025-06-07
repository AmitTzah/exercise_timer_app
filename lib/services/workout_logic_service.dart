import 'package:exercise_timer_app/models/user_workout.dart';
import 'package:exercise_timer_app/models/exercise.dart'; // Still needed for Exercise object within WorkoutSet
import 'package:exercise_timer_app/models/workout_set.dart';
import 'package:exercise_timer_app/models/workout_item.dart'; // New: Import WorkoutItem

/// Manages the core logic of workout structure and progression.
/// This service is independent of UI or specific timer implementations.
class WorkoutLogicService {
  final UserWorkout _baseWorkout;
  final bool _isAlternateMode;
  final dynamic _selectedLevelOrMode; // int for level, String for "survival"

  late List<WorkoutSet> _exercisesToPerform;
  int _currentOverallSetIndex = 0;
  int _totalSetsCompleted = 0;

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

  /// Calculates the total expected duration of the workout including rest periods.
  int get totalWorkoutDurationWithRests {
    int totalDuration = 0;
    for (final set in _exercisesToPerform) {
      if (set.isRestSet) {
        totalDuration += set.restBlockDuration ?? (set.exercise.restTimeInSeconds ?? 0);
      } else {
        totalDuration += set.exercise.workTimeInSeconds;
      }
    }
    return totalDuration;
  }

  /// Initializes the workout sequence based on level/mode and alternation.
  void _initializeWorkoutSequence() {
    List<WorkoutSet> sequence = [];
    List<ExerciseItem> originalExerciseItems = [];

    // Extract all ExerciseItems from the base workout for level modification
    for (var item in _baseWorkout.items) {
      if (item is ExerciseItem) {
        originalExerciseItems.add(item);
      }
    }

    List<Exercise> adjustedExercises = _applyLevelModifier(originalExerciseItems);

    if (_isAlternateMode) {
      // Create a map for quick lookup of adjusted exercises by their original name
      Map<String, Exercise> adjustedExerciseMap = {
        for (var ae in adjustedExercises) ae.name: ae
      };

      // Track the current set number for each exercise
      Map<String, int> currentSetNumbers = {
        for (var ae in adjustedExercises) ae.name: 1
      };

      bool moreSetsExist = true;
      while (moreSetsExist) {
        moreSetsExist = false; // Assume no more sets until we find one

        for (var item in _baseWorkout.items) {
          if (item is ExerciseItem) {
            final originalExerciseName = item.exercise.name;
            final adjustedExercise = adjustedExerciseMap[originalExerciseName];

            if (adjustedExercise != null) {
              int currentSet = currentSetNumbers[originalExerciseName]!;
              if (currentSet <= adjustedExercise.sets) {
                // Add the work set
                sequence.add(WorkoutSet(
                  exercise: adjustedExercise,
                  setNumber: currentSet,
                  isRestSet: false,
                  isRestBlock: false,
                ));
                // Add per-set rest if defined and not the last set of THIS exercise
                if (adjustedExercise.restTimeInSeconds != null && adjustedExercise.restTimeInSeconds! > 0 && currentSet < adjustedExercise.sets) {
                  sequence.add(WorkoutSet(
                    exercise: adjustedExercise,
                    setNumber: currentSet,
                    isRestSet: true,
                    isRestBlock: false,
                    restBlockDuration: adjustedExercise.restTimeInSeconds,
                  ));
                }
                currentSetNumbers[originalExerciseName] = currentSet + 1; // Increment set number for this exercise
                moreSetsExist = true; // More sets were added in this round
              }
            }
          } else if (item is RestBlockItem) {
            // Insert rest blocks directly at their position in the original sequence
            // This ensures they are not duplicated per alternating "round"
            sequence.add(WorkoutSet(
              exercise: Exercise(name: 'Rest Block', sets: 1, workTimeInSeconds: item.durationInSeconds), // Dummy exercise
              setNumber: 1, // Rest blocks don't have sets in the same way
              isRestSet: true,
              isRestBlock: true,
              restBlockDuration: item.durationInSeconds,
            ));
          }
        }
      }
    } else {
      // Sequential Mode (existing logic, slightly adapted for WorkoutItem)
      int adjustedExerciseIndex = 0;
      for (var item in _baseWorkout.items) {
        if (item is ExerciseItem) {
          if (adjustedExerciseIndex < adjustedExercises.length) {
            final adjustedExercise = adjustedExercises[adjustedExerciseIndex];
            for (int s = 1; s <= adjustedExercise.sets; s++) {
              sequence.add(WorkoutSet(
                exercise: adjustedExercise,
                setNumber: s,
                isRestSet: false,
                isRestBlock: false,
              ));
              // Add per-set rest if defined and not the last set
              if (adjustedExercise.restTimeInSeconds != null && adjustedExercise.restTimeInSeconds! > 0 && s < adjustedExercise.sets) {
                sequence.add(WorkoutSet(
                  exercise: adjustedExercise,
                  setNumber: s,
                  isRestSet: true,
                  isRestBlock: false,
                  restBlockDuration: adjustedExercise.restTimeInSeconds,
                ));
              }
            }
            adjustedExerciseIndex++;
          }
        } else if (item is RestBlockItem) {
          sequence.add(WorkoutSet(
            exercise: Exercise(name: 'Rest Block', sets: 1, workTimeInSeconds: item.durationInSeconds),
            setNumber: 1,
            isRestSet: true,
            isRestBlock: true,
            restBlockDuration: item.durationInSeconds,
          ));
        }
      }
    }

    _exercisesToPerform = sequence;
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
  List<Exercise> _applyLevelModifier(List<ExerciseItem> originalExerciseItems) {
    List<Exercise> adjustedExercises = [];
    if (_selectedLevelOrMode is int && _selectedLevelOrMode >= 1 && _selectedLevelOrMode <= 10) {
      final int level = _selectedLevelOrMode;
      int originalTotalSets = originalExerciseItems.fold(0, (sum, item) => sum + item.exercise.sets);
      if (originalTotalSets == 0) {
        return originalExerciseItems.map((e) => e.exercise).toList();
      }

      int targetTotalSets = _calculateTotalSetsForLevelStatic(level, originalTotalSets);

      int currentSumOfAdjustedSets = 0;
      List<Exercise> tempAdjustedExercises = [];

      for (var item in originalExerciseItems) {
        final exercise = item.exercise;
        double proportion = exercise.sets / originalTotalSets;
        int adjustedSets = (proportion * targetTotalSets).round();

        if (exercise.sets > 0 && adjustedSets == 0) {
          adjustedSets = 1;
        }
        tempAdjustedExercises.add(Exercise(
          name: exercise.name,
          sets: adjustedSets,
          reps: exercise.reps,
          workTimeInSeconds: exercise.workTimeInSeconds,
          restTimeInSeconds: exercise.restTimeInSeconds,
          audioFileName: exercise.audioFileName,
        ));
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
          workTimeInSeconds: exerciseToAdjust.workTimeInSeconds,
          restTimeInSeconds: exerciseToAdjust.restTimeInSeconds,
          audioFileName: exerciseToAdjust.audioFileName,
        );
      }
      adjustedExercises = tempAdjustedExercises;
    } else {
      adjustedExercises = originalExerciseItems.map((e) => e.exercise).toList();
    }
    return adjustedExercises;
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
