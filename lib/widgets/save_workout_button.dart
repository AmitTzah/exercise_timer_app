import 'package:flutter/material.dart';

class SaveWorkoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SaveWorkoutButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
      ),
      child: const Text(
        'Save Workout',
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}
