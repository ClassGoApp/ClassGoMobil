
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_projects/api_structure/api_service.dart';

class AppConfig {
  static final AppConfig _instance = AppConfig._internal();

  static String get mediaBaseUrl {
    if (baseUrl.contains('/api')) {
      return baseUrl.replaceFirst('/api', '/storage');
    }
    return baseUrl.endsWith('/')
        ? '${baseUrl}storage/'
        : '$baseUrl/storage/';
  }


  AppConfig._internal();

  factory AppConfig() {
    return _instance;
  }

  Map<String, dynamic>? _settings;

  void clearSettingsCache() {
    _settings = null;
  }

  Future<Map<String, dynamic>> getSettings() async {
    if (_settings != null) {
      return _settings!;
    } else {
      try {
        final Uri uri = Uri.parse('$baseUrl/settings');
        final headers = <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          'Expires': '0',
        };

        final response = await http.get(uri, headers: headers);

        if (response.statusCode == 200) {
          _settings = json.decode(response.body);
          return _settings!;
        } else {
          final error = json.decode(response.body);
          throw Exception(error['message'] ?? 'Failed to get app settings');
        }
      } catch (e) {
        throw 'Failed to get app settings $e';
      }
    }
  }
}
