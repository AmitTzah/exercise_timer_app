import 'package:flutter/material.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:exercise_timer_app/models/workout_set.dart';
// Import UserWorkout for restDurationInSeconds

class WorkoutSetList extends StatelessWidget {
  final ScrollController scrollController;
  final List<WorkoutSet> exercisesToPerform;
  final int currentOverallSetIndex;
  final Stream<int> currentIntervalTimeRemainingStream;

  const WorkoutSetList({
    super.key,
    required this.scrollController,
    required this.exercisesToPerform,
    required this.currentOverallSetIndex,
    required this.currentIntervalTimeRemainingStream,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: ListView.builder(
        controller: scrollController,
        itemCount: exercisesToPerform.length,
        itemBuilder: (context, index) {
          final workoutSet = exercisesToPerform[index];
          final isCurrent = index == currentOverallSetIndex;
          return Card(
            color: isCurrent ? Colors.blue.shade100 : null,
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: ListTile(
              leading: isCurrent
                  ? const Icon(Icons.arrow_right, color: Colors.blueAccent, size: 30)
                  : null,
              title: Text(
                workoutSet.isRestSet
                    ? (workoutSet.isRestBlock ? 'Rest Block' : 'Rest')
                    : workoutSet.exercise.name,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? Colors.blueAccent : Colors.black,
                  fontSize: 20,
                ),
              ),
              subtitle: workoutSet.isRestSet
                  ? Text(
                      'Duration: ${workoutSet.isRestBlock ? workoutSet.restBlockDuration : (workoutSet.exercise.restTimeInSeconds ?? 0)} seconds',
                      style: TextStyle(
                        color: isCurrent ? Colors.blueAccent : Colors.grey[600],
                        fontSize: 16,
                      ),
                    )
                  : Text(
                      'Set: ${workoutSet.setNumber} / ${workoutSet.exercise.sets}${workoutSet.exercise.reps != null ? ', Reps: ${workoutSet.exercise.reps}' : ''}'
                      ' | Work: ${workoutSet.exercise.workTimeInSeconds}s',
                      style: TextStyle(
                        color: isCurrent ? Colors.blueAccent : Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
              trailing: isCurrent
                  ? StreamBuilder<int>(
                      stream: currentIntervalTimeRemainingStream,
                      initialData: workoutSet.isRestSet
                          ? (workoutSet.isRestBlock ? workoutSet.restBlockDuration! : (workoutSet.exercise.restTimeInSeconds ?? 0)) * 1000
                          : workoutSet.exercise.workTimeInSeconds * 1000,
                      builder: (context, snapshot) {
                        final int timeValue = snapshot.data ?? 0;
                        return Text(
                          StopWatchTimer.getDisplayTime(
                            timeValue,
                            hours: false,
                            minute: true,
                            second: true,
                            milliSecond: true,
                          ),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                            fontSize: 22,
                          ),
                        );
                      },
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
