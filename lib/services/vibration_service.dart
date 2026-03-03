import 'package:vibration/vibration.dart';

class VibrationService {
  static Future<void> vibrateForStatus(String status) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();

      if (hasVibrator ?? false) {
        final normalizedStatus = status.toLowerCase();
        
        switch (normalizedStatus) {
          case 'aceptada':
          case 'aceptado':
            await Vibration.vibrate(duration: 800);
            break;
          case 'rechazada':
          case 'rechazado':
            await Vibration.vibrate(duration: 300);
            break;
          case 'cursando':
            await Vibration.vibrate(pattern: [0, 400, 100, 400, 100, 400]);
            break;
          case 'pendiente':
            await Vibration.vibrate(duration: 200);
            break;
          default:
            await Vibration.vibrate(duration: 500);
        }
      }
    } catch (e) {
      print('❌ Error en VibrationService: $e');
    }
  }
}