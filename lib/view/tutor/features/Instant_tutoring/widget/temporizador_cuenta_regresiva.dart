import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_projects/view/tutor/features/Instant_tutoring/expiret_tutoring_screen.dart';

class TemporizadorCuentaRegresiva extends StatefulWidget {
  final int segundosIniciales;

  // Te permito pasarle los segundos iniciales por parámetro (ej. 87 = 01:27)
  const TemporizadorCuentaRegresiva({
    Key? key,
    this.segundosIniciales = 300, // Por defecto 5 minutos (300 segundos)
  }) : super(key: key);

  @override
  State<TemporizadorCuentaRegresiva> createState() =>
      _TemporizadorCuentaRegresivaState();
}

class _TemporizadorCuentaRegresivaState
    extends State<TemporizadorCuentaRegresiva> {
  late int _segundosRestantes;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _segundosRestantes = widget.segundosIniciales;
    _iniciarTemporizador();
  }

  void _iniciarTemporizador() {
    // Se ejecuta cada 1 segundo exacto
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_segundosRestantes > 0) {
        setState(() {
          _segundosRestantes--;
        });
      } else {
        _timer?.cancel(); // Se detiene cuando llega a 0
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const VistaSolicitudExpirada(), // Asegúrate de tener este import
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Limpiamos el timer al destruir la vista
    super.dispose();
  }

  // Pequeña fórmula para convertir segundos a formato MM:SS
  String get _tiempoFormateado {
    int minutos = _segundosRestantes ~/ 60;
    int segundos = _segundosRestantes % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Expira en: -',
          style: TextStyle(
            color: Color(0xFF4A4A4A),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Tiempo restante: ',
              style: TextStyle(
                color: Color(0xFF4A4A4A),
                fontSize: 14,
              ),
            ),
            Text(
              _tiempoFormateado,
              style: TextStyle(
                // Si el tiempo es menor a 10 segundos, lo ponemos en rojo para alertar
                color: _segundosRestantes <= 10
                    ? Colors.red
                    : const Color(0xFF1A1A1A),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
