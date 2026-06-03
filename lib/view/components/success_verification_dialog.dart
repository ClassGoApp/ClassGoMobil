import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';

class SuccessVerificationDialog extends StatefulWidget {
  const SuccessVerificationDialog({Key? key}) : super(key: key);

  @override
  _SuccessVerificationDialogState createState() =>
      _SuccessVerificationDialogState();
}

class _SuccessVerificationDialogState extends State<SuccessVerificationDialog> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playSuccessSound();
  }

  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      // Ignorar error si no se puede reproducir
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset('assets/lottie/success.json',
                width: 80, height: 80, repeat: false),
            const SizedBox(height: 18),
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 18),
            Text(
              '¡Verificación exitosa!',
              style: TextStyle(
                color: Colors.green[800],
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Tu correo ha sido verificado correctamente.\nTe estamos redirigiendo...',
              style: TextStyle(color: Colors.black87, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
