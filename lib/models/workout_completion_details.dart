import 'package:exercise_timer_app/models/workout_set.dart';

class WorkoutCompletionDetails {
  final bool wasStoppedPrematurely;
  final List<WorkoutSet> finalPerformedSets;

  WorkoutCompletionDetails(this.wasStoppedPrematurely, this.finalPerformedSets);
}
