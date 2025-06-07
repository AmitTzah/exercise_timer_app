import 'package:flutter/material.dart';
import 'package:exercise_timer_app/models/user_workout.dart';
import 'package:exercise_timer_app/repositories/user_workout_repository.dart';
import 'package:exercise_timer_app/screens/define_workout_screen.dart';
import 'package:exercise_timer_app/screens/workout_screen.dart';
import 'package:provider/provider.dart';

class WorkoutCard extends StatefulWidget {
  final UserWorkout workout;
  final String Function(int, {bool includeHours}) formatTime;
  final Function(BuildContext, dynamic, UserWorkout) showLevelSelectionBottomSheet;
  final Function(String) deleteWorkout;
  final Map<String, bool> alternateModeSelections;
  final Map<String, int> levelSelections;
  final Map<String, bool> survivalModeSelections;
  final VoidCallback onSelectionsChanged; // Callback to notify parent of state changes

  const WorkoutCard({
    super.key,
    required this.workout,
    required this.formatTime,
    required this.showLevelSelectionBottomSheet,
    required this.deleteWorkout,
    required this.alternateModeSelections,
    required this.levelSelections,
    required this.survivalModeSelections,
    required this.onSelectionsChanged,
  });

  @override
  State<WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<WorkoutCard> {
  late UserWorkoutRepository _userWorkoutRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userWorkoutRepository = Provider.of<UserWorkoutRepository>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Workout Name
            Text(
              widget.workout.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // 2. Workout Details Row
            Row(
              children: [
                Text('Total Time: ${widget.formatTime(widget.workout.totalWorkoutTime, includeHours: true)}'),
                const SizedBox(width: 16),
                Text('Interval Time: ${widget.formatTime(widget.workout.intervalTimeBetweenSets)}'),
              ],
            ),
            const SizedBox(height: 8),

            // 3. Exercises List
            Text(
              'Exercises:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            ...widget.workout.exercises.map(
              (e) => Text(
                '  - ${e.name} (${e.sets}${e.reps != null ? 'x${e.reps}' : ''})', // Display sets and reps
                style: const TextStyle(fontSize: 14.0),
              ),
            ),
            const SizedBox(height: 12),

            // 4. Controls Section
            // Alternate Sets Row
            Row(
              children: [
                Checkbox(
                  value: widget.alternateModeSelections[widget.workout.id] ?? false,
                  onChanged: (bool? newValue) async {
                    widget.alternateModeSelections[widget.workout.id] = newValue ?? false;
                    widget.workout.selectedAlternateSets = newValue ?? false;
                    await _userWorkoutRepository.saveUserWorkout(widget.workout);
                    widget.onSelectionsChanged(); // Notify parent
                  },
                ),
                const Text('Alternate Sets'),
              ],
            ),
            // Survival Mode Checkbox
            Row(
              children: [
                Checkbox(
                  value: widget.survivalModeSelections[widget.workout.id] ?? false,
                  onChanged: (bool? newValue) async {
                    widget.survivalModeSelections[widget.workout.id] = newValue ?? false;
                    widget.workout.selectedSurvivalMode = newValue ?? false;
                    await _userWorkoutRepository.saveUserWorkout(widget.workout);
                    widget.onSelectionsChanged(); // Notify parent
                  },
                ),
                const Text('Survival Mode'),
              ],
            ),
            // Level Selection Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final int? selectedValue = await widget.showLevelSelectionBottomSheet(
                        context,
                        widget.levelSelections[widget.workout.id] ?? 1,
                        widget.workout,
                      );
                      if (selectedValue != null) {
                        widget.levelSelections[widget.workout.id] = selectedValue;
                        widget.workout.selectedLevel = selectedValue;
                        await _userWorkoutRepository.saveUserWorkout(widget.workout);
                        widget.onSelectionsChanged(); // Notify parent
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Level: L${widget.levelSelections[widget.workout.id] ?? 1} (+${((widget.levelSelections[widget.workout.id] ?? 1) == 1 ? 0 : (((((widget.levelSelections[widget.workout.id] ?? 1) - 1) * 20))))}%)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 5. Action Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Start"),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => WorkoutScreen(
                          workout: widget.workout,
                          isAlternateMode: widget.alternateModeSelections[widget.workout.id] ?? false,
                          selectedLevelOrMode: widget.survivalModeSelections[widget.workout.id] == true
                              ? "survival"
                              : (widget.levelSelections[widget.workout.id] ?? 1),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit"),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DefineWorkoutScreen(workout: widget.workout),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text("Delete"),
                  onPressed: () => widget.deleteWorkout(widget.workout.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
