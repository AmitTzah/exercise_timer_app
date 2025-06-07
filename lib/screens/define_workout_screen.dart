import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:exercise_timer_app/models/exercise.dart';
import 'package:exercise_timer_app/models/user_workout.dart';
import 'package:exercise_timer_app/repositories/user_workout_repository.dart'; // Use the new repository
import 'package:exercise_timer_app/widgets/workout_name_text_field.dart';
import 'package:exercise_timer_app/widgets/exercise_input_section.dart';
import 'package:exercise_timer_app/widgets/exercise_list.dart';
import 'package:exercise_timer_app/widgets/interval_and_rest_section.dart';
import 'package:exercise_timer_app/widgets/workout_duration_display.dart';
import 'package:exercise_timer_app/widgets/save_workout_button.dart';

class DefineWorkoutScreen extends StatefulWidget {
  final UserWorkout? workout; // Optional: for editing existing workouts

  const DefineWorkoutScreen({super.key, this.workout});

  @override
  State<DefineWorkoutScreen> createState() => _DefineWorkoutScreenState();
}

class _DefineWorkoutScreenState extends State<DefineWorkoutScreen> {
  late UserWorkoutRepository _userWorkoutRepository; // Declare repository
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _workoutNameController = TextEditingController();
  String? _selectedExerciseName; // New variable to hold selected exercise
  final TextEditingController _newExerciseSetsController =
      TextEditingController();
  final TextEditingController _newExerciseRepsController =
      TextEditingController(); // New controller for reps
  final TextEditingController _intervalTimeController = TextEditingController();
  final TextEditingController _restDurationController = TextEditingController(); // New controller for rest duration

  List<Exercise> _exercises = [];
  int _intervalTime = 60; // Default to 60 seconds
  String _workoutId = const Uuid().v4(); // Generate new ID for new workouts
  bool _enableRest = false; // Default to false
  int _restDurationInSeconds = 30; // Default rest duration

  // Predefined list of exercises
  final List<String> _predefinedExercises = [
    'Pull-ups',
    'Dips',
    'Squats',
    'One-legged Squats',
    'Push-ups',
    'Sit-ups',
    'Lunges',
    'Crunches',
    'Bench Press',
    'Deadlift',
    'Muscle-Ups',
    'Handstand Push-Ups',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.workout != null) {
      // Editing existing workout
      _workoutId = widget.workout!.id;
      _workoutNameController.text = widget.workout!.name;
      _exercises = List.from(widget.workout!.exercises);
      _intervalTime = widget.workout!.intervalTimeBetweenSets;
      _intervalTimeController.text = _intervalTime.toString();
      _enableRest = widget.workout!.enableRest ?? false;
      _restDurationInSeconds = widget.workout!.restDurationInSeconds ?? 30;
      _restDurationController.text = _restDurationInSeconds.toString();
      // Populate reps for existing exercises if available
      for (var exercise in _exercises) {
        if (exercise.reps != null) {
          _newExerciseRepsController.text = exercise.reps.toString();
        }
      }
    } else {
      // Creating new workout, set default interval time and rest duration
      _intervalTimeController.text = _intervalTime.toString();
      _restDurationController.text = _restDurationInSeconds.toString();
    }
    // Set initial selected exercise if editing and it's in the predefined list
    if (widget.workout != null && _exercises.isNotEmpty) {
      _selectedExerciseName = _exercises.first.name; // Or the first exercise in the list
    } else {
      _selectedExerciseName = _predefinedExercises.first; // Default to the first in the list
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userWorkoutRepository = Provider.of<UserWorkoutRepository>(context); // Get repository
  }

  @override
  void dispose() {
    _workoutNameController.dispose();
    _newExerciseSetsController.dispose();
    _newExerciseRepsController.dispose();
    _intervalTimeController.dispose();
    _restDurationController.dispose(); // Dispose new controller
    super.dispose();
  }

