import 'package:flutter/material.dart';

class IntervalAndRestSection extends StatelessWidget {
  final TextEditingController intervalTimeController;
  final int intervalTime;
  final ValueChanged<String> onIntervalTimeChanged;
  final bool enableRest;
  final ValueChanged<bool> onEnableRestChanged;
  final TextEditingController restDurationController;
  final int restDurationInSeconds;
  final ValueChanged<String> onRestDurationChanged;

  const IntervalAndRestSection({
    super.key,
    required this.intervalTimeController,
    required this.intervalTime,
    required this.onIntervalTimeChanged,
    required this.enableRest,
    required this.onEnableRestChanged,
    required this.restDurationController,
    required this.restDurationInSeconds,
    required this.onRestDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: intervalTimeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Set Interval Time (seconds)',
            hintText: 'e.g., 60',
          ),
          validator: (value) {
            if (value == null ||
                int.tryParse(value) == null ||
                int.parse(value) <= 0) {
              return 'Please enter a valid interval time (seconds).';
            }
            return null;
          },
          onChanged: onIntervalTimeChanged,
        ),
        const SizedBox(height: 20), // Added space for new rest options
        SwitchListTile(
          title: const Text('Include Rest Periods'),
          value: enableRest,
          onChanged: onEnableRestChanged,
        ),
        if (enableRest) // Conditionally display rest duration input
          TextFormField(
            controller: restDurationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Rest Duration (seconds)',
              hintText: 'e.g., 30',
            ),
            validator: (value) {
              if (enableRest && (value == null || int.tryParse(value) == null || int.parse(value) <= 0)) {
                return 'Please enter a valid rest duration (seconds).';
              }
              return null;
            },
            onChanged: onRestDurationChanged,
          ),
        const SizedBox(height: 10), // Reduced space
      ],
    );
  }
}
