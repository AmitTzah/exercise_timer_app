import 'package:flutter/material.dart';
import 'package:exercise_timer_app/models/exercise.dart';
import 'package:exercise_timer_app/models/workout_summary.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // For date formatting

class WorkoutSummaryDisplayScreen extends StatelessWidget {
  final DateTime workoutStartTime;
  final List<Exercise> exercises;
  final int totalDurationInSeconds;
  final bool completed;

  const WorkoutSummaryDisplayScreen({
    super.key,
    required this.workoutStartTime,
    required this.exercises,
    required this.totalDurationInSeconds,
    required this.completed,
  });

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Summary'),
        automaticallyImplyLeading: false, // No back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              completed ? 'Workout Complete!' : 'Workout Ended!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Text(
              'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(workoutStartTime)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              'Total Duration: ${_formatDuration(totalDurationInSeconds)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Text(
              'Exercises Performed:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      '- ${exercise.name} (${exercise.sets} sets)',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst); // Go back to setup screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(150, 50),
                  ),
                  child: const Text(
                    'Discard Workout',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final workoutSummary = WorkoutSummary(
                      date: workoutStartTime,
                      exercises: exercises,
                      totalDurationInSeconds: totalDurationInSeconds,
                    );
                    await Hive.box<WorkoutSummary>('workoutSummaries').add(workoutSummary);
                    if (!context.mounted) return;
                    Navigator.of(context).popUntil((route) => route.isFirst); // Go back to setup screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(150, 50),
                  ),
                  child: const Text(
                    'Save Workout',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
