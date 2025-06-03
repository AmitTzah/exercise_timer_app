import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:exercise_timer_app/models/exercise.dart';
import 'package:exercise_timer_app/models/user_workout.dart';
import 'package:exercise_timer_app/services/database_service.dart';

class DefineWorkoutScreen extends StatefulWidget {
  final UserWorkout? workout; // Optional: for editing existing workouts

  const DefineWorkoutScreen({super.key, this.workout});

  @override
  State<DefineWorkoutScreen> createState() => _DefineWorkoutScreenState();
}

class _DefineWorkoutScreenState extends State<DefineWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _workoutNameController = TextEditingController();
  final TextEditingController _newExerciseNameController =
      TextEditingController();
  final TextEditingController _newExerciseSetsController =
      TextEditingController();
  final TextEditingController _intervalTimeController = TextEditingController();

  List<Exercise> _exercises = [];
  int _intervalTime = 60; // Default to 60 seconds
  String _workoutId = const Uuid().v4(); // Generate new ID for new workouts
  bool _alternateSets = false; // New state variable for alternate sets

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
      _alternateSets = widget.workout!.alternateSets; // Initialize with existing value
    } else {
      // Creating new workout, set default interval time
      _intervalTimeController.text = _intervalTime.toString();
      _alternateSets = false; // Default for new workouts
    }
  }

  @override
  void dispose() {
    _workoutNameController.dispose();
    _newExerciseNameController.dispose();
    _newExerciseSetsController.dispose();
    _intervalTimeController.dispose();
    super.dispose();
  }

  void _addExercise() {
    final String name = _newExerciseNameController.text.trim();
    final int? sets = int.tryParse(_newExerciseSetsController.text.trim());

    if (name.isNotEmpty && sets != null && sets > 0) {
      setState(() {
        _exercises.add(Exercise(name: name, sets: sets));
        _newExerciseNameController.clear();
        _newExerciseSetsController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid exercise name and number of sets.',
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
        alternateSets: _alternateSets, // Save the new field
      );

      await DatabaseService.saveUserWorkout(newWorkout);

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
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _newExerciseNameController,
                      decoration: const InputDecoration(
                        labelText: 'Exercise Name',
                        hintText: 'e.g., Pushups',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: _addExercise,
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
                      subtitle: Text('Sets: ${exercise.sets}'),
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
                  labelText: 'Interval Time (seconds)',
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
              const SizedBox(height: 10), // Reduced space
              CheckboxListTile(
                title: const Text('Alternate Sets'),
                value: _alternateSets,
                onChanged: (bool? value) {
                  setState(() {
                    _alternateSets = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading, // Checkbox on the left
              ),
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
