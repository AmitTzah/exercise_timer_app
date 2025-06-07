import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:exercise_timer_app/models/user_workout.dart';
import 'package:exercise_timer_app/services/audio_service.dart';
import 'package:exercise_timer_app/models/workout_summary.dart';
import 'package:exercise_timer_app/models/workout_set.dart'; // Keep for WorkoutSummary
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:exercise_timer_app/services/workout_logic_service.dart'; // New: Import WorkoutLogicService
import 'package:exercise_timer_app/models/workout_completion_details.dart';

class WorkoutController extends ChangeNotifier {
  final UserWorkout _workout; // Keep original workout for summary and interval time
  final AudioService _audioService;
  DateTime? _workoutStartTime;
  bool _workoutCompletedAudioPlayed = false; // Re-add this field
  bool _isWorkoutFinished = false; // New: Flag to indicate if workout is finished
  int _currentRawTimeMs = 0; // New: To store the latest raw time from the timer

  final StopWatchTimer _stopWatchTimer = StopWatchTimer(
    mode: StopWatchMode.countUp,
  );
  StreamSubscription<int>? _rawTimeSubscription;

  final WorkoutLogicService _workoutLogicService;

  UserWorkout get workout => _workout;
  int get totalSetsCompleted => _workoutLogicService.totalSetsCompleted;
  bool get isPaused => !_stopWatchTimer.isRunning;
  List<WorkoutSet> get exercisesToPerform => _workoutLogicService.exercisesToPerform;
  int get currentOverallSetIndex => _workoutLogicService.currentOverallSetIndex;
  // Use the new getter from WorkoutLogicService for total expected duration
  double get totalExpectedWorkoutDuration => _workoutLogicService.totalWorkoutDurationWithRests.toDouble();

  Stream<int> get currentIntervalTimeRemainingStream => _stopWatchTimer.rawTime.map(_calculateCurrentIntervalTimeRemaining);

  int _calculateCurrentIntervalTimeRemaining(int rawTimeValue) {
    if (_isWorkoutFinished) return 0;

    final WorkoutSet? currentWs = _workoutLogicService.currentWorkoutSet;
    if (currentWs == null) return 0;

    final int currentSetDurationSec = currentWs.isRestSet
        ? (_workout.restDurationInSeconds ?? 0)
        : _workout.intervalTimeBetweenSets;

    int cumulativeDurationOfCompletedSetsSec = 0;
    for (int i = 0; i < _workoutLogicService.totalSetsCompleted; i++) {
      if (i < _workoutLogicService.exercisesToPerform.length) {
        final set = _workoutLogicService.exercisesToPerform[i];
        if (set.isRestSet) {
          cumulativeDurationOfCompletedSetsSec += (_workout.restDurationInSeconds ?? 0);
        } else {
          cumulativeDurationOfCompletedSetsSec += _workout.intervalTimeBetweenSets;
        }
      } else if (_workoutLogicService.isSurvivalMode) {
        final set = _workoutLogicService.exercisesToPerform[i % _workoutLogicService.exercisesToPerform.length];
        if (set.isRestSet) {
          cumulativeDurationOfCompletedSetsSec += (_workout.restDurationInSeconds ?? 0);
        } else {
          cumulativeDurationOfCompletedSetsSec += _workout.intervalTimeBetweenSets;
        }
      }
    }

    final int elapsedInCurrentIntervalMs = rawTimeValue - (cumulativeDurationOfCompletedSetsSec * 1000);
    final int remainingMs = (currentSetDurationSec * 1000) - elapsedInCurrentIntervalMs;
    return remainingMs > 0 ? remainingMs : 0;
  }

  Stream<int> get totalTimeRemainingStream => _stopWatchTimer.rawTime.map(_calculateTotalTimeRemaining);

  int _calculateTotalTimeRemaining(int rawTimeValue) {
    if (_workoutLogicService.isSurvivalMode) return 0;
    if (_isWorkoutFinished) return 0;
    final int remainingMs = (totalExpectedWorkoutDuration * 1000).round() - rawTimeValue;
    return remainingMs > 0 ? remainingMs : 0;
  }

