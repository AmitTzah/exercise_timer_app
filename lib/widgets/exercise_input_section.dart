import 'package:flutter/material.dart';

class ExerciseInputSection extends StatefulWidget {
  final List<String> predefinedExercises;
  final String? selectedExerciseName;
  final TextEditingController newExerciseSetsController;
  final TextEditingController newExerciseRepsController;
  final ValueChanged<String?> onExerciseSelected;
  final VoidCallback onAddExercise;

  const ExerciseInputSection({
    super.key,
    required this.predefinedExercises,
    required this.selectedExerciseName,
    required this.newExerciseSetsController,
    required this.newExerciseRepsController,
    required this.onExerciseSelected,
    required this.onAddExercise,
  });

  @override
  State<ExerciseInputSection> createState() => _ExerciseInputSectionState();
}

class _ExerciseInputSectionState extends State<ExerciseInputSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: widget.selectedExerciseName,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name',
                ),
                items: widget.predefinedExercises.map((String exercise) {
                  return DropdownMenuItem<String>(
                    value: exercise,
                    child: Text(exercise),
                  );
                }).toList(),
                onChanged: widget.onExerciseSelected,
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
                controller: widget.newExerciseSetsController,
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
                controller: widget.newExerciseRepsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reps',
                  hintText: 'e.g., 12',
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: widget.onAddExercise,
            ),
          ],
        ),
      ],
    );
  }
}
