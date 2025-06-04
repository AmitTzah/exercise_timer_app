import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:exercise_timer_app/models/user_workout.dart';
import 'package:exercise_timer_app/services/audio_service.dart';
import 'package:exercise_timer_app/screens/workout_summary_display_screen.dart';
import 'package:exercise_timer_app/controllers/workout_controller.dart';
import 'package:exercise_timer_app/models/workout_summary.dart';

class WorkoutScreen extends StatefulWidget {
  final UserWorkout workout;
  final bool isAlternateMode;
  final dynamic selectedLevelOrMode; // int for level, String for "survival"

  const WorkoutScreen({
    super.key,
    required this.workout,
    required this.isAlternateMode,
    required this.selectedLevelOrMode,
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  late WorkoutController _workoutController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final audioService = Provider.of<AudioService>(context, listen: false);
    _workoutController = WorkoutController(
      workout: widget.workout,
      audioService: audioService,
      isAlternateMode: widget.isAlternateMode,
      selectedLevelOrMode: widget.selectedLevelOrMode,
    );

    _workoutController.addListener(_onControllerChanged);
    _workoutController.onWorkoutFinished = (summary) {
      _navigateToWorkoutSummaryDisplay(
        summary: summary,
      );
    };
  }

  @override
  void dispose() {
    _workoutController.removeListener(_onControllerChanged);
    _workoutController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {
      if (_workoutController.currentOverallSetIndex * 60.0 != _scrollController.offset) {
        _scrollController.animateTo(
          _workoutController.currentOverallSetIndex * 60.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _navigateToWorkoutSummaryDisplay({required WorkoutSummary summary}) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => WorkoutSummaryDisplayScreen(
          summary: summary,
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout: ${_workoutController.workout.name}'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                child: Column(
                  children: [
                    Text(
                      widget.selectedLevelOrMode == "survival"
                          ? 'Survival Time:'
                          : 'Total Time Remaining:',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      widget.selectedLevelOrMode == "survival"
                          ? _formatDuration(_workoutController.elapsedSurvivalTime)
                          : _formatDuration(_workoutController.totalTimeRemaining),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    Text(
                      'Total Sets: ${_workoutController.totalSetsCompleted}/${_workoutController.exercisesToPerform.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _workoutController.exercisesToPerform.length,
                  itemBuilder: (context, index) {
                    final workoutSet = _workoutController.exercisesToPerform[index];
                    final isCurrent = index == _workoutController.currentOverallSetIndex;
                    return Card(
                      color: isCurrent ? Colors.blue.shade100 : null,
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: ListTile(
                        leading: isCurrent
                            ? const Icon(Icons.arrow_right, color: Colors.blueAccent, size: 30)
                            : null,
                        title: Text(
                          workoutSet.exercise.name, // Reverted title
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? Colors.blueAccent : Colors.black,
                            fontSize: 20,
                          ),
                        ),
                        subtitle: Text(
                          'Set: ${workoutSet.setNumber} / ${workoutSet.exercise.sets}${workoutSet.exercise.reps != null ? ', Reps: ${workoutSet.exercise.reps}' : ''}',
                          style: TextStyle(
                            color: isCurrent ? Colors.blueAccent : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        trailing: isCurrent
                            ? Text(
                                _formatDuration(_workoutController.currentIntervalTimeRemaining),
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
                    // Removed the redundant "Total Time Remaining" / "Time Survived" text
                    const SizedBox(height: 20), // Keep spacing for buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (_workoutController.isPaused) {
                              _workoutController.resumeWorkout();
                            } else {
                              _workoutController.pauseWorkout();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _workoutController.isPaused ? Colors.green : Colors.orange,
                            minimumSize: const Size(150, 50),
                          ),
                          child: Text(
                            _workoutController.isPaused ? 'Resume Workout' : 'Pause Workout',
                            style: const TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Stop Workout?'),
                                  content: const Text(
                                    'Are you sure you want to stop the workout?',
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('Cancel'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _workoutController.resumeWorkout(); // Resume if cancelled
                                      },
                                    ),
                                    TextButton(
                                      child: const Text('Stop'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _workoutController.finishWorkout();
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
                            'Stop Workout',
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
