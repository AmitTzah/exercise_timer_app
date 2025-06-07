import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:exercise_timer_app/models/user_workout.dart';
import 'package:exercise_timer_app/repositories/user_workout_repository.dart'; // Use the new repository
import 'package:exercise_timer_app/screens/define_workout_screen.dart';
import 'package:exercise_timer_app/screens/workout_summaries_screen.dart';
import 'package:exercise_timer_app/widgets/workout_card.dart';
import 'package:exercise_timer_app/widgets/level_selection_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late UserWorkoutRepository _userWorkoutRepository;
  List<UserWorkout> _userWorkouts = [];
  final Map<String, int> _levelSelections = {}; // Stores int for level
  final Map<String, bool> _survivalModeSelections = {}; // Stores bool for survival mode

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
        _levelSelections[workout.id] = workout.selectedLevel ?? 1;
        _survivalModeSelections[workout.id] = workout.selectedSurvivalMode ?? false; // Initialize survival mode
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

  String _formatTime(int totalSeconds, {bool includeHours = false}) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    String formattedTime = '';
    if (includeHours && hours > 0) {
      formattedTime += '${hours}h ';
    }
    formattedTime += '${minutes}m ${seconds}s';
    return formattedTime.trim();
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
                return WorkoutCard(
                  workout: workout,
                  formatTime: _formatTime,
                  showLevelSelectionBottomSheet: LevelSelectionBottomSheet.show,
                  deleteWorkout: _deleteWorkout,
                  levelSelections: _levelSelections,
                  survivalModeSelections: _survivalModeSelections,
                  onSelectionsChanged: _onWorkoutsChanged, // Callback to trigger setState in parent
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