  Stream<int> get totalWorkoutDurationStream => _stopWatchTimer.rawTime;
  DateTime? get workoutStartTime => _workoutStartTime;
  Stream<int> get elapsedSurvivalTimeStream => _stopWatchTimer.rawTime;

  WorkoutSet? get currentWorkoutSet => _workoutLogicService.currentWorkoutSet;
  int get totalSets => _workoutLogicService.totalSetsInSequence;

  set onWorkoutFinished(Function(WorkoutSummary)? callback) {
    _onWorkoutFinished = callback;
  }

  Function(WorkoutSummary)? _onWorkoutFinished;

  void resumeWorkout() {
    _stopWatchTimer.onStartTimer(); // Updated: Use new start method
    notifyListeners();
  }

  void pauseWorkout() {
    _stopWatchTimer.onStopTimer(); // Updated: Use new stop method
    notifyListeners();
  }

  void finishWorkout() async {
    _isWorkoutFinished = true; // Set flag that workout is finished
    notifyListeners(); // Notify listeners immediately to update UI

    await _rawTimeSubscription?.cancel();
    _rawTimeSubscription = null;
    
    if (_stopWatchTimer.isRunning) {
        _stopWatchTimer.onStopTimer(); // Updated: Use new stop method
        debugPrint('Workout manually finished. StopWatchTimer stopped.');
    } else {
        debugPrint('Workout manually finished. StopWatchTimer was already stopped.');
    }
    _finishWorkoutInternal();
  }

  WorkoutController({
    required UserWorkout workout,
    required AudioService audioService,
    required bool isAlternateMode,
    required dynamic selectedLevelOrMode,
  })  : _workout = workout,
        _audioService = audioService,
        _workoutLogicService = WorkoutLogicService(
          baseWorkout: workout,
          isAlternateMode: isAlternateMode,
          selectedLevelOrMode: selectedLevelOrMode,
        ) {
    _workoutStartTime = DateTime.now();

    if (_workoutLogicService.exercisesToPerform.isNotEmpty) {
      debugPrint('StopWatchTimer started.');
      _stopWatchTimer.onStartTimer(); // Updated: Use new start method
      _startTimerListener();
      _initializeAndStartWorkoutAudio(); // Call async method for audio
    } else {
      _isWorkoutFinished = true; // Set flag if workout ends immediately
      _finishWorkoutInternal();
    }
  }

  Future<void> _initializeAndStartWorkoutAudio() async {
    await _audioService.playWorkoutStartedSound(); // Play sound when workout starts
    // Announce the first exercise after the workout started sound
    if (_workoutLogicService.exercisesToPerform.isNotEmpty) {
      final currentSet = _workoutLogicService.currentWorkoutSet!;
      if (currentSet.isRestSet) {
        await _audioService.playRestSound();
      } else {
        await _audioService.playJustExerciseSound(currentSet.exercise.name);
      }
    }
  }

