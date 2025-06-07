import 'package:flutter/material.dart';

class WorkoutDurationDisplay extends StatelessWidget {
  final int totalDurationInSeconds;
  final String Function(int) formatDuration;

  const WorkoutDurationDisplay({
    super.key,
    required this.totalDurationInSeconds,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'Total Workout Duration: ${formatDuration(totalDurationInSeconds)}',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
