import 'package:flutter/material.dart';
import 'package:exercise_timer_app/models/exercise.dart';
import 'package:exercise_timer_app/models/workout_item.dart';

class AddExerciseDialog extends StatefulWidget {
  final List<String> predefinedExercises;

  const AddExerciseDialog({
    super.key,
    required this.predefinedExercises,
  });

  @override
  State<AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<AddExerciseDialog> {
  String? _selectedExerciseName;
  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _workTimeController = TextEditingController();
  final TextEditingController _restTimeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedExerciseName = widget.predefinedExercises.first;
    _workTimeController.text = '60';
    _restTimeController.text = '10';
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _workTimeController.dispose();
    _restTimeController.dispose();
    super.dispose();
  }

  void _addExercise() {
    if (_formKey.currentState!.validate()) {
      final String? name = _selectedExerciseName;
      final int? sets = int.tryParse(_setsController.text.trim());
      final int? reps = int.tryParse(_repsController.text.trim());
      final int? workTime = int.tryParse(_workTimeController.text.trim());
      final int? restTime = int.tryParse(_restTimeController.text.trim());

      if (name != null && name.isNotEmpty && sets != null && sets > 0 && workTime != null && workTime > 0) {
        Navigator.of(context).pop(ExerciseItem(
          exercise: Exercise(
            name: name,
            sets: sets,
            reps: reps,
            workTimeInSeconds: workTime,
            restTimeInSeconds: restTime,
          ),
        ));
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
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Exercise'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedExerciseName,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name',
                ),
                items: widget.predefinedExercises.map((String exercise) {
                  return DropdownMenuItem<String>(
                    value: exercise,
                    child: Text(exercise),
                  );
                }).toList(),
                onChanged: (newValue) {
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
              TextFormField(
                controller: _setsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sets',
                  hintText: 'e.g., 3',
                ),
                validator: (value) {
                  if (value == null || int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter valid sets.';
                  }
                  return null;
                },
              ),
              TextField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reps (Optional)',
                  hintText: 'e.g., 12',
                ),
              ),
              TextFormField(
                controller: _workTimeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Work Time (seconds)',
                  hintText: 'e.g., 60',
                ),
                validator: (value) {
                  if (value == null || int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter valid work time.';
                  }
                  return null;
                },
              ),
              TextField(
                controller: _restTimeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Rest Time (seconds, Optional)',
                  hintText: 'e.g., 10',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          onPressed: _addExercise,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
