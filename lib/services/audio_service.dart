import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playNextSet() async {
    await _audioPlayer.play(AssetSource('sounds/next_set.mp3'));
  }

  Future<void> playSessionComplete() async {
    await _audioPlayer.play(AssetSource('sounds/session_complete.mp3'));
  }

  void dispose() {
    _audioPlayer.stop(); // Stop any ongoing playback
    _audioPlayer.dispose();
  }
}
