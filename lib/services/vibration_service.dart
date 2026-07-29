import 'package:vibration/vibration.dart';
import 'package:flutter_projects/models/booking_status.dart';

class VibrationService {
  static Future<void> vibrateForStatus(String status) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();

      if (hasVibrator ?? false) {
        final bookingStatus = BookingStatus.fromString(status);
        switch (bookingStatus) {
          case BookingStatus.aceptado:
            await Vibration.vibrate(duration: 800);
            break;
          case BookingStatus.rechazado:
            await Vibration.vibrate(duration: 300);
            break;
          case BookingStatus.cursando:
            await Vibration.vibrate(pattern: [0, 400, 100, 400, 100, 400]);
            break;
          case BookingStatus.pendiente:
            await Vibration.vibrate(duration: 200);
            break;
          default:
            await Vibration.vibrate(duration: 500);
        }
      }
    } catch (e) {
      print('Error en VibrationService: $e');
    }
  }
}
