import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_projects/view/tutor/features/Instant_tutoring/expiret_tutoring_screen.dart';
import 'package:flutter_projects/view/tutor/features/home/providers/tutor_home_provider.dart';
import 'package:provider/provider.dart';

class TemporizadorCuentaRegresiva extends StatefulWidget {
  final int segundosIniciales;

  const TemporizadorCuentaRegresiva({
    Key? key,
    this.segundosIniciales = 300, 
  }) : super(key: key);

  @override
  State<TemporizadorCuentaRegresiva> createState() =>
      _TemporizadorCuentaRegresivaState();
}

class _TemporizadorCuentaRegresivaState
    extends State<TemporizadorCuentaRegresiva> {
  int _segundosRestantes = 300;
  Timer? _timer;
  DateTime? _lastStartTime;

  @override
  void initState() {
    super.initState();
    _iniciarTemporizador();
  }

  void _syncWithProvider() {
    final homeProvider = Provider.of<TutorHomeProvider>(context, listen: false);
    final startTime = homeProvider.tutoringTimerStartTime ?? homeProvider.confirmationStartTime;

    if (startTime != null && startTime != _lastStartTime) {
      _lastStartTime = startTime;
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      _segundosRestantes = widget.segundosIniciales - elapsed;
      if (_segundosRestantes < 0) _segundosRestantes = 0;
    }
  }

  void _iniciarTemporizador() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      // Sincronizamos en cada tick por si acaso hubo un cambio global
      final homeProvider = Provider.of<TutorHomeProvider>(context, listen: false);
      final startTime = homeProvider.tutoringTimerStartTime ?? homeProvider.confirmationStartTime;
      
      if (startTime != null) {
        if (startTime != _lastStartTime) {
          // Ha ocurrido un reset global
          _lastStartTime = startTime;
          final elapsed = DateTime.now().difference(startTime).inSeconds;
          _segundosRestantes = widget.segundosIniciales - elapsed;
        } else {
          // Descontamos normal si no ha cambiado el inicio
          if (_segundosRestantes > 0) {
            _segundosRestantes--;
          }
        }
      } else {
        // Fallback si no hay tiempo global aún
        if (_segundosRestantes > 0) {
          _segundosRestantes--;
        }
      }

      if (_segundosRestantes <= 0) {
        _timer?.cancel();
        _redigirAExpirado();
      } else {
        setState(() {});
      }
    });
  }

  void _redigirAExpirado() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const VistaSolicitudExpirada(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _tiempoFormateado {
    int minutos = _segundosRestantes ~/ 60;
    int segundos = _segundosRestantes % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos al provider para detectar resets instantáneos
    return Consumer<TutorHomeProvider>(
      builder: (context, provider, child) {
        // Forzamos la sincronización si el Build ocurre por el Provider
        final startTime = provider.tutoringTimerStartTime ?? provider.confirmationStartTime;
        if (startTime != null && startTime != _lastStartTime) {
           _lastStartTime = startTime;
           final elapsed = DateTime.now().difference(startTime).inSeconds;
           _segundosRestantes = widget.segundosIniciales - elapsed;
           if (_segundosRestantes < 0) _segundosRestantes = 0;
        }

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
      },
    );
  }
}
