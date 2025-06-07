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
import 'package:exercise_timer_app/models/workout_item.dart'; // Import WorkoutItem

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
  final TextEditingController _newExerciseRepsController = TextEditingController();
  final TextEditingController _newExerciseWorkTimeController = TextEditingController(); // New controller for work time
  final TextEditingController _newExerciseRestTimeController = TextEditingController(); // New controller for rest time

  List<WorkoutItem> _workoutItems = []; // Changed to WorkoutItem
  String _workoutId = const Uuid().v4(); // Generate new ID for new workouts

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
      _workoutItems = List.from(widget.workout!.items); // Populate with WorkoutItems

      // Set initial selected exercise if editing and it's in the predefined list
      // Find the first ExerciseItem to set the initial selected exercise name
      final firstExerciseItem = _workoutItems.firstWhere(
        (item) => item is ExerciseItem,
        orElse: () => ExerciseItem(exercise: Exercise(name: _predefinedExercises.first, sets: 1, workTimeInSeconds: 60)), // Default if no exercise items
      ) as ExerciseItem;
      _selectedExerciseName = firstExerciseItem.exercise.name;

    } else {
      // Creating new workout, set default values for new exercise input
      _newExerciseWorkTimeController.text = '60'; // Default work time
      _newExerciseRestTimeController.text = '10'; // Default rest time
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
    _newExerciseWorkTimeController.dispose(); // Dispose new controller
    _newExerciseRestTimeController.dispose(); // Dispose new controller
    super.dispose();
  }

  void _addExercise() {
    final String? name = _selectedExerciseName;
    final int? sets = int.tryParse(_newExerciseSetsController.text.trim());
    final int? reps = int.tryParse(_newExerciseRepsController.text.trim());
    final int? workTime = int.tryParse(_newExerciseWorkTimeController.text.trim());
    final int? restTime = int.tryParse(_newExerciseRestTimeController.text.trim());

    if (name != null && name.isNotEmpty && sets != null && sets > 0 && workTime != null && workTime > 0) {
      setState(() {
        _workoutItems.add(ExerciseItem(
          exercise: Exercise(
            name: name,
            sets: sets,
            reps: reps,
            workTimeInSeconds: workTime,
            restTimeInSeconds: restTime,
          ),
        ));
        _newExerciseSetsController.clear();
        _newExerciseRepsController.clear();
        _newExerciseWorkTimeController.text = '60'; // Reset to default
        _newExerciseRestTimeController.text = '10'; // Reset to default
        _selectedExerciseName = _predefinedExercises.first; // Reset dropdown
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select an exercise, enter valid sets, and work time.',
          ),
        ),
      );
    }
  }

  void _addRestBlock() {
    final TextEditingController restBlockDurationController = TextEditingController(text: '30'); // Default rest block duration

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Rest Block'),
          content: TextField(
            controller: restBlockDurationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Rest Duration (seconds)'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () {
                final int? duration = int.tryParse(restBlockDurationController.text.trim());
                if (duration != null && duration > 0) {
                  setState(() {
                    _workoutItems.add(RestBlockItem(durationInSeconds: duration));
                  });
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid rest duration.'),
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

  void _removeWorkoutItem(int index) {
    setState(() {
      _workoutItems.removeAt(index);
    });
  }

  void _editWorkoutItem(int index) {
    final WorkoutItem itemToEdit = _workoutItems[index];

    if (itemToEdit is ExerciseItem) {
      final Exercise exerciseToEdit = itemToEdit.exercise;
      final TextEditingController setsController =
          TextEditingController(text: exerciseToEdit.sets.toString());
      final TextEditingController repsController =
          TextEditingController(text: exerciseToEdit.reps?.toString() ?? '');
      final TextEditingController workTimeController =
          TextEditingController(text: exerciseToEdit.workTimeInSeconds.toString());
      final TextEditingController restTimeController =
          TextEditingController(text: exerciseToEdit.restTimeInSeconds?.toString() ?? '');

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
                  decoration: const InputDecoration(labelText: 'Reps (Optional)'),
                ),
                TextField(
                  controller: workTimeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Work Time (seconds)'),
                ),
                TextField(
                  controller: restTimeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Rest Time (seconds, Optional)'),
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
                  final int? newWorkTime = int.tryParse(workTimeController.text.trim());
                  final int? newRestTime = int.tryParse(restTimeController.text.trim());

                  if (newSets != null && newSets > 0 && newWorkTime != null && newWorkTime > 0) {
                    setState(() {
                      _workoutItems[index] = ExerciseItem(
                        exercise: Exercise(
                          name: exerciseToEdit.name,
                          sets: newSets,
                          reps: newReps,
                          workTimeInSeconds: newWorkTime,
                          restTimeInSeconds: newRestTime,
                          audioFileName: exerciseToEdit.audioFileName,
                        ),
                      );
                    });
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter valid sets and work time.'),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    } else if (itemToEdit is RestBlockItem) {
      final TextEditingController restBlockDurationController =
          TextEditingController(text: itemToEdit.durationInSeconds.toString());

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Edit Rest Block'),
            content: TextField(
              controller: restBlockDurationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Rest Duration (seconds)'),
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
                  final int? newDuration = int.tryParse(restBlockDurationController.text.trim());
                  if (newDuration != null && newDuration > 0) {
                    setState(() {
                      _workoutItems[index] = RestBlockItem(durationInSeconds: newDuration);
                    });
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid rest duration.'),
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
  }

  int _calculateTotalDuration() {
    int totalDuration = 0;
    for (var item in _workoutItems) {
      if (item is ExerciseItem) {
        totalDuration += item.exercise.sets * item.exercise.workTimeInSeconds;
        if (item.exercise.restTimeInSeconds != null) {
          totalDuration += item.exercise.sets * item.exercise.restTimeInSeconds!;
        }
      } else if (item is RestBlockItem) {
        totalDuration += item.durationInSeconds;
      }
    }
    return totalDuration;
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 0) {
      return 'N/A';
    }

    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;

    List<String> parts = [];
    if (hours > 0) {
      parts.add('${hours}h');
    }
    if (minutes > 0 || hours > 0) {
      parts.add('${minutes}m');
    }
    if (seconds > 0 || (hours == 0 && minutes == 0)) {
      parts.add('${seconds}s');
    }

    return parts.join(' ');
  }

  Future<void> _saveWorkout() async {
    if (_formKey.currentState!.validate()) {
      if (_workoutItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one exercise or rest block.')),
        );
        return;
      }

      final String workoutName = _workoutNameController.text.trim();
      final int totalDuration = _calculateTotalDuration();

      final UserWorkout newWorkout = UserWorkout(
        id: _workoutId,
        name: workoutName,
        items: _workoutItems, // Use new items list
        totalWorkoutTime: totalDuration,
      );

      await _userWorkoutRepository.saveUserWorkout(newWorkout);

      if (!mounted) return;
      Navigator.of(context).pop();
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
                newExerciseWorkTimeController: _newExerciseWorkTimeController, // Pass new controller
                newExerciseRestTimeController: _newExerciseRestTimeController, // Pass new controller
                onExerciseSelected: (newValue) {
                  setState(() {
                    _selectedExerciseName = newValue;
                  });
                },
                onAddExercise: _addExercise,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addRestBlock,
                child: const Text('Add Rest Block'),
              ),
              const SizedBox(height: 20),
              ExerciseList(
                workoutItems: _workoutItems, // Pass workoutItems
                onEditWorkoutItem: _editWorkoutItem, // Use new edit method
                onRemoveWorkoutItem: _removeWorkoutItem, // Use new remove method
                onReorderWorkoutItems: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final WorkoutItem item = _workoutItems.removeAt(oldIndex);
                    _workoutItems.insert(newIndex, item);
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
