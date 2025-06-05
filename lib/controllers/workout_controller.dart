import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:exercise_timer_app/models/user_workout.dart';
import 'package:exercise_timer_app/services/audio_service.dart';
import 'package:exercise_timer_app/models/workout_summary.dart';
import 'package:exercise_timer_app/models/workout_set.dart'; // Keep for WorkoutSummary
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:exercise_timer_app/services/workout_logic_service.dart'; // New: Import WorkoutLogicService

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

  late WorkoutLogicService _workoutLogicService;

  UserWorkout get workout => _workout;
  int get totalSetsCompleted => _workoutLogicService.totalSetsCompleted;
  bool get isPaused => !_stopWatchTimer.isRunning;
  List<WorkoutSet> get exercisesToPerform => _workoutLogicService.exercisesToPerform;
  int get currentOverallSetIndex => _workoutLogicService.currentOverallSetIndex;
  double get totalExpectedWorkoutDuration => _workoutLogicService.totalSetsInSequence * _workout.intervalTimeBetweenSets.toDouble();

  Stream<int> get currentIntervalTimeRemainingStream => _stopWatchTimer.rawTime.map((value) {
    if (_isWorkoutFinished) return 0; // If workout is finished, remaining time is 0
    // In survival mode, currentOverallSetIndex resets to 0, causing incorrect elapsed time calculation for display.
    // totalSetsCompleted correctly tracks the cumulative number of sets finished.
    final int elapsedInCurrentIntervalMs = value - (_workoutLogicService.totalSetsCompleted * _workout.intervalTimeBetweenSets * 1000);
    final int remainingMs = (_workout.intervalTimeBetweenSets * 1000) - elapsedInCurrentIntervalMs;
    return remainingMs > 0 ? remainingMs : 0;
  });

  Stream<int> get totalTimeRemainingStream => _stopWatchTimer.rawTime.map((value) {
    if (_workoutLogicService.isSurvivalMode) return 0;
    if (_isWorkoutFinished) return 0; // If workout is finished, remaining time is 0
    final int remainingMs = (totalExpectedWorkoutDuration * 1000).round() - value;
    return remainingMs > 0 ? remainingMs : 0;
  });

  Stream<int> get totalWorkoutDurationStream => _stopWatchTimer.rawTime;
  DateTime? get workoutStartTime => _workoutStartTime;
  Stream<int> get elapsedSurvivalTimeStream => _stopWatchTimer.rawTime;

  WorkoutSet? get currentWorkoutSet => _workoutLogicService.currentWorkoutSet;
  int get totalSets => _workoutLogicService.totalSetsInSequence;

  Function(WorkoutSummary)? onWorkoutFinished;

  WorkoutController({
    required UserWorkout workout,
    required AudioService audioService,
    required bool isAlternateMode,
    required dynamic selectedLevelOrMode,
  }) : _workout = workout,
       _audioService = audioService {
    _workoutStartTime = DateTime.now();

    _workoutLogicService = WorkoutLogicService(
      baseWorkout: workout,
      isAlternateMode: isAlternateMode,
      selectedLevelOrMode: selectedLevelOrMode,
    );

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
    if (_workoutLogicService.exercisesToPerform.isNotEmpty) { // Ensure there's an exercise to announce
      await _audioService.playJustExerciseSound(_workoutLogicService.currentWorkoutSet!.exercise.name);
    }
  }

  void _startTimerListener() {
    _rawTimeSubscription?.cancel(); 
    _rawTimeSubscription = _stopWatchTimer.rawTime.listen((value) async {
      _currentRawTimeMs = value; // New: Update current raw time
      if (!_stopWatchTimer.isRunning) return;

      // In survival mode, currentOverallSetIndex resets to 0, causing incorrect elapsed time calculation.
      // totalSetsCompleted correctly tracks the cumulative number of sets finished.
      final int elapsedInCurrentIntervalMs = value - (_workoutLogicService.totalSetsCompleted * _workout.intervalTimeBetweenSets * 1000);

      if (elapsedInCurrentIntervalMs >= _workout.intervalTimeBetweenSets * 1000) {
        bool workoutContinues = _workoutLogicService.moveToNextSet();
        if (workoutContinues) {
          notifyListeners(); 
          await _audioService.playExerciseAnnouncement(_workoutLogicService.currentWorkoutSet!.exercise.name);
        } else { // Workout has ended
          _isWorkoutFinished = true; // Set flag that workout is finished
          notifyListeners(); // Notify listeners immediately to update UI

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

  void pauseWorkout() {
    _stopWatchTimer.onStopTimer(); // Updated: Use new stop method
    notifyListeners();
  }

  void resumeWorkout() {
    _stopWatchTimer.onStartTimer(); // Updated: Use new start method
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

  void _finishWorkoutInternal() {
    _workoutStartTime ??= DateTime.now();

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

    debugPrint('Creating WorkoutSummary. totalWorkoutDuration: ${_currentRawTimeMs / 1000.0} seconds'); // Updated: Use _currentRawTimeMs
    final summary = WorkoutSummary(
      date: _workoutStartTime!,
      performedSets: finalPerformedSets,
      totalDurationInSeconds: (_currentRawTimeMs / 1000.0).round(), // Updated: Use _currentRawTimeMs
      workoutName: _workout.name,
      workoutLevel: _workoutLogicService.isSurvivalMode ? 1 : (_workoutLogicService.selectedLevelOrMode is int ? _workoutLogicService.selectedLevelOrMode : 1),
      isSurvivalMode: _workoutLogicService.isSurvivalMode,
      isAlternatingSets: _workoutLogicService.isAlternateMode,
      intervalTime: _workout.intervalTimeBetweenSets,
      wasStoppedPrematurely: wasStoppedPrematurely,
      totalSets: finalPerformedSets.length,
    );
    onWorkoutFinished?.call(summary);
  }

  @override
  void dispose() async {
    await _rawTimeSubscription?.cancel();
    _rawTimeSubscription = null;
    await _stopWatchTimer.dispose();
    super.dispose();
  }
}
