import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_projects/view/auth/email_verification_screen.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';

class SimpleDeepLinkHandler {
  /// Maneja los deep links de verificación de forma simple
  static Future<void> handleVerificationLink(
      BuildContext context, String link) async {
    try {
      print('SimpleDeepLinkHandler: procesando link: $link');
      final uri = Uri.parse(link);

      // Debug: imprimir todos los componentes del URI
      print('SimpleDeepLinkHandler: URI parseado:');
      print('  - scheme: ${uri.scheme}');
      print('  - host: ${uri.host}');
      print('  - path: ${uri.path}');
      print('  - queryParameters: ${uri.queryParameters}');

      // Manejar tanto el custom scheme como el dominio
      bool isVerificationLink = false;
      String? id, hash;

      // Custom scheme: classgo://verify?id=...&hash=...
      if (uri.scheme == 'classgo' &&
          (uri.host == 'verify' || uri.path == '/verify')) {
        isVerificationLink = true;
        id = uri.queryParameters['id'];
        hash = uri.queryParameters['hash'];
        print(
            'SimpleDeepLinkHandler: custom scheme detectado - id: $id, hash: $hash');
      }
      // Dominio: https://classgoapp.com/verify?id=...&hash=...
      else if (uri.host == 'classgoapp.com' && uri.path == '/verify') {
        isVerificationLink = true;
        id = uri.queryParameters['id'];
        hash = uri.queryParameters['hash'];
        print(
            'SimpleDeepLinkHandler: dominio detectado - id: $id, hash: $hash');
      }

      print('SimpleDeepLinkHandler: isVerificationLink = $isVerificationLink');
      print('SimpleDeepLinkHandler: id = $id, hash = $hash');

      if (isVerificationLink && id != null && hash != null) {
        print('SimpleDeepLinkHandler: navegando a EmailVerificationScreen');
        // Navegar a la pantalla de verificación
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              verificationId: id!,
              verificationHash: hash!,
            ),
          ),
          (Route<dynamic> route) => false,
        );
      } else {
        print('SimpleDeepLinkHandler: link no válido, navegando a LoginScreen');
        // En caso de error, ir al login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print('Error al manejar deep link: $e');
      // En caso de error, ir al login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  /// Abre el email del usuario para verificar
  static Future<void> openEmailApp() async {
    try {
      final url = Uri.parse('mailto:');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      print('Error al abrir app de email: $e');
    }
  }

  /// Abre un link en el navegador (para testing)
  static Future<void> openLinkInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error al abrir link en navegador: $e');
    }
  }
}
