import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart'; // Keep Hive import for Box type
import 'package:exercise_timer_app/models/workout_summary.dart';
import 'package:exercise_timer_app/repositories/workout_summary_repository.dart'; // Use the new repository

class WorkoutSummariesScreen extends StatelessWidget {
  const WorkoutSummariesScreen({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final workoutSummaryRepository = Provider.of<WorkoutSummaryRepository>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Summaries'),
      ),
      body: ValueListenableBuilder(
        valueListenable: workoutSummaryRepository.listenable, // Use repository's listenable
        builder: (context, Box<WorkoutSummary> box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text('No workout summaries yet. Complete a workout to see it here!'),
            );
          }
          final List<WorkoutSummary> summaries = box.values.toList().cast<WorkoutSummary>();
          return ListView.builder(
            itemCount: summaries.length,
            itemBuilder: (context, index) {
              final summary = summaries[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ExpansionTile(
                  title: Text('Workout on ${summary.date.toLocal().toString().split(' ')[0]}'),
                  subtitle: Text('Duration: ${_formatDuration(summary.totalDuration)}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: summary.exercises.map((exercise) {
                          return Text('${exercise.name}: ${exercise.sets} sets');
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
