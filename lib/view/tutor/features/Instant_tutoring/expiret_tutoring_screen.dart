import 'package:flutter/material.dart';
import 'package:flutter_projects/view/tutor/dashboard_tutor.dart';

class VistaSolicitudExpirada extends StatelessWidget {
  const VistaSolicitudExpirada({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF0F2F5), // Mismo fondo de las vistas anteriores
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
                  _construirIconoExpirado(),
                  const SizedBox(height: 24),
                  _construirTextosPrincipales(),
                  const SizedBox(height: 30),
                  _construirBotonVolver(context),
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

  /// Construye el círculo con la 'X' roja
  Widget _construirIconoExpirado() {
    return Container(
      padding: const EdgeInsets.all(6), // Borde exterior muy suave
      decoration: const BoxDecoration(
        color: Color(0xFFFEE2E2), // Rojo muy claro / rosado
        shape: BoxShape.circle,
      ),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          color: Color(0xFFFEE2E2),
          shape: BoxShape.circle,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFEF4444), // Rojo intenso
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(10),
          child: const Icon(
            Icons.close_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Construye el título y el párrafo explicativo
  Widget _construirTextosPrincipales() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: const [
          Text(
            'La solicitud ya\nexpiró',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color:
                  Color(0xFFEF4444), // Texto rojo haciendo juego con el ícono
              height: 1.2,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'El estudiante dejó de buscar tutor. Si\nvuelve a solicitar, te llegará otra\ninvitación.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF7A8B99), // Gris azulado para la descripción
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el botón secundario para volver al inicio
  Widget _construirBotonVolver(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardTutor(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF1F5F9), // Gris/azulado muy claro
            foregroundColor: const Color(0xFF003049), // Texto oscuro
            elevation: 0, // Sin sombra para que se vea como un botón secundario
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Volver al Inicio',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
