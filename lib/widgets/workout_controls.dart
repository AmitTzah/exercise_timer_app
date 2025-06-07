import 'package:flutter/material.dart';

class WorkoutControls extends StatelessWidget {
  final bool isPaused;
  final VoidCallback onPauseResume;
  final VoidCallback onStop;

  const WorkoutControls({
    super.key,
    required this.isPaused,
    required this.onPauseResume,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 20), // Keep spacing for buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: onPauseResume,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPaused ? Colors.green : Colors.orange,
                  minimumSize: const Size(150, 50),
                ),
                child: Text(
                  isPaused ? 'Resume Workout' : 'Pause Workout',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: onStop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(150, 50),
                ),
                child: const Text(
                  'Stop Workout',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
