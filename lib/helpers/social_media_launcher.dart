import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class LauncherHelper {
  static Future<void> launchWhatsApp({required String phone, required String message}) async {
    final url = "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";
    await _launch(url);
  }

  static Future<void> launchEmail({required String email}) async {
  final Uri emailLaunchUri = Uri(
    scheme: 'mailto',
    path: email,
  );
  await _launch(emailLaunchUri.toString());
}

  static Future<void> launchURL(String url) async {
    await _launch(url);
  }

  static Future<void> _launch(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("No se pudo abrir $urlString");
    }
  }
}