import 'package:flutter/material.dart';
import 'package:exercise_timer_app/models/exercise.dart';
import 'package:exercise_timer_app/services/settings_service.dart';
import 'package:exercise_timer_app/screens/workout_screen.dart';
import 'package:exercise_timer_app/screens/workout_summaries_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final SettingsService _settingsService = SettingsService();
  List<Exercise> _exercises = [];
  int _intervalTime = 60; // Default to 60 seconds
  final TextEditingController _newExerciseNameController = TextEditingController();
  final TextEditingController _newExerciseSetsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _newExerciseNameController.dispose();
    _newExerciseSetsController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    _exercises = await _settingsService.loadExercises();
    _intervalTime = await _settingsService.loadIntervalTime();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _saveSettings() async {
    await _settingsService.saveExercises(_exercises);
    await _settingsService.saveIntervalTime(_intervalTime);
  }

  void _addExercise() {
    final String name = _newExerciseNameController.text.trim();
    final int? sets = int.tryParse(_newExerciseSetsController.text.trim());

    if (name.isNotEmpty && sets != null && sets > 0) {
      setState(() {
        _exercises.add(Exercise(name: name, sets: sets));
        _newExerciseNameController.clear();
        _newExerciseSetsController.clear();
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid exercise name and number of sets.')),
      );
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  int _calculateTotalDuration() {
    int totalSets = _exercises.fold(0, (sum, exercise) => sum + exercise.sets);
    return totalSets * _intervalTime;
  }

  void _startWorkout() async {
    if (_exercises.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one exercise.')),
      );
      return;
    }
    await _saveSettings();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutScreen(
          exercises: _exercises,
          intervalTime: _intervalTime,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Timer Setup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WorkoutSummariesScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _newExerciseNameController,
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
                hintText: 'e.g., Pullups',
              ),
            ),
            TextField(
              controller: _newExerciseSetsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of Sets',
                hintText: 'e.g., 3',
              ),
            ),
            ElevatedButton(
              onPressed: _addExercise,
              child: const Text('Add Exercise'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _exercises.length,
                itemBuilder: (context, index) {
                  final exercise = _exercises[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      title: Text(exercise.name),
                      subtitle: Text('Sets: ${exercise.sets}'), // Keep braces for expression
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeExercise(index),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Interval Time (seconds)',
                hintText: 'e.g., 60',
              ),
              controller: TextEditingController(text: '$_intervalTime'), // Remove braces for simple variable
              onChanged: (value) {
                setState(() {
                  _intervalTime = int.tryParse(value) ?? 60;
                });
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Total Workout Duration: ${_calculateTotalDuration()} seconds', // Keep braces for method call
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startWorkout,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50), // Make button wide
              ),
              child: const Text(
                'Start Workout',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
