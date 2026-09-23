import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleCalendarService {
  static final GoogleCalendarService _instance = GoogleCalendarService._internal();
  factory GoogleCalendarService() => _instance;
  GoogleCalendarService._internal();

  final String _baseUrl = 'https://classgoapp.com/api';
  bool _isConnected = false;
  String? _currentUserEmail;
  Map<String, dynamic>? _calendarInfo;
  String? _accessToken;
  
  // Google Sign-In with calendar scopes
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/calendar.readonly',
      'https://www.googleapis.com/auth/userinfo.email',
    ],
  );

  /// Conecta con Google Calendar usando Google Sign-In (dentro de la app)
  Future<bool> connectWithGoogleCalendar({
    required String token,
    required int userId,
  }) async {
    try {
      print('🔴 [GoogleCalendarService] Iniciando Google Sign-In...');
      print('🔴 [GoogleCalendarService] GoogleSignIn scopes: ${_googleSignIn.scopes}');
      
      // Paso 1: Abrir Google Sign-In dialog (DENTRO de la app)
      final account = await _googleSignIn.signIn();
      
      print('🔴 [GoogleCalendarService] Sign-In result: account=$account');
      
      if (account == null) {
        print('🔴 [GoogleCalendarService] Usuario canceló el sign-in');
        _isConnected = false;
        return false;
      }

      print('🔴 [GoogleCalendarService] Cuenta obtenida: ${account.email}');
      
      // Paso 2: Obtener authentication details
      final auth = await account.authentication;
      final accessToken = auth.accessToken;
      
      print('🔴 [GoogleCalendarService] Access token obtenido: ${accessToken != null}');
      print('🔴 [GoogleCalendarService] Access token: $accessToken');
      
      if (accessToken == null) {
        print('🔴 [GoogleCalendarService] No hay access token');
        _isConnected = false;
        return false;
      }

      _accessToken = accessToken;
      _currentUserEmail = account.email;
      
      print('🔴 [GoogleCalendarService] Enviando token al backend...');

      // Paso 3: Enviar token de Google al backend para validar/guardar
      final response = await http.post(
        Uri.parse('$_baseUrl/google-calendar/connect-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'google_access_token': accessToken,
          'user_id': userId,
          'email': account.email,
        }),
      );

      print('🔴 [GoogleCalendarService] Backend response: ${response.statusCode}');
      print('🔴 [GoogleCalendarService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔴 [GoogleCalendarService] Response data: $data');
        if (data['success'] == true) {
          _isConnected = true;
          _calendarInfo = data['data']?['calendar_info'] ?? {
            'id': account.email,
            'summary': account.email,
          };
          print('🔴 [GoogleCalendarService] ✅ Conexión exitosa');
          return true;
        } else {
          print('🔴 [GoogleCalendarService] ❌ Backend respondió success=false');
        }
      } else {
        print('🔴 [GoogleCalendarService] ❌ Backend error ${response.statusCode}');
      }

      _isConnected = false;
      return false;
    } on PlatformException catch (e) {
      print('🔴 [GoogleCalendarService] ❌ PlatformException: ${e.code}');
      print('🔴 [GoogleCalendarService] ❌ Message: ${e.message}');
      print('🔴 [GoogleCalendarService] ❌ Details: ${e.details}');
      _isConnected = false;
      return false;
    } catch (e) {
      print('🔴 [GoogleCalendarService] ❌ Exception: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Desconecta Google Calendar
  Future<bool> disconnect({required String token}) async {
    try {
      // Paso 1: Desconectar en Google
      await _googleSignIn.signOut();
      
      // Paso 2: Limpiar estado local
      _isConnected = false;
      _currentUserEmail = null;
      _calendarInfo = null;
      _accessToken = null;

      // Paso 3: Notificar al backend (opcional)
      try {
        await http.post(
          Uri.parse('$_baseUrl/google-calendar/disconnect'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      } catch (e) {
        // Continuar aunque falle
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Crea un evento en Google Calendar directamente (sin backend)
  Future<Map<String, dynamic>?> createEvent({
    required String title,
    required String description,
    required DateTime start,
    required DateTime end,
    String? location,
    List<String>? attendees,
  }) async {
    if (!_isConnected || _accessToken == null) {
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('https://www.googleapis.com/calendar/v3/calendars/primary/events'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'summary': title,
          'description': description,
          'start': {
            'dateTime': start.toIso8601String(),
            'timeZone': 'UTC',
          },
          'end': {
            'dateTime': end.toIso8601String(),
            'timeZone': 'UTC',
          },
          if (location != null) 'location': location,
          if (attendees != null && attendees.isNotEmpty)
            'attendees': attendees.map((email) => {'email': email}).toList(),
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Verifica el estado de conexión y actualiza si es necesario
  Future<bool> checkConnectionStatus({required String token}) async {
    try {
      final currentUser = _googleSignIn.currentUser;
      
      if (currentUser == null) {
        _isConnected = false;
        return false;
      }

      final auth = await currentUser.authentication;
      _accessToken = auth.accessToken;
      _currentUserEmail = currentUser.email;
      _isConnected = _accessToken != null;
      
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  Future<bool> isConnected() async {
    return _isConnected;
  }

  String? get currentUserEmail => _currentUserEmail;
  Map<String, dynamic>? get calendarInfo => _calendarInfo;
}