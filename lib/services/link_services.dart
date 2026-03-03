import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class LinkService {
  static Future<void> openSocialMediaLink({
    required BuildContext context,
    required String url,
    required String platform,
  }) async {
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showSnackBar(context, 'Abriendo $platform...', Colors.green);
      } else {
        await launchUrl(uri);
        _showSnackBar(context, 'Abriendo $platform en el navegador...', Colors.blue);
      }
    } catch (e) {
      _showSnackBar(context, 'Error al abrir $platform', Colors.red);
    }
  }

  static void _showSnackBar(BuildContext context, String message, Color color) {
    // La validación de 'mounted' se hace donde se llama al servicio o usando el scaffoldMessenger
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
}