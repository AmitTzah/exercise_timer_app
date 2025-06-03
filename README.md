# Exercise Timer App

A personal Android exercise timer app designed to manage alternating sets for different exercises within fixed time intervals. The app also stores workout summaries and allows users to set and track fitness goals.

## Core Functionality

### I. Workout Timer Module

*   **Setup Screen:**
    *   Users can input:
        *   List of exercises (e.g., "Pullups, Dips, Squats").
        *   Number of sets desired for each exercise.
        *   Interval Time (in seconds): Fixed duration for one set and immediate rest/transition.
    *   Displays: Calculated total workout duration.
    *   Action: "Start Workout" button.
    *   **Persistence:** These settings (exercises, sets, interval time) are saved for future use using `shared_preferences`.

*   **Workout Mode:**
    *   When "Start" is pressed, a timer begins, cycling through the specified exercises, one set at a time.
    *   The app emits a "next_set.mp3" sound at the end of each interval, signaling the end of the current interval and the immediate start of the next exercise's set.
    *   **Display during workout:**
        *   Current exercise to perform.
        *   Current set number for that exercise (e.g., "Pullups: Set 3/10").
        *   Overall progress (e.g., "Total Set: 7/30").
        *   Time counting down within the current Interval Time.
    *   **Pause Workout button:** Pauses and resumes the timer.
    *   **Finish Workout button:** Prompts a confirmation dialog. If confirmed, navigates to the new Workout Summary Display Screen.
    *   Upon natural completion of all sets:
        *   An automated voice announces "session_complete.mp3".
        *   The app navigates to the Workout Summary Display Screen.

### II. Data & Progress Module

*   **Workout Summary Display Screen:**
    *   A new screen that displays the details of a completed or ended workout (date, exercises, total duration).
    *   Provides explicit "Save Workout" and "Discard Workout" buttons.
    *   If "Save Workout" is pressed, the summary is stored using Hive.

*   **Workout Summaries Screen:**
    *   Displays a list or history of completed workouts.
    *   Each entry shows key details (e.g., date, exercises, duration).
    *   Ability to view details of a specific past workout.
    *   **Data Storage:** Workout summaries are stored using Hive.

*   **Goals Screen (Optional but desired future feature):**
    *   Allows users to define personal fitness goals (e.g., "Complete 100 pullups this month," "Workout 3 times a week").
    *   Mechanism to track progress towards these goals (manual input or potentially derived from workout summaries).
    *   Displays progress for each goal.
    *   **Data Storage:** Goals are stored using Hive.

## Key App-wide Features

*   **Alternating Sets Timer:** Core workout mechanism.
*   **Fixed Interval Timing:** Each set within a defined time slot.
*   **Automated Audio Cues:** "next_set.mp3" for interval transitions, "session_complete.mp3" for session completion.
*   **Progress Tracking:** Displays relevant progress information for workouts and goals.
*   **Data Persistence:**
    *   Settings: `shared_preferences`.
    *   Workout Summaries & Goals: Local database (`Hive`).
*   **User Interface:** Clear, simple, and intuitive.
*   **Target Platform:** Android (version 9 or newer).
*   **Development Environment:** Flutter with VS Code.

## Getting Started

This project is a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
