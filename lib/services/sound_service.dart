import 'package:audioplayers/audioplayers.dart';

class SoundService {
  // Las variables de control ahora viven aquí, protegidas.
  static DateTime? _lastSoundPlayed;
  static String? _lastSoundStatus;
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> playStatusChangeSound([String? status]) async {
    try {
      final now = DateTime.now();

      // Lógica de protección contra duplicados
      if (_lastSoundPlayed != null &&
          now.difference(_lastSoundPlayed!).inSeconds < 2 &&
          _lastSoundStatus == status) {
        return;
      }

      await _audioPlayer.play(AssetSource('sounds/cambioEstado.mp3'));

      _lastSoundPlayed = now;
      _lastSoundStatus = status;
    } catch (e) {
      print('❌ Error en SoundService: $e');
    }
  }
}