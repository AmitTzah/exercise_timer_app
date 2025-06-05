import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:exercise_timer_app/models/workout_summary.dart';
import 'package:exercise_timer_app/repositories/workout_summary_repository.dart'; // Use the new repository
import 'package:intl/intl.dart'; // For date formatting

class WorkoutSummaryDisplayScreen extends StatelessWidget {
  final WorkoutSummary summary;

  const WorkoutSummaryDisplayScreen({
    super.key,
    required this.summary,
  });

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150, // Fixed width for labels
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
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
              summary.wasStoppedPrematurely
                  ? 'Workout Stopped Early!'
                  : (summary.isSurvivalMode ? 'Survival Workout Ended!' : 'Workout Complete!'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            _buildSummaryRow(context, 'Workout Name:', summary.workoutName),
            _buildSummaryRow(context, 'Date:', DateFormat('yyyy-MM-dd HH:mm').format(summary.date)),
            _buildSummaryRow(context, 'Total Duration:', _formatDuration(summary.totalDurationInSeconds)),
            _buildSummaryRow(context, 'Workout Level:', summary.workoutLevel.toString()),
            _buildSummaryRow(context, 'Alternating Sets:', summary.isAlternatingSets ? 'Yes' : 'No'),
            _buildSummaryRow(context, 'Interval Time:', '${summary.intervalTime} seconds'),
            _buildSummaryRow(context, 'Total Sets Performed:', summary.totalSets.toString()),
            const SizedBox(height: 20),
            Text(
              'Exercises Performed:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: summary.performedSets.length, // Use performedSets
                itemBuilder: (context, index) {
                  final workoutSet = summary.performedSets[index]; // Get WorkoutSet
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      '- ${workoutSet.exercise.name} (Set ${workoutSet.setNumber})${workoutSet.exercise.reps != null ? ', ${workoutSet.exercise.reps} reps' : ''}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
              child: Row(
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
                      final workoutSummaryRepository = Provider.of<WorkoutSummaryRepository>(context, listen: false);
                      await workoutSummaryRepository.addWorkoutSummary(summary); // Use the passed summary
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
            ),
          ],
        ),
      ),
    );
  }
}