  void _addExercise() {
    final String? name = _selectedExerciseName; // Use the selected exercise name
    final int? sets = int.tryParse(_newExerciseSetsController.text.trim());
    final int? reps = int.tryParse(_newExerciseRepsController.text.trim());

    if (name != null && name.isNotEmpty && sets != null && sets > 0) {
      setState(() {
        _exercises.add(Exercise(name: name, sets: sets, reps: reps));
        _newExerciseSetsController.clear();
        _newExerciseRepsController.clear();
        _selectedExerciseName = _predefinedExercises.first; // Reset dropdown to first item
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select an exercise and enter a valid number of sets.',
          ),
        ),
      );
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  void _editExercise(int index) {
    final Exercise exerciseToEdit = _exercises[index];
    final TextEditingController setsController =
        TextEditingController(text: exerciseToEdit.sets.toString());
    final TextEditingController repsController =
        TextEditingController(text: exerciseToEdit.reps?.toString() ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit ${exerciseToEdit.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: setsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sets'),
              ),
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Reps'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                final int? newSets = int.tryParse(setsController.text.trim());
                final int? newReps = int.tryParse(repsController.text.trim());

                if (newSets != null && newSets > 0) {
                  setState(() {
                    _exercises[index] = Exercise(
                      name: exerciseToEdit.name,
                      sets: newSets,
                      reps: newReps,
                    );
                  });
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid number of sets.'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  int _calculateTotalDuration() {
    int totalSets = _exercises.fold(0, (sum, exercise) => sum + exercise.sets);
    return totalSets * _intervalTime;
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 0) {
      return 'N/A'; // Or throw an error, depending on desired behavior for negative input
    }

    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;

    List<String> parts = [];
    if (hours > 0) {
      parts.add('${hours}h');
    }
    if (minutes > 0 || hours > 0) { // Show minutes if there are hours, or if minutes are present
      parts.add('${minutes}m');
    }
    if (seconds > 0 || (hours == 0 && minutes == 0)) { // Show seconds if there are no hours/minutes, or if seconds are present
      parts.add('${seconds}s');
    }

    return parts.join(' ');
  }

  Future<void> _saveWorkout() async {
    if (_formKey.currentState!.validate()) {
      if (_exercises.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one exercise.')),
        );
        return;
      }

      final String workoutName = _workoutNameController.text.trim();
      final int totalDuration = _calculateTotalDuration();

      final UserWorkout newWorkout = UserWorkout(
        id: _workoutId,
        name: workoutName,
        exercises: _exercises,
        intervalTimeBetweenSets: _intervalTime,
        totalWorkoutTime: totalDuration,
        enableRest: _enableRest, // Pass new field
        restDurationInSeconds: _restDurationInSeconds, // Pass new field
      );

      await _userWorkoutRepository.saveUserWorkout(newWorkout); // Use repository

      if (!mounted) return;
      Navigator.of(context).pop(); // Go back to the home screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.workout == null ? 'Define New Workout' : 'Edit Workout',
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              WorkoutNameTextField(controller: _workoutNameController),
              const SizedBox(height: 20),
              const Text(
                'Exercises:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ExerciseInputSection(
                predefinedExercises: _predefinedExercises,
                selectedExerciseName: _selectedExerciseName,
                newExerciseSetsController: _newExerciseSetsController,
                newExerciseRepsController: _newExerciseRepsController,
                onExerciseSelected: (newValue) {
                  setState(() {
                    _selectedExerciseName = newValue;
                  });
                },
                onAddExercise: _addExercise,
              ),
              ExerciseList(
                exercises: _exercises,
                onEditExercise: _editExercise,
                onRemoveExercise: _removeExercise,
                onReorderExercises: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final Exercise item = _exercises.removeAt(oldIndex);
                    _exercises.insert(newIndex, item);
                  });
                },
              ),
              const SizedBox(height: 20),
              IntervalAndRestSection(
                intervalTimeController: _intervalTimeController,
                intervalTime: _intervalTime,
                onIntervalTimeChanged: (value) {
                  setState(() {
                    _intervalTime = int.tryParse(value) ?? 60;
                  });
                },
                enableRest: _enableRest,
                onEnableRestChanged: (value) {
                  setState(() {
                    _enableRest = value;
                    if (!value) {
                      _restDurationController.text = _restDurationInSeconds.toString();
                    }
                  });
                },
                restDurationController: _restDurationController,
                restDurationInSeconds: _restDurationInSeconds,
                onRestDurationChanged: (value) {
                  setState(() {
                    _restDurationInSeconds = int.tryParse(value) ?? 30;
                  });
                },
              ),
              const SizedBox(height: 20),
              WorkoutDurationDisplay(
                totalDurationInSeconds: _calculateTotalDuration(),
                formatDuration: _formatDuration,
              ),
              const SizedBox(height: 20),
              SaveWorkoutButton(onPressed: _saveWorkout),
            ],
          ),
        ),
      ),
    );
  }
}
