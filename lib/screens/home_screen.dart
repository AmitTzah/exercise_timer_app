import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:exercise_timer_app/models/user_workout.dart';
import 'package:exercise_timer_app/repositories/user_workout_repository.dart'; // Use the new repository
import 'package:exercise_timer_app/screens/define_workout_screen.dart';
import 'package:exercise_timer_app/screens/workout_screen.dart';
import 'package:exercise_timer_app/screens/workout_summaries_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late UserWorkoutRepository _userWorkoutRepository;
  List<UserWorkout> _userWorkouts = [];
  final Map<String, bool> _alternateModeSelections = {};
  final Map<String, dynamic> _levelSelections = {}; // Stores int for level or "survival" string

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userWorkoutRepository = Provider.of<UserWorkoutRepository>(context);
    _userWorkoutRepository.listenable.addListener(_onWorkoutsChanged);
    _loadUserWorkouts(); // Initial load
  }

  @override
  void dispose() {
    _userWorkoutRepository.listenable.removeListener(_onWorkoutsChanged);
    super.dispose();
  }

  void _onWorkoutsChanged() {
    _loadUserWorkouts();
  }

  void _loadUserWorkouts() {
    final workouts = _userWorkoutRepository.getAllUserWorkouts();
    setState(() {
      _userWorkouts = workouts;
      // Initialize selections from persisted values, or default
      for (var workout in workouts) {
        _alternateModeSelections[workout.id] = workout.selectedAlternateSets ?? false;
        _levelSelections[workout.id] = workout.selectedLevel ?? 1;
      }
    });
  }

  Future<void> _deleteWorkout(String id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this workout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _userWorkoutRepository.deleteUserWorkout(id);
      // _loadUserWorkouts() will be called by the listener
    }
  }

  Future<dynamic> _showLevelSelectionBottomSheet(BuildContext context, dynamic currentLevel, UserWorkout workout) async {
    // Helper to calculate total sets for a given level, ensuring strict increase
    int _calculateTotalSetsForLevel(int level) {
      int totalOriginalSets = workout.exercises.fold(0, (sum, exercise) => sum + exercise.sets);
      if (totalOriginalSets == 0) return 0; // Handle empty workout

      double multiplier;
      if (level == 1) {
        multiplier = 1.0;
      } else {
        multiplier = 1.0 + ((level - 1) * 20) / 100.0; // Changed to 20% increment
      }

      int calculatedSets = (totalOriginalSets * multiplier).ceil();

      // Ensure strict increase for total sets compared to previous level
      if (level > 1) {
        int previousLevelSets = _calculateTotalSetsForLevel(level - 1); // Recursive call
        if (calculatedSets <= previousLevelSets) {
          calculatedSets = previousLevelSets + 1; // Force an increment
        }
      }
      return calculatedSets;
    }

    return showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select Workout Level',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (int i = 1; i <= 10; i++) // Changed to 10 levels
                      ListTile(
                        title: Text(
                          'Level $i (+${i == 1 ? 0 : ((i - 1) * 20)}%) - Total Sets: ${_calculateTotalSetsForLevel(i)}', // Updated percentage
                        ),
                        trailing: i == currentLevel ? const Icon(Icons.check, color: Colors.blue) : null,
                        onTap: () {
                          Navigator.pop(context, i);
                        },
                      ),
                    ListTile(
                      title: const Text('Survival Mode'),
                      trailing: currentLevel == "survival" ? const Icon(Icons.check, color: Colors.blue) : null,
                      onTap: () {
                        Navigator.pop(context, "survival");
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Workouts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WorkoutSummariesScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _userWorkouts.isEmpty
          ? const Center(
              child: Text(
                'No workouts defined yet. Tap the + button to create one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _userWorkouts.length,
              itemBuilder: (context, index) {
                final workout = _userWorkouts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Workout Name
                        Text(
                          workout.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        // 2. Workout Details Row
                        Row(
                          children: [
                            Text('Total Time: ${workout.totalWorkoutTime}s'),
                            const SizedBox(width: 16),
                            Text('Interval Time: ${workout.intervalTimeBetweenSets}s'),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // 3. Exercises List
                        Text(
                          'Exercises:',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        ...workout.exercises.map(
                          (e) => Text(
                            '  - ${e.name} (${e.sets})',
                            style: const TextStyle(fontSize: 14.0),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 4. Controls Section
                        // Alternate Sets Row
                        Row(
                          children: [
                            Checkbox(
                              value: _alternateModeSelections[workout.id] ?? false,
                              onChanged: (bool? newValue) async {
                                setState(() {
                                  _alternateModeSelections[workout.id] = newValue ?? false;
                                });
                                // Persist the change
                                workout.selectedAlternateSets = newValue ?? false;
                                await _userWorkoutRepository.saveUserWorkout(workout);
                              },
                            ),
                            const Text('Alternate Sets'),
                          ],
                        ),
                        // Level Selection Row
                        Row(
                          children: [
                            Expanded( // Expanded to take available space
                              child: InkWell(
                                onTap: () async {
                                  final dynamic selectedValue = await _showLevelSelectionBottomSheet(
                                    context,
                                    _levelSelections[workout.id] ?? 1,
                                    workout, // Pass the workout object
                                  );
                                  if (selectedValue != null) {
                                    setState(() {
                                      _levelSelections[workout.id] = selectedValue;
                                    });
                                    // Persist the change
                                    workout.selectedLevel = selectedValue is int ? selectedValue : null; // Save int or null for survival
                                    await _userWorkoutRepository.saveUserWorkout(workout);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Row( // New Row inside Container
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // To push text and potential icon apart
                                    children: [
                                      Text( // Combined text
                                        _levelSelections[workout.id] == "survival"
                                            ? 'Level: Survival' // Add "Level:" here
                                            : 'Level: L${_levelSelections[workout.id] ?? 1} (+${((_levelSelections[workout.id] ?? 1) == 1 ? 0 : ((((_levelSelections[workout.id] ?? 1) - 1) * 20)))}%)', // Updated percentage
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      // Optionally, re-add a subtle icon here if desired, e.g., Icons.unfold_more
                                      // For now, let's keep it without an icon as per previous feedback.
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
                          mainAxisAlignment: MainAxisAlignment.center, // Center the buttons
                          children: [
                            ElevatedButton.icon( // Play button
                              icon: const Icon(Icons.play_arrow),
                              label: const Text("Play"),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => WorkoutScreen(
                                      workout: workout,
                                      isAlternateMode: _alternateModeSelections[workout.id] ?? false,
                                      selectedLevelOrMode: _levelSelections[workout.id] ?? 1,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon( // Edit button (changed from TextButton.icon)
                              icon: const Icon(Icons.edit),
                              label: const Text("Edit"),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => DefineWorkoutScreen(workout: workout),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon( // Delete button (changed from TextButton.icon)
                              icon: const Icon(Icons.delete),
                              label: const Text("Delete"),
                              onPressed: () => _deleteWorkout(workout.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const DefineWorkoutScreen(),
            ),
          ); // No need to refresh explicitly, listener handles it
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
