import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:exercise_timer_app/models/user_workout.dart';
import 'package:exercise_timer_app/services/audio_service.dart';
import 'package:exercise_timer_app/screens/workout_summary_display_screen.dart';
import 'package:exercise_timer_app/controllers/workout_controller.dart';
import 'package:exercise_timer_app/models/workout_summary.dart';
import 'package:exercise_timer_app/widgets/workout_timer_header.dart';
import 'package:exercise_timer_app/widgets/workout_set_list.dart';
import 'package:exercise_timer_app/widgets/workout_controls.dart';

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
  int _lastOverallSetIndex = -1; // Track the last index to prevent redundant scrolls

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
      // Only animate if the current set index has actually changed
      if (_workoutController.currentOverallSetIndex != _lastOverallSetIndex) {
        _lastOverallSetIndex = _workoutController.currentOverallSetIndex;
        _scrollController.animateTo(
          _workoutController.currentOverallSetIndex * 60.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _navigateToWorkoutSummaryDisplay({required WorkoutSummary summary}) {
    if (!mounted) return; // Check if the widget is still mounted
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => WorkoutSummaryDisplayScreen(
          summary: summary,
        ),
      ),
    );
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
              WorkoutTimerHeader(
                selectedLevelOrMode: widget.selectedLevelOrMode,
                timeStream: widget.selectedLevelOrMode == "survival"
                    ? _workoutController.elapsedSurvivalTimeStream
                    : _workoutController.totalTimeRemainingStream,
                totalSetsCompleted: _workoutController.totalSetsCompleted,
                totalExercisesToPerform: _workoutController.exercisesToPerform.length,
              ),
              WorkoutSetList(
                scrollController: _scrollController,
                exercisesToPerform: _workoutController.exercisesToPerform,
                currentOverallSetIndex: _workoutController.currentOverallSetIndex,
                currentIntervalTimeRemainingStream: _workoutController.currentIntervalTimeRemainingStream,
              ),
              WorkoutControls(
                isPaused: _workoutController.isPaused,
                onPauseResume: () {
                  if (_workoutController.isPaused) {
                    _workoutController.resumeWorkout();
                  } else {
                    _workoutController.pauseWorkout();
                  }
                },
                onStop: () {
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
                              _workoutController.resumeWorkout();
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
