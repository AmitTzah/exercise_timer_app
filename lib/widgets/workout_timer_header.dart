import 'package:flutter/material.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

class WorkoutTimerHeader extends StatelessWidget {
  final dynamic selectedLevelOrMode;
  final Stream<int> timeStream;
  final int totalSetsCompleted;
  final int totalExercisesToPerform;

  const WorkoutTimerHeader({
    super.key,
    required this.selectedLevelOrMode,
    required this.timeStream,
    required this.totalSetsCompleted,
    required this.totalExercisesToPerform,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Column(
        children: [
          Text(
            selectedLevelOrMode == "survival"
                ? 'Survival Time:'
                : 'Total Time Remaining:',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          StreamBuilder<int>(
            stream: timeStream,
            initialData: 0,
            builder: (context, snapshot) {
              final int timeValue = snapshot.data ?? 0;
              return Text(
                StopWatchTimer.getDisplayTime(
                  timeValue,
                  hours: true,
                  minute: true,
                  second: true,
                  milliSecond: false,
                ),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              );
            },
          ),
          Text(
            'Total Sets: $totalSetsCompleted/$totalExercisesToPerform',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
