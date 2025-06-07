import 'package:flutter/material.dart';

class WorkoutNameTextField extends StatelessWidget {
  final TextEditingController controller;
  // Removed: final FocusNode? focusNode;

  const WorkoutNameTextField({
    super.key,
    required this.controller,
    // Removed: this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      // Removed: focusNode: focusNode,
      keyboardType: TextInputType.text, // Explicitly set keyboard type
      decoration: const InputDecoration(
        labelText: 'Workout Name',
        hintText: 'e.g., Full Body Blast',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a workout name.';
        }
        return null;
      },
    );
  }
}
