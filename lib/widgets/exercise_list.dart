import 'package:flutter/material.dart';
import 'package:exercise_timer_app/models/exercise.dart';

class ExerciseList extends StatelessWidget {
  final List<Exercise> exercises;
  final Function(int) onEditExercise;
  final Function(int) onRemoveExercise;
  final Function(int oldIndex, int newIndex) onReorderExercises;

  const ExerciseList({
    super.key,
    required this.exercises,
    required this.onEditExercise,
    required this.onRemoveExercise,
    required this.onReorderExercises,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return Card(
          key: ValueKey(exercise.name + index.toString()), // Unique key for reordering
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            title: Text(exercise.name),
            subtitle: Text(
              'Sets: ${exercise.sets}${exercise.reps != null ? ' | Reps: ${exercise.reps}' : ''}', // Display reps if available
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => onEditExercise(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => onRemoveExercise(index),
                ),
              ],
            ),
          ),
        );
      },
      onReorder: onReorderExercises,
    );
  }
}
