import 'package:audioplayers/audioplayers.dart';
import 'dart:async'; // Import for Completer
import 'package:flutter/foundation.dart'; // For debugPrint

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _playerCompleteSubscription;

  AudioService() {
    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      // This listener is here to ensure the stream is consumed,
      // but individual play methods will handle their own Completers.
    });
  }

  // Mapping from display name to actual WAV file name
  static const Map<String, String> _exerciseSoundMap = {
    'Pull-ups': 'Pull-ups.wav',
    'Dips': 'Dips.wav',
    'Squats': 'Squats.wav',
    'One-legged Squats': 'One-legged-squats.wav',
    'Push-ups': 'Push-ups.wav',
    'Sit-ups': 'Sit-ups.wav',
    'Lunges': 'Lunges.wav',
    'Crunches': 'Crunches.wav',
    'Bench Press': 'Bench-Press.wav',
    'Deadlift': 'Deadlift.wav',
    'Muscle-Ups': 'Muscle-Ups.wav',
    'Handstand Push-Ups': 'Handstand Push-Ups.wav',
  };

  Future<void> playNextSetSound() async {
    final completer = Completer<void>();
    StreamSubscription? tempSubscription;

    tempSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      if (!completer.isCompleted) {
        completer.complete();
        tempSubscription?.cancel();
      }
    });

    await _audioPlayer.play(AssetSource('sounds/Next-Set.wav'));
    return completer.future;
  }

  Future<void> playExerciseAnnouncement(String exerciseDisplayName) async {
    final String? fileName = _exerciseSoundMap[exerciseDisplayName];
    if (fileName == null) {
      debugPrint('Error: Sound file not found for exercise: $exerciseDisplayName');
      return;
    }

    // Play "Next Set" sound first
    await playNextSetSound();

    // Then play the exercise specific sound
    final completer = Completer<void>();
    StreamSubscription? tempSubscription;

    tempSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      if (!completer.isCompleted) {
        completer.complete();
        tempSubscription?.cancel();
      }
    });

    await _audioPlayer.play(AssetSource('sounds/$fileName'));
    return completer.future;
  }

  Future<void> playSessionComplete() async {
    final completer = Completer<void>();
    StreamSubscription? tempSubscription;

    tempSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      if (!completer.isCompleted) {
        completer.complete();
        tempSubscription?.cancel();
      }
    });

    await _audioPlayer.play(AssetSource('sounds/workout_complete.wav'));
    return completer.future;
  }

  Future<void> playWorkoutStartedSound() async {
    final completer = Completer<void>();
    StreamSubscription? tempSubscription;

    tempSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      if (!completer.isCompleted) {
        completer.complete();
        tempSubscription?.cancel();
      }
    });

    await _audioPlayer.play(AssetSource('sounds/workout_started.wav'));
    return completer.future;
  }

  Future<void> playJustExerciseSound(String exerciseDisplayName) async {
    final String? fileName = _exerciseSoundMap[exerciseDisplayName];
    if (fileName == null) {
      debugPrint('Error: Sound file not found for exercise: $exerciseDisplayName');
      return;
    }

    final completer = Completer<void>();
    StreamSubscription? tempSubscription;

    tempSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      if (!completer.isCompleted) {
        completer.complete();
        tempSubscription?.cancel();
      }
    });

    await _audioPlayer.play(AssetSource('sounds/$fileName'));
    return completer.future;
  }

  void dispose() {
    _playerCompleteSubscription?.cancel(); // Cancel the main subscription
    _audioPlayer.stop(); // Stop any ongoing playback
    _audioPlayer.dispose();
  }
}
