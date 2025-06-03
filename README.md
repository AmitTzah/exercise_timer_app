# Exercise Timer App

A personal Android exercise timer app designed to manage alternating sets for different exercises within fixed time intervals. The app also stores workout summaries and allows users to set and track fitness goals.

## Core Functionality

### I. Workout Management & Timer Module

*   **Home Screen:**
    *   Displays a list of user-defined workouts.
    *   For each workout, users can:
        *   **Play Workout:** Initiates the timer for the selected workout.
        *   **Edit Workout:** Navigates to the Define Workout Screen to modify the workout.
        *   **Delete Workout:** Removes the workout after confirmation.
    *   Action: Floating action button to "Define New Workout".

*   **Define Workout Screen:**
    *   Users can create new workouts or edit existing ones.
    *   Input fields for:
        *   Workout Name.
        *   List of exercises (each with name and number of sets).
        *   Set Interval Time (seconds) between sets.
        *   **Alternate Sets Checkbox:** Toggles between sequential and alternating set progression.
    *   Displays: Calculated total workout duration.
    *   Action: "Save Workout" button.
    *   **Persistence:** User-defined workouts (including exercises, sets, and interval time) are saved using `Hive`.

*   **Workout Mode:**
    *   When "Start Workout" is pressed from the Home Screen, a timer begins, cycling through the exercises defined in the selected workout.
    *   **Sequential Sets (Default):** Completes all sets of one exercise before moving to the next.
    *   **Alternating Sets (If enabled):** Cycles through one set of each exercise before moving to the next set number for any exercise. For example, if you have Exercise A (3 sets) and Exercise B (2 sets), the order would be: A-Set1, B-Set1, A-Set2, B-Set2, A-Set3.
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

*   **Configurable Set Progression:** Users can choose between sequential or alternating sets.
*   **Fixed Interval Timing:** Each set within a defined time slot.
*   **Automated Audio Cues:** "next_set.mp3" for interval transitions, "session_complete.mp3" for session completion.
*   **Progress Tracking:** Displays relevant progress information for workouts and goals.
*   **Data Persistence:**
    *   User-defined Workouts, Workout Summaries & Goals: Local database (`Hive`).
    *   (Note: `shared_preferences` is no longer used for workout settings.)
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
