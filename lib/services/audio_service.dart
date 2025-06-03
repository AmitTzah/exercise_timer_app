import 'package:audioplayers/audioplayers.dart';
import 'dart:async'; // Import for Completer

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _playerCompleteSubscription;

  AudioService() {
    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      // This listener is here to ensure the stream is consumed,
      // but individual play methods will handle their own Completers.
    });
  }

  Future<void> playNextSet() async {
    final completer = Completer<void>();
    StreamSubscription? tempSubscription;

    tempSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      if (!completer.isCompleted) {
        completer.complete();
        tempSubscription?.cancel(); // Cancel this specific listener
      }
    });

    await _audioPlayer.play(AssetSource('sounds/next_set.mp3'));
    return completer.future;
  }

  Future<void> playSessionComplete() async {
    final completer = Completer<void>();
    StreamSubscription? tempSubscription;

    tempSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      if (!completer.isCompleted) {
        completer.complete();
        tempSubscription?.cancel(); // Cancel this specific listener
      }
    });

    await _audioPlayer.play(AssetSource('sounds/session_complete.mp3'));
    return completer.future;
  }

  void dispose() {
    _playerCompleteSubscription?.cancel(); // Cancel the main subscription
    _audioPlayer.stop(); // Stop any ongoing playback
    _audioPlayer.dispose();
  }
}
