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
    setState(() {
      _userWorkouts = _userWorkoutRepository.getAllUserWorkouts();
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
                  child: ListTile(
                    title: Text(workout.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Time: ${workout.totalWorkoutTime}s'),
                        Text('Interval Time: ${workout.intervalTimeBetweenSets}s'),
                        ...workout.exercises.map(
                          (e) => Text(
                            '${e.name} (${e.sets})',
                            style: const TextStyle(fontSize: 14.0),
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_arrow, size: 40.0),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => WorkoutScreen(workout: workout),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => DefineWorkoutScreen(workout: workout),
                              ),
                            ); // No need to refresh explicitly, listener handles it
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteWorkout(workout.id),
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
