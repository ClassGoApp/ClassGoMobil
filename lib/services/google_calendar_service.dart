import 'dart:convert';

import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class GoogleCalendarService {
  Future<void> openAuthorization({required String token}) async {
    final data = await _get('auth-url', token);
    final url = data['auth_url'];
    final uri = url is String ? Uri.tryParse(url) : null;
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'accounts.google.com') {
      throw const FormatException('URL de autorización inválida');
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('No se pudo abrir la autorización de Google');
    }
  }

  Future<Map<String, dynamic>> getConnectionStatus(
      {required String token}) async {
    final response = await _get('status', token);
    final data = response['data'];
    if (data is! Map<String, dynamic> || data['connected'] is! bool) {
      throw const FormatException('Estado de Calendar inválido');
    }
    return data;
  }

  Future<void> disconnect({required String token}) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/google-calendar/disconnect'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 15));
    _decode(response);
  }

  Future<Map<String, dynamic>> _get(String route, String token) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/google-calendar/$route'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 15));
    return _decode(response);
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode != 200) {
      throw StateError('Google Calendar HTTP ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic> || data['success'] != true) {
      throw const FormatException('Respuesta de Calendar inválida');
    }
    return data;
  }
}
