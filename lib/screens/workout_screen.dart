import 'package:flutter/material.dart';
import 'dart:async';
import 'package:exercise_timer_app/models/user_workout.dart'; // Import UserWorkout
import 'package:exercise_timer_app/models/exercise.dart'; // Import Exercise
import 'package:exercise_timer_app/services/audio_service.dart';
import 'package:exercise_timer_app/screens/workout_summary_display_screen.dart';

class WorkoutScreen extends StatefulWidget {
  final UserWorkout workout; // Now accepts a UserWorkout object

  const WorkoutScreen({super.key, required this.workout});

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
  late int _totalExpectedWorkoutDuration;
  late int _totalTimeRemaining;
  final ScrollController _scrollController = ScrollController();

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

    _totalExpectedWorkoutDuration = _exercisesToPerform.length * widget.workout.intervalTimeBetweenSets;
    _totalTimeRemaining = _totalExpectedWorkoutDuration;

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
        } else { // Interval just ended, move to next set and prepare its timer
          bool workoutContinues = _moveToNextSetAndPrepareInterval();
          if (workoutContinues) {
            _currentIntervalTimeRemaining--; // Decrement immediately for the new set
            _audioService.playNextSet(); // Play sound immediately
          }
        }

        if (_totalTimeRemaining > 0) {
          _totalTimeRemaining--;
        }
        if (_totalTimeRemaining < 0) _totalTimeRemaining = 0;

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

  bool _moveToNextSetAndPrepareInterval() {
    _totalSetsCompleted++; // Increment total sets completed after each set

    if (_currentOverallSetIndex < _exercisesToPerform.length - 1) {
      _currentOverallSetIndex++;
      _currentIntervalTimeRemaining = widget.workout.intervalTimeBetweenSets;
      // Scroll to the current item
      _scrollController.animateTo(
        _currentOverallSetIndex * 60.0, // Assuming each item has a height of 60.0
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return true; // Workout continues
    } else {
      // Workout complete
      _timer.cancel();
      _currentIntervalTimeRemaining = 0;
      _totalTimeRemaining = 0;
      _audioService.playSessionComplete(); // Play sound (non-blocking)
      _navigateToWorkoutSummaryDisplay(completed: true);
      return false; // Workout finished
    }
  }

  void _navigateToWorkoutSummaryDisplay({required bool completed}) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => WorkoutSummaryDisplayScreen(
          workoutStartTime: _workoutStartTime!,
          exercises:
              widget.workout.exercises, // Pass exercises from UserWorkout
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
    return widget.workout.exercises.fold(
      0,
      (sum, exercise) => sum + exercise.sets,
    ); // Use from UserWorkout
  }

  @override
  Widget build(BuildContext context) {
    final totalSets = _getTotalSets();

    return Scaffold(
      appBar: AppBar(
        title: Text('Workout: ${widget.workout.name}'), // Display workout name
        automaticallyImplyLeading: false, // No back button during workout
      ),
      body: SafeArea( // Wrapped the entire content in SafeArea
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                child: Column(
                  children: [
                    Text(
                      'Total Time Remaining:',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      _formatDuration(_totalTimeRemaining),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _exercisesToPerform.length,
                  itemBuilder: (context, index) {
                    final workoutSet = _exercisesToPerform[index];
                    final isCurrent = index == _currentOverallSetIndex;
                    return Card(
                      color: isCurrent ? Colors.blue.shade100 : null,
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: ListTile(
                        leading: isCurrent
                            ? const Icon(Icons.arrow_right, color: Colors.blueAccent, size: 30)
                            : null,
                        title: Text(
                          workoutSet.exercise.name,
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? Colors.blueAccent : Colors.black,
                            fontSize: 20,
                          ),
                        ),
                        subtitle: Text(
                          'Set: ${workoutSet.setNumber} / ${workoutSet.exercise.sets}',
                          style: TextStyle(
                            color: isCurrent ? Colors.blueAccent : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        trailing: isCurrent
                            ? Text(
                                _formatDuration(_currentIntervalTimeRemaining),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                  fontSize: 22,
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                child: Column(
                  children: [
                    Text(
                      'Total Sets: $_totalSetsCompleted / $totalSets',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 20),
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
                                  content: const Text(
                                    'Are you sure you want to finish the workout?',
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('Cancel'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _startTimer();
                                      },
                                    ),
                                    TextButton(
                                      child: const Text('Finish'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _navigateToWorkoutSummaryDisplay(
                                          completed: false,
                                        );
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
            ],
          ),
        ),
      ),
    );
  }
}
