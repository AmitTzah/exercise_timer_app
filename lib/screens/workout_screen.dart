import 'package:flutter/material.dart';
import 'dart:async';
import 'package:exercise_timer_app/models/exercise.dart';
import 'package:exercise_timer_app/services/audio_service.dart';
import 'package:exercise_timer_app/screens/workout_summary_display_screen.dart';

class WorkoutScreen extends StatefulWidget {
  final List<Exercise> exercises;
  final int intervalTime;

  const WorkoutScreen({
    super.key,
    required this.exercises,
    required this.intervalTime,
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  late AudioService _audioService;
  late Timer _timer;
  int _currentExerciseIndex = 0;
  int _currentSetInExercise = 1;
  int _currentIntervalTimeRemaining = 0;
  int _totalSetsCompleted = 0;
  int _totalWorkoutDuration = 0; // in seconds
  DateTime? _workoutStartTime;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _audioService = AudioService();
    _workoutStartTime = DateTime.now();
    _currentIntervalTimeRemaining = widget.intervalTime;
    _startTimer();
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
          _totalSetsCompleted++;
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

  void _moveToNextSet() {
    if (_currentSetInExercise < widget.exercises[_currentExerciseIndex].sets) {
      _currentSetInExercise++;
    } else {
      if (_currentExerciseIndex < widget.exercises.length - 1) {
        _currentExerciseIndex++;
        _currentSetInExercise = 1;
      } else {
        // Workout complete
        _timer.cancel();
        _audioService.playSessionComplete();
        _navigateToWorkoutSummaryDisplay(completed: true);
        return;
      }
    }
    _currentIntervalTimeRemaining = widget.intervalTime;
  }

  void _navigateToWorkoutSummaryDisplay({required bool completed}) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => WorkoutSummaryDisplayScreen(
          workoutStartTime: _workoutStartTime!,
          exercises: widget.exercises,
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
    return widget.exercises.fold(0, (sum, exercise) => sum + exercise.sets);
  }

  @override
  Widget build(BuildContext context) {
    final currentExercise = widget.exercises[_currentExerciseIndex];
    final totalSets = _getTotalSets();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout in Progress'),
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
              currentExercise.name,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 20),
            Text(
              'Set: $_currentSetInExercise / ${currentExercise.sets}',
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
