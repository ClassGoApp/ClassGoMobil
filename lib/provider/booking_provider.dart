import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/services/sound_service.dart';
import 'package:flutter_projects/services/vibration_service.dart';
import 'dart:convert'; 

class BookingProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = false;
  bool _isLoaded = false;
  String? _lastToken;
  int? _lastUserId;

  List<Map<String, dynamic>> get bookings => _bookings;
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;

  Future<void> loadBookings(AuthProvider authProvider,
      {bool forceRefresh = false}) async {
    final token = authProvider.token;
    final userId = authProvider.userId;
    if (token == null || userId == null) return;
    if (!forceRefresh &&
        _isLoaded &&
        _lastToken == token &&
        _lastUserId == userId) return;
    _isLoading = true;
    notifyListeners();
    try {
      final data = await getUserBookingsById(token, userId);
      final List<Map<String, dynamic>> bookings = data
          .map((t) {
            DateTime? date;
            if (t['start_time'] is DateTime) {
              date = t['start_time'];
            } else if (t['start_time'] is String) {
              try {
                date = DateTime.parse(t['start_time']);
              } catch (_) {
                date = null;
              }
            }
            return {
              'title': t['title'] ?? 'Tutoría',
              'date': date,
              'hour': date != null
                  ? '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
                  : '',
              'status': (t['status'] ?? '').toString().toLowerCase(),
              ...t,
            };
          })
          .where((t) => t['date'] != null)
          .toList();
      _bookings = bookings;
      _isLoaded = true;
      _lastToken = token;
      _lastUserId = userId;
    } catch (e) {
      _bookings = [];
      _isLoaded = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  void clear() {
    _bookings = [];
    _isLoaded = false;
    notifyListeners();
  }

  Future<void> refreshBookingData({
    required int bookingId,
    required String token,
    required int userId,
  }) async {
    try {
      final allBookings = await getUserBookingsById(token, userId);

      // SOLUCIÓN AL NULL: Usamos cast explícito y manejamos el resultado como dinámico
      // o usamos 'cast' para asegurar que trabajamos con Maps.
      final List<dynamic> rawList = allBookings;

      // Buscamos el elemento. Usamos un bloque try-catch o firstWhere con orElse retornando un mapa vacío.
      Map<String, dynamic>? updatedData;
      
      try {
        updatedData = rawList.firstWhere(
          (b) => b['id'] == bookingId,
        ) as Map<String, dynamic>;
      } catch (e) {
        updatedData = null; // Si no lo encuentra, ahora sí es un null controlado
      }

      if (updatedData != null) {
        final index = _bookings.indexWhere((b) => b['id'] == bookingId);
        
        if (index != -1) {
          // Replicamos la lógica de formateo que tienes en loadBookings para mantener consistencia
          DateTime? date;
          var startTime = updatedData['start_time'];
          if (startTime is DateTime) {
            date = startTime;
          } else if (startTime is String) {
            date = DateTime.tryParse(startTime);
          }

          _bookings[index] = {
             ...updatedData,
             'title': updatedData['title'] ?? 'Tutoría',
             'date': date,
             'hour': date != null
                  ? '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
                  : '',
             'status': (updatedData['status'] ?? '').toString().toLowerCase(),
          };
          notifyListeners(); 
        }
      }
    } catch (e) {
      print('❌ Error refrescando booking individual: $e');
    }
  }

  Future<void> fetchTodaysBookings(String token, int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final bookings = await getUserBookingsById(token, userId);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      

      // Guardamos en la variable de la clase Provider, ya filtradas
      _bookings = bookings.where((b) {
        final status = b['status'].toString().toLowerCase();
        if (status == 'completado' || status == 'rechazado') return false;

        final start = DateTime.tryParse(b['start_time'] ?? '') ?? now;
        return start.year == today.year &&
              start.month == today.month &&
              start.day == today.day;
      }).cast<Map<String, dynamic>>().toList();

    } catch (e) {
      print('Error en Provider: $e');
      _bookings = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void handlePusherUpdate(dynamic data, int? currentUserId) {
    try {
      // 1. Parsear datos
      final Map<String, dynamic> eventData = (data is String) ? json.decode(data) : data;
      final int? eventStudentId = eventData['student_id'];

      // 2. Filtrar por usuario
      if (eventStudentId == null || currentUserId == null || eventStudentId != currentUserId) return;

      final int? slotBookingId = eventData['slotBookingId'];
      final String? newStatus = eventData['newStatus'];

      // 3. Feedback Sensorial
      SoundService.playStatusChangeSound(newStatus);
      VibrationService.vibrateForStatus(newStatus ?? '');

      // 4. Actualizar Estado Local
      final index = _bookings.indexWhere((b) => b['id'] == slotBookingId);
      if (index != -1) {
        _bookings[index] = {..._bookings[index], 'status': newStatus};
        notifyListeners(); // Esto reemplaza al setState de la Home
      }
    } catch (e) {
      print('❌ Error en Provider al procesar Pusher: $e');
    }
  }

}


