import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:exercise_timer_app/models/exercise.dart';
import 'package:exercise_timer_app/models/user_workout.dart';
import 'package:exercise_timer_app/repositories/user_workout_repository.dart'; // Use the new repository

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

  int _calculateTotalDuration() {
    int totalSets = _exercises.fold(0, (sum, exercise) => sum + exercise.sets);
    return totalSets * _intervalTime;
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
              TextFormField(
                controller: _workoutNameController,
                decoration: const InputDecoration(
                  labelText: 'Workout Name',
                  hintText: 'e.g., Full Body Blast',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a workout name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Exercises:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedExerciseName,
                          decoration: const InputDecoration(
                            labelText: 'Exercise Name',
                          ),
                          items: _predefinedExercises.map((String exercise) {
                            return DropdownMenuItem<String>(
                              value: exercise,
                              child: Text(exercise),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedExerciseName = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select an exercise.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8), // Vertical spacing between rows
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _newExerciseSetsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Sets',
                            hintText: 'e.g., 3',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _newExerciseRepsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Reps',
                            hintText: 'e.g., 12',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        onPressed: _addExercise,
                      ),
                    ],
                  ),
                ],
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _exercises.length,
                itemBuilder: (context, index) {
                  final exercise = _exercises[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      title: Text(exercise.name),
                      subtitle: Text(
                        'Sets: ${exercise.sets}${exercise.reps != null ? ' | Reps: ${exercise.reps}' : ''}', // Display reps if available
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeExercise(index),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _intervalTimeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Set Interval Time (seconds)',
                  hintText: 'e.g., 60',
                ),
                validator: (value) {
                  if (value == null ||
                      int.tryParse(value) == null ||
                      int.parse(value) <= 0) {
                    return 'Please enter a valid interval time (seconds).';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _intervalTime = int.tryParse(value) ?? 60;
                  });
                },
              ),
              const SizedBox(height: 20), // Added space for new rest options
              SwitchListTile(
                title: const Text('Include Rest Periods'),
                value: _enableRest,
                onChanged: (bool value) {
                  setState(() {
                    _enableRest = value;
                    // If disabling rest, clear the rest duration controller
                    if (!value) {
                      _restDurationController.text = _restDurationInSeconds.toString(); // Reset to default
                    }
                  });
                },
              ),
              if (_enableRest) // Conditionally display rest duration input
                TextFormField(
                  controller: _restDurationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Rest Duration (seconds)',
                    hintText: 'e.g., 30',
                  ),
                  validator: (value) {
                    if (_enableRest && (value == null || int.tryParse(value) == null || int.parse(value) <= 0)) {
                      return 'Please enter a valid rest duration (seconds).';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _restDurationInSeconds = int.tryParse(value) ?? 30;
                    });
                  },
                ),
              const SizedBox(height: 10), // Reduced space
              const SizedBox(height: 20),
              Text(
                'Total Workout Duration: ${_calculateTotalDuration()} seconds',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveWorkout,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text(
                  'Save Workout',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
