import 'package:url_launcher/url_launcher.dart';
import 'google_auth_api_service.dart';

class GoogleCalendarService {
  final GoogleAuthApiService _apiService = GoogleAuthApiService.instance;

  Future<Map<String, dynamic>> connectCalendar() async {
    try {
      // Verificar token almacenado
      await _apiService.checkStoredToken();
      
      // Sincronizar token antes de hacer peticiones
      await _apiService.syncTokenFromAuthProvider();
      
      // Obtener URL de autenticación
      final urlResponse = await _apiService.getGoogleCalendarAuthUrl();
      
      if (!urlResponse['success']) {
        throw Exception(urlResponse['message']);
      }

      final String authUrl = urlResponse['auth_url'];
      
      // Abrir URL en navegador
      if (await canLaunchUrl(Uri.parse(authUrl))) {
        await launchUrl(Uri.parse(authUrl), mode: LaunchMode.externalApplication);
      } else {
        throw Exception('No se puede abrir la URL de autenticación');
      }

      return {'success': true, 'message': 'URL de calendario abierta'};
    } catch (e) {
      throw Exception('Error al conectar calendario: $e');
    }
  }

  Future<Map<String, dynamic>> handleCalendarCallback(String code) async {
    try {
      final response = await _apiService.connectGoogleCalendar(code);
      return response;
    } catch (e) {
      throw Exception('Error en callback de calendario: $e');
    }
  }

  Future<bool> isCalendarConnected() async {
    try {
      // Sincronizar token antes de hacer peticiones
      await _apiService.syncTokenFromAuthProvider();
      
      final response = await _apiService.getCalendarStatus();
      print('DEBUG - Respuesta de estado: $response');
      
      if (response['success'] == true) {
        final connected = response['data']?['connected'] ?? false;
        print('DEBUG - Calendario conectado: $connected');
        return connected;
      } else {
        print('DEBUG - Backend retornó success: false');
        return false;
      }
    } catch (e) {
      print('DEBUG - Error verificando conexión: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> createEvent({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final response = await _apiService.createCalendarEvent(
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
      );
      return response;
    } catch (e) {
      throw Exception('Error al crear evento: $e');
    }
  }

  Future<Map<String, dynamic>> deleteEvent(String eventId) async {
    try {
      final response = await _apiService.deleteCalendarEvent(eventId);
      return response;
    } catch (e) {
      throw Exception('Error al eliminar evento: $e');
    }
  }

  Future<Map<String, dynamic>> disconnectCalendar() async {
    try {
      final response = await _apiService.disconnectGoogleCalendar();
      return response;
    } catch (e) {
      throw Exception('Error al desconectar calendario: $e');
    }
  }
}

