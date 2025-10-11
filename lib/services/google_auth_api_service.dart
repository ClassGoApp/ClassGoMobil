import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleAuthApiService {
  static const String baseUrl = 'http://classgoapp.com/api';
  late Dio _dio;
  String? _accessToken;
  
  // Singleton pattern
  static GoogleAuthApiService? _instance;
  static GoogleAuthApiService get instance {
    _instance ??= GoogleAuthApiService._internal();
    return _instance!;
  }
  
  GoogleAuthApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Cargar token si no está cargado
        if (_accessToken == null) {
          await loadToken();
        }
        
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
          print('DEBUG - Token enviado en request: ${_accessToken!.substring(0, 20)}...');
        } else {
          print('DEBUG - No hay token disponible para enviar');
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        print('DEBUG - Error en request: ${error.response?.statusCode}');
        if (error.response?.statusCode == 401) {
          print('DEBUG - Token inválido, limpiando...');
          await _clearToken();
          // Redirigir al login
        }
        handler.next(error);
      },
    ));
  }

  // Cargar token al inicializar
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('token'); // Usar la misma clave que AuthProvider
    print('DEBUG - Token cargado desde SharedPreferences: ${_accessToken != null ? "${_accessToken!.substring(0, 20)}..." : "null"}');
  }

  // Guardar token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token); // Usar la misma clave que AuthProvider
    _accessToken = token;
    print('DEBUG - Token guardado en SharedPreferences: ${token.substring(0, 20)}...');
  }

  // Limpiar token
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token'); // Usar la misma clave que AuthProvider
    _accessToken = null;
    print('DEBUG - Token limpiado de SharedPreferences');
  }

  // Limpiar token (método público)
  Future<void> clearToken() async {
    await _clearToken();
  }
  
  // Sincronizar token con AuthProvider
  Future<void> syncTokenFromAuthProvider() async {
    await loadToken();
    print('DEBUG - Token sincronizado: ${_accessToken != null ? "${_accessToken!.substring(0, 20)}..." : "null"}');
  }
  
  // Verificar token guardado en SharedPreferences
  Future<void> checkStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('token');
    print('DEBUG - Token almacenado en SharedPreferences: ${storedToken != null ? "${storedToken.substring(0, 20)}..." : "null"}');
  }

  // ===== GOOGLE AUTH METHODS =====
  
  Future<Map<String, dynamic>> getGoogleAuthUrl() async {
    try {
      final response = await _dio.get('/auth/google/url');
      return response.data;
    } catch (e) {
      throw Exception('Error al obtener URL de autenticación: $e');
    }
  }

  Future<Map<String, dynamic>> handleGoogleCallback(String code) async {
    try {
      print('DEBUG - Enviando código al backend: ${code.substring(0, 20)}...');
      
      final response = await _dio.post('/auth/google/callback', data: {
        'code': code,
      });
      
      print('DEBUG - Respuesta del backend: ${response.data}');
      
      if (response.data['success']) {
        final token = response.data['data']['access_token'];
        print('DEBUG - Token recibido: ${token.substring(0, 20)}...');
        await saveToken(token);
        print('DEBUG - Token guardado exitosamente');
      } else {
        print('DEBUG - Backend retornó success: false');
      }
      
      return response.data;
    } catch (e) {
      print('DEBUG - Error en callback: $e');
      throw Exception('Error en callback de Google: $e');
    }
  }

  Future<Map<String, dynamic>> disconnectGoogle() async {
    try {
      final response = await _dio.post('/auth/google/disconnect');
      await _clearToken();
      return response.data;
    } catch (e) {
      throw Exception('Error al desconectar Google: $e');
    }
  }

  // ===== GOOGLE CALENDAR METHODS =====
  
  Future<Map<String, dynamic>> getGoogleCalendarAuthUrl() async {
    try {
      print('DEBUG - Obteniendo URL de calendario...');
      print('DEBUG - Token actual: ${_accessToken != null ? "${_accessToken!.substring(0, 20)}..." : "null"}');
      
      final response = await _dio.get('/google-calendar/auth-url');
      
      print('DEBUG - Respuesta del calendario: ${response.data}');
      return response.data;
    } catch (e) {
      print('DEBUG - Error al obtener URL de calendario: $e');
      throw Exception('Error al obtener URL de calendario: $e');
    }
  }

  Future<Map<String, dynamic>> connectGoogleCalendar(String code) async {
    try {
      final response = await _dio.post('/google-calendar/connect', data: {
        'code': code,
      });
      return response.data;
    } catch (e) {
      throw Exception('Error al conectar calendario: $e');
    }
  }

  Future<Map<String, dynamic>> getCalendarStatus() async {
    try {
      print('DEBUG - Verificando estado del calendario...');
      final response = await _dio.get('/google-calendar/status');
      print('DEBUG - Estado del calendario: ${response.data}');
      return response.data;
    } catch (e) {
      print('DEBUG - Error al verificar estado del calendario: $e');
      throw Exception('Error al verificar estado: $e');
    }
  }

  Future<Map<String, dynamic>> createCalendarEvent({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    String timezone = 'UTC',
  }) async {
    try {
      final response = await _dio.post('/google-calendar/events', data: {
        'title': title,
        'description': description,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'timezone': timezone,
      });
      return response.data;
    } catch (e) {
      throw Exception('Error al crear evento: $e');
    }
  }

  Future<Map<String, dynamic>> deleteCalendarEvent(String eventId) async {
    try {
      final response = await _dio.delete('/google-calendar/events/$eventId');
      return response.data;
    } catch (e) {
      throw Exception('Error al eliminar evento: $e');
    }
  }

  Future<Map<String, dynamic>> disconnectGoogleCalendar() async {
    try {
      final response = await _dio.post('/google-calendar/disconnect');
      return response.data;
    } catch (e) {
      throw Exception('Error al desconectar calendario: $e');
    }
  }
}

