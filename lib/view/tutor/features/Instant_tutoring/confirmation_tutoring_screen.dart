import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/view/tutor/features/Instant_tutoring/expiret_tutoring_screen.dart';
import 'package:flutter_projects/view/tutor/features/Instant_tutoring/reject_tutoting_screen.dart';
import 'package:flutter_projects/view/tutor/features/Instant_tutoring/view_wait_tutoring_screen.dart';
import 'package:flutter_projects/view/tutor/features/Instant_tutoring/widget/lupa_animada.dart';
import 'package:flutter_projects/view/tutor/features/Instant_tutoring/widget/sincronizacion_animada.dart';
import 'package:flutter_projects/view/tutor/features/Instant_tutoring/widget/temporizador_cuenta_regresiva.dart';

class VistaConfirmacion extends StatefulWidget {
  const VistaConfirmacion({Key? key}) : super(key: key);

  @override
  State<VistaConfirmacion> createState() => _VistaConfirmacionState();
}

class _VistaConfirmacionState extends State<VistaConfirmacion> {
  StreamSubscription<RemoteMessage>? _messageSub;
  bool _yaRedirigio = false;

  @override
  void initState() {
    super.initState();
    _escucharNotificaciones();
  }

  void _escucharNotificaciones() {
    _messageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final data = message.data;

      if (!mounted || _yaRedirigio) return;

      if (data['screen'] == 'tutor_rechazado') {
        _yaRedirigio = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const VistaOtroTutor(), // Asegúrate de tener este import
          ),
        );
      } else if (data['screen'] == 'tutor_expirado') {
        _yaRedirigio = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const VistaSolicitudExpirada(), // Asegúrate de tener este import
          ),
        );
      } else if (data['screen'] == 'tutor_aceptado') {
        _yaRedirigio = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                VistaFuisteElegido(), // Crea esta pantalla si no existe
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _construirEncabezado(),
                  const SizedBox(height: 40),

                  // ¡Aquí usamos nuestros nuevos widgets separados!
                  const LupaAnimada(),

                  const SizedBox(height: 24),
                  _construirTextosPrincipales(),
                  const SizedBox(height: 30),

                  // ¡Nuestro indicador giratorio!
                  const SincronizacionAnimada(),

                  const SizedBox(height: 40),

                  // Se le pasa 300 segundos (05:00)
                  const TemporizadorCuentaRegresiva(segundosIniciales: 300),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- MÉTODOS PRIVADOS QUE MANTUVIMOS ---

  Widget _construirEncabezado() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF00445E),
            Color(0xFF26A2B8),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: const [
          Icon(Icons.check_circle, color: Colors.white, size: 20),
          SizedBox(width: 10),
          Text(
            'TUTORÍA AL INSTANTE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTextosPrincipales() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          Text(
            'Buscando\nconfirmación',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF003049),
              height: 1.2,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'El estudiante está revisando tu perfil.\nPor favor, mantente en línea para\nrecibir el pago.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF7A8B99),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
