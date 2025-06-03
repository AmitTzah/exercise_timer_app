import 'package:flutter/material.dart';
import 'dart:async';
import 'package:exercise_timer_app/models/user_workout.dart'; // Import UserWorkout
import 'package:exercise_timer_app/models/exercise.dart'; // Import Exercise
import 'package:exercise_timer_app/services/audio_service.dart';
import 'package:exercise_timer_app/screens/workout_summary_display_screen.dart';

class WorkoutScreen extends StatefulWidget {
  final UserWorkout workout; // Now accepts a UserWorkout object

  const WorkoutScreen({
    super.key,
    required this.workout,
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

// Helper class for alternating sets
class _WorkoutSet {
  final Exercise exercise;
  final int setNumber;

  _WorkoutSet({required this.exercise, required this.setNumber});
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  late AudioService _audioService;
  late Timer _timer;
  int _currentIntervalTimeRemaining = 0;
  int _totalSetsCompleted = 0;
  int _totalWorkoutDuration = 0; // in seconds
  DateTime? _workoutStartTime;
  bool _isPaused = false;

  // Variables for workout sequence
  late List<_WorkoutSet> _exercisesToPerform;
  int _currentOverallSetIndex = 0; // Index in _exercisesToPerform list

  @override
  void initState() {
    super.initState();
    _audioService = AudioService();
    _workoutStartTime = DateTime.now();

    if (widget.workout.alternateSets) {
      _exercisesToPerform = _generateAlternatingWorkoutSequence();
    } else {
      _exercisesToPerform = _generateSequentialWorkoutSequence();
    }

    if (_exercisesToPerform.isNotEmpty) {
      _currentIntervalTimeRemaining = widget.workout.intervalTimeBetweenSets;
      _startTimer();
    } else {
      // Handle case where workout has no exercises
      _navigateToWorkoutSummaryDisplay(completed: true);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _audioService.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      setState(() {
        if (_currentIntervalTimeRemaining > 0) {
          _currentIntervalTimeRemaining--;
        } else {
          _audioService.playNextSet();
          _moveToNextSet();
        }
        _totalWorkoutDuration++;
      });
    });
  }

  void _pauseWorkout() {
    setState(() {
      _isPaused = true;
    });
  }

  void _resumeWorkout() {
    setState(() {
      _isPaused = false;
    });
  }

  List<_WorkoutSet> _generateAlternatingWorkoutSequence() {
    List<_WorkoutSet> sequence = [];
    int maxSets = 0;
    for (var exercise in widget.workout.exercises) {
      if (exercise.sets > maxSets) {
        maxSets = exercise.sets;
      }
    }

    for (int s = 1; s <= maxSets; s++) {
      for (var exercise in widget.workout.exercises) {
        if (s <= exercise.sets) {
          sequence.add(_WorkoutSet(exercise: exercise, setNumber: s));
        }
      }
    }
    return sequence;
  }

  List<_WorkoutSet> _generateSequentialWorkoutSequence() {
    List<_WorkoutSet> sequence = [];
    for (var exercise in widget.workout.exercises) {
      for (int s = 1; s <= exercise.sets; s++) {
        sequence.add(_WorkoutSet(exercise: exercise, setNumber: s));
      }
    }
    return sequence;
  }

  void _moveToNextSet() {
    _totalSetsCompleted++; // Increment total sets completed after each set

    if (_currentOverallSetIndex < _exercisesToPerform.length - 1) {
      _currentOverallSetIndex++;
      _currentIntervalTimeRemaining = widget.workout.intervalTimeBetweenSets;
    } else {
      // Workout complete
      _timer.cancel();
      _audioService.playSessionComplete();
      _navigateToWorkoutSummaryDisplay(completed: true);
    }
  }

  void _navigateToWorkoutSummaryDisplay({required bool completed}) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => WorkoutSummaryDisplayScreen(
          workoutStartTime: _workoutStartTime!,
          exercises: widget.workout.exercises, // Pass exercises from UserWorkout
          totalDurationInSeconds: _totalWorkoutDuration,
          completed: completed,
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  int _getTotalSets() {
    return widget.workout.exercises.fold(0, (sum, exercise) => sum + exercise.sets); // Use from UserWorkout
  }

  @override
  Widget build(BuildContext context) {
    // Determine the current exercise and set based on the sequence
    final _WorkoutSet? currentWorkoutSet = _exercisesToPerform.isNotEmpty
        ? _exercisesToPerform[_currentOverallSetIndex]
        : null;

    final totalSets = _getTotalSets();

    return Scaffold(
      appBar: AppBar(
        title: Text('Workout: ${widget.workout.name}'), // Display workout name
        automaticallyImplyLeading: false, // No back button during workout
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Current Exercise:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              currentWorkoutSet?.exercise.name ?? 'N/A',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 20),
            Text(
              'Set: ${currentWorkoutSet?.setNumber ?? 0} / ${currentWorkoutSet?.exercise.sets ?? 0}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Total Set: $_totalSetsCompleted / $totalSets',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 40),
            Text(
              _formatDuration(_currentIntervalTimeRemaining),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_isPaused) {
                      _resumeWorkout();
                    } else {
                      _pauseWorkout();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPaused ? Colors.green : Colors.orange,
                    minimumSize: const Size(150, 50),
                  ),
                  child: Text(
                    _isPaused ? 'Resume Workout' : 'Pause Workout',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _timer.cancel();
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Finish Workout?'),
                          content: const Text('Are you sure you want to finish the workout?'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop(); // Close dialog
                                _startTimer(); // Resume timer if cancelled
                              },
                            ),
                            TextButton(
                              child: const Text('Finish'),
                              onPressed: () {
                                Navigator.of(context).pop(); // Close dialog
                                _navigateToWorkoutSummaryDisplay(completed: false);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(150, 50),
                  ),
                  child: const Text(
                    'Finish Workout',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
