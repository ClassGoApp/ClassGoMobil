import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';

class TutorAgendaProvider extends ChangeNotifier {

  // 1. ESTADO CENTRAL (Base de datos local en memoria)
  final Map<DateTime, List<Map<String, dynamic>>> _freeTimesByDay = {};
  Map<DateTime, List<Map<String, dynamic>>> get freeTimesByDay =>
      _freeTimesByDay;

  bool _isLoadingSlots = false;
  bool get isLoadingSlots => _isLoadingSlots;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isMutating = false;
  bool get isMutating => _isMutating;

  // 2. LECTURA (GET) - CON MANEJO DE ERRORES ESTRICTO
  Future<void> loadAvailableSlots(String token, String userId) async {
    _isLoadingSlots = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await getTutorAvailableSlots(token, userId);
      print("📥 DEBUG DATA DE BD: $response"); // Veremos esto en tu consola

      List<dynamic> slotsData = [];

      // Buscador inteligente: No importa cómo Laravel mande el JSON, lo encontraremos
      if (response['data'] is List) {
        slotsData = response['data'];
      } else if (response['data'] != null && response['data']['data'] is List) {
        slotsData = response['data']['data'];
      } else if (response['slots'] is List) {
        slotsData = response['slots'];
      }

      if (slotsData.isNotEmpty) {
        _parseAndLoadSlots(slotsData);
      } else {
        _freeTimesByDay.clear(); // Limpia si no hay datos
      }
    } catch (e) {
      print('❌ Error al cargar slots: $e');
      _errorMessage = "Error de conexión. Verifica tu internetv.";
    } finally {
      _isLoadingSlots = false;
      notifyListeners();
    }
  }

  // 3. GUARDADO MÚLTIPLE (POST) - VERSIÓN ULTRA RÁPIDA (PARALELA)
  Future<bool> saveSlotsForDays({
    required String token,
    required String userId,
    required List<DateTime> days,
    required List<Map<String, String>> newSlots,
  }) async {
    if (days.isEmpty || newSlots.isEmpty) return false;

    _isMutating = true;
    notifyListeners();

    bool allSuccess = true;

    try {
      List<Future<void>> tareasParalelas = [];

      for (var day in days) {
        final cleanDay = _normalizeDate(day);
        final dateString =
            "${cleanDay.year}-${cleanDay.month.toString().padLeft(2, '0')}-${cleanDay.day.toString().padLeft(2, '0')}";

        for (var slot in newSlots) {
          // 1. Calculamos la duración en minutos (requerido por tu API)
          final startParts = slot['start']!.split(':');
          final endParts = slot['end']!.split(':');
          final startMinutes =
              (int.parse(startParts[0]) * 60) + int.parse(startParts[1]);
          final endMinutes =
              (int.parse(endParts[0]) * 60) + int.parse(endParts[1]);
          final duracion = (endMinutes - startMinutes).toString();

          // 2. Preparamos el mapa de datos exacto que tu API pide
          final slotData = {
            'user_id': userId,
            'start_time': slot['start'],
            'end_time': slot['end'],
            'date': dateString,
            'duracion': duracion,
          };

          // 3. Enviamos a tu API real
          tareasParalelas
              .add(createUserSubjectSlot(token, slotData).then((response) {
            if (response['success'] == true) {
              // Obtenemos el ID real generado por tu base de datos
              final nuevoId = response['data']?['id']?.toString() ??
                  DateTime.now().millisecondsSinceEpoch.toString();

              // Guardamos en memoria local
              _freeTimesByDay.putIfAbsent(cleanDay, () => []).add({
                'id': nuevoId,
                'start': slot['start'],
                'end': slot['end'],
              });
            } else {
              print(
                  "❌ El servidor rechazó el bloque de $dateString: ${response['message']}");
              allSuccess = false;
            }
          }).catchError((error) {
            print('❌ Error de red guardando slot: $error');
            allSuccess = false;
          }));
        }
      }

      // Ejecutamos todo al mismo tiempo para que sea instantáneo
      await Future.wait(tareasParalelas);
    } catch (e) {
      print('❌ Error crítico en el guardado masivo: $e');
      allSuccess = false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }

    return allSuccess;
  }

  // 4. ELIMINAR DATO (DELETE) - CONECTADO A TU API
  Future<bool> deleteSlot(
      String token, String slotId, String userId, DateTime day) async {
    final cleanDay = _normalizeDate(day);

    // 1. Guardamos copia de seguridad (por si falla el servidor)
    final backupSlots =
        List<Map<String, dynamic>>.from(_freeTimesByDay[cleanDay] ?? []);

    // 2. Lo borramos de la memoria visual instantáneamente (Optimistic UI)
    _freeTimesByDay[cleanDay]
        ?.removeWhere((slot) => slot['id'].toString() == slotId);
    notifyListeners();

    try {
      final slotIdInt = int.tryParse(slotId);
      if (slotIdInt == null) throw Exception("ID inválido");

      final response =
          await deleteUserSubjectSlot(token, slotIdInt, int.parse(userId));

      if (response['success'] == true) {
        return true;
      } else {
        throw Exception(
            response['message'] ?? "Error desconocido del servidor");
      }
    } catch (e) {
      print('❌ Error al borrar el slot: $e');
      // 3. Si algo falló (no hay internet, etc), restauramos el cuadro en la pantalla
      _freeTimesByDay[cleanDay] = backupSlots;
      notifyListeners();
      return false;
    }
  }

  // 5. HELPER METHODS (Para la UI)
  bool hasSchedule(DateTime day) {
    final cleanDay = _normalizeDate(day);
    return _freeTimesByDay.containsKey(cleanDay) &&
        _freeTimesByDay[cleanDay]!.isNotEmpty;
  }

  List<Map<String, dynamic>> getSlotsForDay(DateTime day) {
    final cleanDay = _normalizeDate(day);
    return _freeTimesByDay[cleanDay] ?? [];
  }

  // 6. VALIDACIONES ANTI-CRASHEOS (MUY IMPORTANTE)
  void _parseAndLoadSlots(List<dynamic> slotsData) {
    _freeTimesByDay.clear();

    for (var slot in slotsData) {
      try {
        // Validación 1: Que el dato no sea null
        if (slot == null || slot is! Map) continue;

        // Validación 2: Que la fecha exista
        final dateStr = slot['date']?.toString();
        if (dateStr == null || dateStr.isEmpty) continue;

        // Validación 3: Que la fecha tenga un formato correcto
        final date = DateTime.tryParse(dateStr);
        if (date == null)
          continue; // Si es '2026-99-99', lo ignora sin crashear

        final day = _normalizeDate(date);

        // Validación 4: Formateo seguro de la hora
        final formattedStart =
            _formatTimeString(slot['start_time']?.toString() ?? '');
        final formattedEnd =
            _formatTimeString(slot['end_time']?.toString() ?? '');

        _freeTimesByDay.putIfAbsent(day, () => []).add({
          'start': formattedStart,
          'end': formattedEnd,
          'id': slot['id']?.toString() ?? '',
          'description': slot['description']?.toString() ?? '',
        });
      } catch (e) {
        // Si CUALQUIER COSA sale mal con este bloque, lo atrapa aquí
        // Se ignora el bloque corrupto y el bucle sigue con el próximo día. ¡Cero crasheos!
        print("⚠️ Bloque corrupto ignorado: $e");
      }
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _formatTimeString(String timeString) {
    if (timeString.isEmpty) return '00:00';

    try {
      // 1. Si el servidor manda fecha y hora completa (Ej: "2026-02-26T17:00:00")
      if (timeString.contains('T') || timeString.contains(' ')) {
        String cleanString = timeString.replaceAll(' ', 'T');

        // Le agregamos la 'Z' al final para obligar a Flutter a entender que esto es hora UTC
        if (!cleanString.endsWith('Z')) {
          cleanString += 'Z';
        }

        DateTime dateTimeUTC = DateTime.parse(cleanString);

        DateTime dateTimeLocal = dateTimeUTC.subtract(const Duration(hours: 4));

        return "${dateTimeLocal.hour.toString().padLeft(2, '0')}:${dateTimeLocal.minute.toString().padLeft(2, '0')}";
      }

      final parts = timeString.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);

        hour = hour - 4;
        if (hour < 0) hour += 24;

        return "${hour.toString().padLeft(2, '0')}:${parts[1].padLeft(2, '0')}";
      }
    } catch (_) {
    }

    return timeString;
  }
}