import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/auth/email_verification_screen.dart';
import 'package:flutter_projects/helpers/email_verification_helper.dart';

class DeepLinkHandler {
  static const String _baseUrl = 'https://classgoapp.com/verify';

  /// Maneja los deep links de verificación
  static Future<void> handleVerificationLink(
      BuildContext context, String link) async {
    try {
      final uri = Uri.parse(link);

      if (uri.host == 'classgoapp.com' && uri.path == '/verify') {
        final id = uri.queryParameters['id'];
        final hash = uri.queryParameters['hash'];

        if (id != null && hash != null) {
          // Navegar a la pantalla de verificación
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(
                verificationId: id,
                verificationHash: hash,
              ),
            ),
            (Route<dynamic> route) => false,
          );
        }
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

  /// Verifica el email usando el API
  static Future<bool> verifyEmail(String id, String hash) async {
    try {
      final result = await EmailVerificationHelper.verifyEmail(id, hash);
      return result['success'];
    } catch (e) {
      print('Error al verificar email: $e');
      return false;
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
}