  void _startTimerListener() {
    _rawTimeSubscription?.cancel(); 
    _rawTimeSubscription = _stopWatchTimer.rawTime.listen((value) async {
      _currentRawTimeMs = value;
      if (!_stopWatchTimer.isRunning) return;

      // Determine the duration of the current set (either interval or rest)
      final int currentSetDurationMs = (_workoutLogicService.currentWorkoutSet?.isRestSet == true
          ? (_workout.restDurationInSeconds ?? 0)
          : _workout.intervalTimeBetweenSets) * 1000;

      // Calculate elapsed time within the current set/interval
      int cumulativeDurationOfCompletedSets = 0;
      for (int i = 0; i < _workoutLogicService.totalSetsCompleted; i++) {
        final set = _workoutLogicService.exercisesToPerform[i];
        if (set.isRestSet) {
          cumulativeDurationOfCompletedSets += (_workout.restDurationInSeconds ?? 0);
        } else {
          cumulativeDurationOfCompletedSets += _workout.intervalTimeBetweenSets;
        }
      }
      final int elapsedInCurrentIntervalMs = value - (cumulativeDurationOfCompletedSets * 1000);

      if (elapsedInCurrentIntervalMs >= currentSetDurationMs) {
        bool workoutContinues = _workoutLogicService.moveToNextSet();
        if (workoutContinues) {
          notifyListeners();
          // Play appropriate audio for the next set
          final nextSet = _workoutLogicService.currentWorkoutSet!;
          if (nextSet.isRestSet) {
            await _audioService.playRestSound();
          } else {
            await _audioService.playExerciseAnnouncement(nextSet.exercise.name);
          }
        } else { // Workout has ended
          _isWorkoutFinished = true;
          notifyListeners();

          // Play workout complete sound if not in survival mode and not already played
          if (!_workoutLogicService.isSurvivalMode && !_workoutCompletedAudioPlayed) {
            _workoutCompletedAudioPlayed = true; // Set flag
            await _audioService.playSessionComplete();
            debugPrint('Played workout_complete.wav');
          }

          await _rawTimeSubscription?.cancel();
          _rawTimeSubscription = null;
          
          if (_stopWatchTimer.isRunning) {
              _stopWatchTimer.onStopTimer(); // Updated: Use new stop method
              debugPrint('Workout finished naturally. StopWatchTimer stopped.');
          } else {
              debugPrint('Workout finished naturally. StopWatchTimer was already stopped.');
          }
          _finishWorkoutInternal();
        }
      }
      if (_rawTimeSubscription != null && !_isWorkoutFinished) { // Only notify if not already finished
          notifyListeners(); 
      }
    });
  }


  void _finishWorkoutInternal() {
    _workoutStartTime ??= DateTime.now();

    final WorkoutCompletionDetails details = _determineWorkoutCompletionDetails();

    debugPrint('Creating WorkoutSummary. totalWorkoutDuration: ${_currentRawTimeMs / 1000.0} seconds');
    final summary = _createWorkoutSummary(details);
    _onWorkoutFinished?.call(summary);
  }

  WorkoutCompletionDetails _determineWorkoutCompletionDetails() {
    final bool wasStoppedPrematurely;
    List<WorkoutSet> finalPerformedSets;

    if (_workoutLogicService.isSurvivalMode) {
      wasStoppedPrematurely = false;
      finalPerformedSets = [];
      if (_workoutLogicService.exercisesToPerform.isNotEmpty) {
        int fullCycles = _workoutLogicService.totalSetsCompleted ~/ _workoutLogicService.exercisesToPerform.length;
        int remainingSets = _workoutLogicService.totalSetsCompleted % _workoutLogicService.exercisesToPerform.length;

        for (int i = 0; i < fullCycles; i++) {
          finalPerformedSets.addAll(_workoutLogicService.exercisesToPerform);
        }
        if (remainingSets > 0) {
          finalPerformedSets.addAll(_workoutLogicService.exercisesToPerform.sublist(0, remainingSets));
        }
      }
    } else {
      wasStoppedPrematurely = (_workoutLogicService.totalSetsCompleted < _workoutLogicService.exercisesToPerform.length);
      finalPerformedSets = _workoutLogicService.exercisesToPerform.sublist(0, wasStoppedPrematurely ? _workoutLogicService.totalSetsCompleted : _workoutLogicService.exercisesToPerform.length);
    }
    return WorkoutCompletionDetails(wasStoppedPrematurely, finalPerformedSets);
  }

  WorkoutSummary _createWorkoutSummary(WorkoutCompletionDetails details) {
    return WorkoutSummary(
      date: _workoutStartTime!,
      performedSets: details.finalPerformedSets,
      totalDurationInSeconds: (_currentRawTimeMs / 1000.0).round(),
      workoutName: _workout.name,
      workoutLevel: _workoutLogicService.isSurvivalMode ? 1 : (_workoutLogicService.selectedLevelOrMode is int ? _workoutLogicService.selectedLevelOrMode : 1),
      isSurvivalMode: _workoutLogicService.isSurvivalMode,
      isAlternatingSets: _workoutLogicService.isAlternateMode,
      intervalTime: _workout.intervalTimeBetweenSets,
      wasStoppedPrematurely: details.wasStoppedPrematurely,
      totalSets: details.finalPerformedSets.length,
    );
  }
}
