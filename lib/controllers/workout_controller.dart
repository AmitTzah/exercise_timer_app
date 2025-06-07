import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:exercise_timer_app/models/user_workout.dart';
import 'package:exercise_timer_app/services/audio_service.dart';
import 'package:exercise_timer_app/models/workout_summary.dart';
import 'package:exercise_timer_app/models/workout_set.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:exercise_timer_app/services/workout_logic_service.dart';
import 'package:exercise_timer_app/models/workout_completion_details.dart';
import 'package:exercise_timer_app/models/workout_item.dart'; // Import new workout_item

class WorkoutController extends ChangeNotifier {
  final UserWorkout _workout;
  final AudioService _audioService;
  DateTime? _workoutStartTime;
  bool _workoutCompletedAudioPlayed = false;
  bool _isWorkoutFinished = false;
  int _currentRawTimeMs = 0;

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
  double get totalExpectedWorkoutDuration => _workoutLogicService.totalWorkoutDurationWithRests.toDouble();

  Stream<int> get currentIntervalTimeRemainingStream => _stopWatchTimer.rawTime.map(_calculateCurrentIntervalTimeRemaining);

  int _calculateCurrentIntervalTimeRemaining(int rawTimeValue) {
    if (_isWorkoutFinished) return 0;

    final WorkoutSet? currentWs = _workoutLogicService.currentWorkoutSet;
    if (currentWs == null) return 0;

    int currentSetDurationSec = 0;
    if (currentWs.isRestSet) {
      if (currentWs.isRestBlock) {
        currentSetDurationSec = currentWs.restBlockDuration!;
      } else {
        currentSetDurationSec = currentWs.exercise.restTimeInSeconds ?? 0;
      }
    } else {
      currentSetDurationSec = currentWs.exercise.workTimeInSeconds;
    }

    int cumulativeDurationOfCompletedSetsSec = 0;
    for (int i = 0; i < _workoutLogicService.totalSetsCompleted; i++) {
      if (i < _workoutLogicService.exercisesToPerform.length) {
        final set = _workoutLogicService.exercisesToPerform[i];
        if (set.isRestSet) {
          if (set.isRestBlock) {
            cumulativeDurationOfCompletedSetsSec += set.restBlockDuration!;
          } else {
            cumulativeDurationOfCompletedSetsSec += (set.exercise.restTimeInSeconds ?? 0);
          }
        } else {
          cumulativeDurationOfCompletedSetsSec += set.exercise.workTimeInSeconds;
        }
      } else if (_workoutLogicService.isSurvivalMode) {
        final set = _workoutLogicService.exercisesToPerform[i % _workoutLogicService.exercisesToPerform.length];
        if (set.isRestSet) {
          if (set.isRestBlock) {
            cumulativeDurationOfCompletedSetsSec += set.restBlockDuration!;
          } else {
            cumulativeDurationOfCompletedSetsSec += (set.exercise.restTimeInSeconds ?? 0);
          }
        } else {
          cumulativeDurationOfCompletedSetsSec += set.exercise.workTimeInSeconds;
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
    _stopWatchTimer.onStartTimer();
    notifyListeners();
  }

  void pauseWorkout() {
    _stopWatchTimer.onStopTimer();
    notifyListeners();
  }

  void finishWorkout() async {
    _isWorkoutFinished = true;
    notifyListeners();

    await _rawTimeSubscription?.cancel();
    _rawTimeSubscription = null;
    
    if (_stopWatchTimer.isRunning) {
        _stopWatchTimer.onStopTimer();
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
      _stopWatchTimer.onStartTimer();
      _startTimerListener();
      _initializeAndStartWorkoutAudio();
    } else {
      _isWorkoutFinished = true;
      _finishWorkoutInternal();
    }
  }

  Future<void> _initializeAndStartWorkoutAudio() async {
    await _audioService.playWorkoutStartedSound();
    if (_workoutLogicService.exercisesToPerform.isNotEmpty) {
      final currentSet = _workoutLogicService.currentWorkoutSet!;
      if (currentSet.isRestSet) {
        if (currentSet.isRestBlock) {
          await _audioService.playRestSound();
        } else {
          await _audioService.playRestSound(); // Play rest sound for per-exercise rest
        }
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

      int currentSetDurationMs = 0;
      if (_workoutLogicService.currentWorkoutSet?.isRestSet == true) {
        if (_workoutLogicService.currentWorkoutSet!.isRestBlock) {
          currentSetDurationMs = _workoutLogicService.currentWorkoutSet!.restBlockDuration! * 1000;
        } else {
          currentSetDurationMs = (_workoutLogicService.currentWorkoutSet!.exercise.restTimeInSeconds ?? 0) * 1000;
        }
      } else {
        currentSetDurationMs = _workoutLogicService.currentWorkoutSet!.exercise.workTimeInSeconds * 1000;
      }

      int cumulativeDurationOfCompletedSets = 0;
      for (int i = 0; i < _workoutLogicService.totalSetsCompleted; i++) {
        final set = _workoutLogicService.exercisesToPerform[i];
        if (set.isRestSet) {
          if (set.isRestBlock) {
            cumulativeDurationOfCompletedSets += set.restBlockDuration!;
          } else {
            cumulativeDurationOfCompletedSets += (set.exercise.restTimeInSeconds ?? 0);
          }
        } else {
          cumulativeDurationOfCompletedSets += set.exercise.workTimeInSeconds;
        }
      }
      final int elapsedInCurrentIntervalMs = value - (cumulativeDurationOfCompletedSets * 1000);

      if (elapsedInCurrentIntervalMs >= currentSetDurationMs) {
        bool workoutContinues = _workoutLogicService.moveToNextSet();
        if (workoutContinues) {
          notifyListeners();
          final nextSet = _workoutLogicService.currentWorkoutSet!;
          if (nextSet.isRestSet) {
            if (nextSet.isRestBlock) {
              await _audioService.playRestSound();
            } else {
              await _audioService.playRestSound();
            }
          } else {
            await _audioService.playExerciseAnnouncement(nextSet.exercise.name);
          }
        } else {
          _isWorkoutFinished = true;
          notifyListeners();

          if (!_workoutLogicService.isSurvivalMode && !_workoutCompletedAudioPlayed) {
            _workoutCompletedAudioPlayed = true;
            await _audioService.playSessionComplete();
            debugPrint('Played workout_complete.wav');
          }

          await _rawTimeSubscription?.cancel();
          _rawTimeSubscription = null;
          
          if (_stopWatchTimer.isRunning) {
              _stopWatchTimer.onStopTimer();
              debugPrint('Workout finished naturally. StopWatchTimer stopped.');
          } else {
              debugPrint('Workout finished naturally. StopWatchTimer was already stopped.');
          }
          _finishWorkoutInternal();
        }
      }
      if (_rawTimeSubscription != null && !_isWorkoutFinished) {
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
      // intervalTime: _workout.intervalTimeBetweenSets, // Removed as it's no longer global
      wasStoppedPrematurely: details.wasStoppedPrematurely,
      totalSets: details.finalPerformedSets.length,
    );
  }
}
