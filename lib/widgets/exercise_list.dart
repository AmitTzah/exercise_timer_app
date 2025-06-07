import 'package:flutter/material.dart';
import 'package:exercise_timer_app/models/workout_item.dart'; // Import WorkoutItem

class ExerciseList extends StatelessWidget {
  final List<WorkoutItem> workoutItems; // Changed to WorkoutItem list
  final Function(int) onEditWorkoutItem; // New callback
  final Function(int) onRemoveWorkoutItem; // New callback
  final Function(int oldIndex, int newIndex) onReorderWorkoutItems; // New callback

  const ExerciseList({
    super.key,
    required this.workoutItems,
    required this.onEditWorkoutItem,
    required this.onRemoveWorkoutItem,
    required this.onReorderWorkoutItems,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: workoutItems.length,
      itemBuilder: (context, index) {
        final item = workoutItems[index];
        if (item is ExerciseItem) {
          final exercise = item.exercise;
          return Card(
            key: ValueKey(exercise.name + index.toString()),
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              title: Text(exercise.name),
              subtitle: Text(
                'Sets: ${exercise.sets}'
                '${exercise.reps != null ? ' | Reps: ${exercise.reps}' : ''}'
                ' | Work: ${exercise.workTimeInSeconds}s'
                '${exercise.restTimeInSeconds != null ? ' | Rest: ${exercise.restTimeInSeconds}s' : ''}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => onEditWorkoutItem(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => onRemoveWorkoutItem(index),
                  ),
                ],
              ),
            ),
          );
        } else if (item is RestBlockItem) {
          return Card(
            key: ValueKey('rest_block_${item.durationInSeconds}_$index'),
            color: Colors.grey[200],
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              title: const Text('Rest Block'),
              subtitle: Text('Duration: ${item.durationInSeconds} seconds'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => onEditWorkoutItem(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => onRemoveWorkoutItem(index),
                  ),
                ],
              ),
            ),
          );
        }
        return Container(); // Should not happen
      },
      onReorder: onReorderWorkoutItems,
    );
  }
}
