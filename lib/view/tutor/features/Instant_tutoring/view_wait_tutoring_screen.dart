import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/view/tutor/features/Instant_tutoring/ready_tutoring_screen.dart';

class VistaFuisteElegido extends StatefulWidget {
  const VistaFuisteElegido({Key? key}) : super(key: key);

  @override
  State<VistaFuisteElegido> createState() => _VistaFuisteElegidoState();
}

class _VistaFuisteElegidoState extends State<VistaFuisteElegido> {
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
      String enlaceFinal = '';
      if (!mounted || _yaRedirigio) return;

      if (data['screen'] == 'tutoria_lista') {
        _yaRedirigio = true;
        try {
          var decodificado = data['data_tutor'];
          if (decodificado != null) {
            // 2. Si viene como texto, lo decodificamos
            if (decodificado is String) {
              decodificado = jsonDecode(decodificado);

              if (decodificado is String) {
                decodificado = jsonDecode(decodificado);
              }
            }
            if (decodificado is Map) {
              // Buscamos ambos nombres por si acaso
              enlaceFinal = decodificado['meet_link'] ??
                  decodificado['meeting_link'] ??
                  '';
            }
          }
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => VistaTutoriaLista(meetLink: enlaceFinal),
              ));
        } catch (e) {
          print('Error al parsear data_tutor: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _messageSub?.cancel(); // MUY IMPORTANTE: Detener la escucha al salir
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usamos el mismo fondo gris claro para mantener la consistencia
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
                  _construirIconoElegido(),
                  const SizedBox(height: 24),
                  _construirTextosPrincipales(),
                  const SizedBox(height: 30),
                  _construirIndicadorEspera(),
                  const SizedBox(height: 30), // Espacio final
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- MÉTODOS PRIVADOS ---

  /// Construye la franja superior azul con degradado
  Widget _construirEncabezado() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF00445E), // Azul oscuro
            Color(0xFF26A2B8), // Azul claro/cyan
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: const [
          Icon(Icons.health_and_safety_outlined, color: Colors.white, size: 20),
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

  /// Construye el círculo central con la caja naranja
  Widget _construirIconoElegido() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF3E0), // Naranja extra claro para el borde exterior
        shape: BoxShape.circle,
      ),
      child: Container(
        padding: const EdgeInsets.all(35),
        decoration: const BoxDecoration(
          color: Color(0xFFFFE0B2), // Naranja claro para el fondo interior
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.view_in_ar_rounded, // Ícono de caja 3D similar al diseño
          size: 60,
          color: Color(0xFFFF8C00), // Naranja intenso
        ),
      ),
    );
  }

  /// Construye el título y el párrafo descriptivo
  Widget _construirTextosPrincipales() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: const [
          Text(
            '¡Fuiste elegido!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF003049), // Azul muy oscuro de tu paleta
              height: 1.2,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'El estudiante está realizando el\npago. Mantente en linea, en breve\npodrás iniciar la tutoría.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF7A8B99), // Gris azulado
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la píldora inferior de estado "Esperando comprobante"
  Widget _construirIndicadorEspera() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5), // Un fondo beige casi blanco
        border: Border.all(
            color: const Color(0xFFFFE0B2), width: 1.5), // Borde naranja claro
        borderRadius: BorderRadius.circular(30), // Forma de píldora
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          // Pequeño indicador de carga naranja
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFFFF8C00),
            ),
          ),
          SizedBox(width: 16),
          // Texto descriptivo
          Text(
            'ESPERANDO\nCOMPROBANTE...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFFF8C00),
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
