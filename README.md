# Exercise Timer App

A personal Android exercise timer app designed to manage alternating sets for different exercises within fixed time intervals. The app also stores workout summaries and allows users to set and track fitness goals.

## Core Functionality

### I. Workout Management & Timer Module

*   **Home Screen:**
    *   Displays a list of user-defined workouts.
    *   For each workout, users can:
        *   **Play Workout:** Initiates the timer for the selected workout.
            *   **Alternate Sets Checkbox:** Toggles between sequential and alternating set progression for the current session.
            *   **Workout Level Selection:** Choose a difficulty level from 1 to 10. Level 1 uses the base sets defined in the workout. Levels 2-10 increase the number of sets for each exercise by a percentage (Level 2: +20%, Level 3: +40%, ..., Level 10: +180%). The adjusted total set count for the workout is **rounded up** after the percentage increase. To ensure a distinct progression, if the calculated total sets for a level would be the same as or less than the previous level's total sets due to rounding, the current level's total sets are forced to be one greater than the previous level's. These total sets are then proportionally distributed among the exercises, with individual exercise sets rounded to the nearest integer.
            *   **Survival Mode:** An option to start an endless workout session. The timer counts up, and the program repeats itself endlessly, challenging the user to survive the longest.
        *   **Edit Workout:** Navigates to the Define Workout Screen to modify the workout.
        *   **Delete Workout:** Removes the workout after confirmation.
    *   Action: Floating action button to "Define New Workout".

*   **Define Workout Screen:**
    *   Users can create new workouts or edit existing ones.
*   Input fields for:
        *   Workout Name.
        *   List of exercises (users select from a predefined list of exercise names, each with number of sets, and optional number of reps).
        *   Set Interval Time (seconds) between sets.
    *   **Include Rest Periods:** A toggle to enable or disable rest periods between exercises.
    *   **Rest Duration (seconds):** If rest periods are enabled, users can specify the duration of each rest period.
    *   **Reorder Exercises:** Users can reorder exercises using a drag-and-drop interface.
    *   **Edit Exercises:** Users can edit the sets and reps of an exercise after it has been added to the workout.
    *   Displays: Calculated total workout duration.
    *   Action: "Save Workout" button.
    *   **Persistence:** User-defined workouts (including exercises, sets, and interval time) are saved using `Hive`.

*   **Workout Mode:**
    *   When "Start Workout" is pressed from the Home Screen, a timer begins, cycling through the exercises defined in the selected workout, adjusted by the chosen level.
    *   **Sequential Sets (Default):** Completes all sets of one exercise before moving to the next.
    *   **Alternating Sets (If enabled):** Cycles through one set of each exercise before moving to the next set number for any exercise. For example, if you have Exercise A (3 sets) and Exercise B (2 sets), the order would be: A-Set1, B-Set1, A-Set2, B-Set2, A-Set3.
    *   **Workout Levels:** The total number of sets for each exercise is dynamically adjusted based on the selected level (1-10), ensuring a strictly increasing total set count across levels. The total set count is rounded up after the percentage increase.
    *   **Survival Mode:** The workout repeats indefinitely. The main timer displays elapsed time (counts up) instead of time remaining. The session ends only when the user manually presses "Finish Workout".
*   The app emits a "workout_started.wav" sound at the beginning of each workout.
*   The app emits a "Next-Set.wav" sound at the end of each interval, immediately followed by the `exercise_name.wav` sound for the upcoming exercise, signaling the end of the current interval and the immediate start of the next exercise's set.
    *   **Display during workout:**
        *   Current exercise to perform.
        *   Current set number for that exercise (e.g., "Pullups: Set 3/10, Reps: 12").
        *   Overall progress (e.g., "Total Sets: 7/30").
        *   Time counting down within the current Interval Time (or counting up in Survival Mode).
    *   **Pause Workout button:** Pauses and resumes the timer.
    *   **Stop Workout button:** Prompts a confirmation dialog. If confirmed, navigates to the new Workout Summary Display Screen. The summary will reflect the exercises actually performed up to the point of stopping and the total time elapsed.
    *   Upon natural completion of all sets (not applicable in Survival Mode):
        *   An automated voice announces "workout_complete.wav".
        *   The app navigates to the Workout Summary Display Screen.

### II. Data & Progress Module

*   **Workout Summary Display Screen:**
    *   A new screen that displays comprehensive details of a completed or ended workout, including workout name, date, total duration, workout level, set progression mode (alternating/sequential), interval time, and a detailed list of individual sets performed.
    *   Indicates if the workout was completed naturally or stopped prematurely.
    *   Provides explicit "Save Workout" and "Discard Workout" buttons.
    *   If "Save Workout" is pressed, the summary is stored using Hive.

*   **Workout Summaries Screen:**
    *   Displays a history of completed workouts in an enhanced, sortable list (newest first).
    *   Each entry shows key details (workout name, date, duration, level, mode, interval, and completion status).
    *   Users can expand each entry to view a detailed list of individual sets performed.
    *   **Ability to delete individual workout summaries via a swipe-to-delete gesture.**
    *   **Data Storage:** Workout summaries are stored using Hive.

*   **Goals Screen (Optional but desired future feature):**
    *   Allows users to define personal fitness goals (e.g., "Complete 100 pullups this month," "Workout 3 times a week").
    *   Mechanism to track progress towards these goals (manual input or potentially derived from workout summaries).
    *   Displays progress for each goal.
    *   **Data Storage:** Goals are stored using Hive.

## Key App-wide Features

*   **Configurable Set Progression:** Users can choose between sequential or alternating sets *per session*.
*   **Workout Levels & Survival Mode:** Dynamic adjustment of workout intensity and an endless challenge mode, with guaranteed distinct total sets per level.
*   **Fixed Interval Timing:** Each set within a defined time slot.
*   **Automated Audio Cues:** "Next-Set.wav" followed by `exercise_name.wav` for interval transitions, "workout_complete.wav" for session completion.
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
