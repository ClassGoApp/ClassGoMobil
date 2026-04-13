import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // NUEVO: Importamos el paquete

class VistaTutoriaLista extends StatelessWidget {
  final String meetLink;

  const VistaTutoriaLista({
    Key? key,
    required this.meetLink,
  }) : super(key: key);

  // NUEVO: Función para abrir el enlace
  Future<void> _abrirEnlace(BuildContext context) async {
    final Uri url = Uri.parse(meetLink);

    try {
      // LaunchMode.externalApplication fuerza a que salga de tu app
      // y abra Google Meet o el navegador externo. (Obligatorio para videollamadas
      // por los permisos de cámara y micrófono).
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('No se pudo abrir el enlace');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al abrir el aula. Verifica el enlace.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                  _construirIconoExito(),
                  const SizedBox(height: 24),
                  _construirTextosPrincipales(),
                  const SizedBox(height: 30),
                  _construirTarjetaAccion(context), // PASAMOS EL CONTEXTO AQUÍ
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- MÉTODOS PRIVADOS ---

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

  Widget _construirIconoExito() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF1E6),
        shape: BoxShape.circle,
      ),
      child: Container(
        padding: const EdgeInsets.all(35),
        decoration: const BoxDecoration(
          color: Color(0xFFE8F4EC),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          size: 60,
          color: Color(0xFF1E8E3E),
        ),
      ),
    );
  }

  Widget _construirTextosPrincipales() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: const [
          Text(
            'Tutoría lista',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF003049),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'El estudiante ya completó el\nproceso. Puedes iniciar la clase\nahora mismo.',
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

  // NUEVO: Ahora recibe el context para poder mostrar el SnackBar de error si falla
  Widget _construirTarjetaAccion(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00445E),
            Color(0xFF26A2B8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.web_asset,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'CLASE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Lista para iniciar',
                    style: TextStyle(
                      color: Color(0xFF2EFEA5),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // NUEVO: Llamamos a nuestra función de abrir el enlace
              onPressed: () => _abrirEnlace(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF003049),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Entrar al Aula',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
