import 'package:flutter/material.dart';
import 'dart:async';
import 'package:exercise_timer_app/models/exercise.dart';
import 'package:exercise_timer_app/models/workout_summary.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:exercise_timer_app/services/audio_service.dart';

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
        _saveWorkoutSummary(completed: true);
        _showCompletionDialog();
        return;
      }
    }
    _currentIntervalTimeRemaining = widget.intervalTime;
  }

  void _saveWorkoutSummary({bool completed = false}) {
    final workoutSummary = WorkoutSummary(
      date: _workoutStartTime!,
      exercises: widget.exercises,
      totalDurationInSeconds: _totalWorkoutDuration,
    );
    Hive.box<WorkoutSummary>('workoutSummaries').add(workoutSummary);
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Workout Complete!'),
          content: Text('You completed all sets in $_totalWorkoutDuration seconds.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                if (!mounted) return;
                Navigator.of(context).pop(); // Close dialog
                if (!mounted) return;
                Navigator.of(context).pop(); // Go back to setup screen
              },
            ),
          ],
        );
      },
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
            ElevatedButton(
              onPressed: () {
                _timer.cancel();
                _saveWorkoutSummary(completed: false);
                Navigator.of(context).pop(); // Go back to setup screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text(
                'Stop Workout',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
