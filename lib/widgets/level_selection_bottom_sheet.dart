import 'package:flutter/material.dart';
import 'package:exercise_timer_app/models/user_workout.dart';

class LevelSelectionBottomSheet {
  static Future<dynamic> show(BuildContext context, dynamic currentLevel, UserWorkout workout) async {
    // Helper to calculate total sets for a given level, ensuring strict increase
    int calculateTotalSetsForLevel(int level) {
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
        int previousLevelSets = calculateTotalSetsForLevel(level - 1); // Recursive call
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
                          'Level $i (+${i == 1 ? 0 : ((i - 1) * 20)}%) - Total Sets: ${calculateTotalSetsForLevel(i)}', // Updated percentage
                        ),
                        trailing: i == currentLevel ? const Icon(Icons.check, color: Colors.blue) : null,
                        onTap: () {
                          Navigator.pop(context, i);
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
}
