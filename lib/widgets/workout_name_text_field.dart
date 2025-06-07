import 'package:flutter/material.dart';

class WorkoutNameTextField extends StatelessWidget {
  final TextEditingController controller;

  const WorkoutNameTextField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
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
