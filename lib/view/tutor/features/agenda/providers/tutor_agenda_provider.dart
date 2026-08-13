import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/view/student/reservations/services/reservations_service.dart';

class TutorAgendaProvider extends ChangeNotifier {

  final Map<DateTime, List<Map<String, dynamic>>> _freeTimesByDay = {};
  Map<DateTime, List<Map<String, dynamic>>> get freeTimesByDay =>
      _freeTimesByDay;

  final Set<String> _loadedMonths = {};

  bool _isLoadingSlots = false;
  bool get isLoadingSlots => _isLoadingSlots;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isMutating = false;
  bool get isMutating => _isMutating;

Future<void> loadAvailableSlots(
  String token,
  String userId, {
  int? year,
  int? month,
  bool forceRefresh = false,
}) async {
  final targetYear = year ?? DateTime.now().year;
  final targetMonth = month ?? DateTime.now().month;
  final monthKey = "$targetYear-$targetMonth";

  if (!forceRefresh && _loadedMonths.contains(monthKey)) {
    return;
  }

  _isLoadingSlots = true;
  _errorMessage = null;
  notifyListeners();

  try {
    final response = await getTutorAvailableSlots(
      token,
      userId,
      targetYear,
      targetMonth,
    );

    if (response is Map && response.containsKey('Date')) {
      final dynamic rawDate = response['Date'];

      if (rawDate is Map) {
        final Map<dynamic, dynamic> dateMap = rawDate;

        dateMap.forEach((dayStr, slotsList) {
          int day = int.tryParse(dayStr.toString()) ?? 1;
          DateTime cleanDay = DateTime(targetYear, targetMonth, day);

          Map<String, Map<String, dynamic>> groupedBlocks = {};

          if (slotsList is List) {
            for (var slot in slotsList) {
              if (slot is Map && slot['status'] == 'free') {
                final timeStr = slot['time']?.toString() ?? '';
                final slotId = slot['slot_id']?.toString() ?? '';

                if (timeStr.isEmpty || slotId.isEmpty) continue;

                final parts = timeStr.split(':');

                if (parts.length >= 2) {
                  final startHour = int.tryParse(parts[0]) ?? 0;
                  final startMin = int.tryParse(parts[1]) ?? 0;

                  final startDateTime = DateTime(
                    targetYear,
                    targetMonth,
                    day,
                    startHour,
                    startMin,
                  );

                  final endDateTime = startDateTime.add(
                    const Duration(minutes: 20),
                  );

                  if (groupedBlocks.containsKey(slotId)) {
                    DateTime currentEnd =
                        groupedBlocks[slotId]!['endDateTime'];

                    if (endDateTime.isAfter(currentEnd)) {
                      groupedBlocks[slotId]!['endDateTime'] = endDateTime;
                      groupedBlocks[slotId]!['end'] =
                          "${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}";
                    }
                  } else {
                    final formattedStart =
                        "${startDateTime.hour.toString().padLeft(2, '0')}:${startDateTime.minute.toString().padLeft(2, '0')}";

                    final formattedEnd =
                        "${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}";

                    groupedBlocks[slotId] = {
                      'id': slotId,
                      'start': formattedStart,
                      'end': formattedEnd,
                      'status': slot['status'],
                      'startDateTime': startDateTime,
                      'endDateTime': endDateTime,
                    };
                  }
                }
              }
            }
          }

          if (groupedBlocks.isNotEmpty) {
            _freeTimesByDay[cleanDay] = groupedBlocks.values.map((block) {
              return {
                'id': block['id'],
                'start': block['start'],
                'end': block['end'],
                'status': block['status'],
              };
            }).toList();

            _freeTimesByDay[cleanDay]!.sort(
              (a, b) => a['start'].compareTo(b['start']),
            );
          } else {
            _freeTimesByDay.remove(cleanDay);
          }
        });

        _loadedMonths.add(monthKey);
      } else {
        print("📭 No hay horarios disponibles para $monthKey");
        _loadedMonths.add(monthKey);
        _errorMessage = null;
      }
    } else if (response is Map) {
      List<dynamic> slotsData = [];

      if (response['data'] is List) {
        slotsData = response['data'];
      } else if (
          response['data'] != null &&
          response['data']['data'] is List) {
        slotsData = response['data']['data'];
      }

      if (slotsData.isNotEmpty) {
        _parseAndLoadSlots(slotsData);
      }
      _loadedMonths.add(monthKey);
    }
  } catch (e) {
    print('❌ Error al cargar slots: $e');
    _errorMessage = "Error de conexión. Verifica tu internet.";
  } finally {
    _isLoadingSlots = false;
    notifyListeners();
  }
}
  Future<Map<String, dynamic>> saveSlotsForDays({
    required String token,
    required String userId,
    required List<DateTime> days,
    required List<Map<String, String>> newSlots,
  }) async {
    if (days.isEmpty || newSlots.isEmpty) {
      return {'success': false, 'savedCount': 0, 'totalCount': 0, 'errors': []};
    }

    _isMutating = true;
    notifyListeners();

    int savedCount = 0;
    int totalCount = days.length;
    List<String> errors = [];

    try {
      List<Future<void>> tareasParalelas = [];

      for (var day in days) {
        final cleanDay = _normalizeDate(day);
        final dateString =
            "${cleanDay.year}-${cleanDay.month.toString().padLeft(2, '0')}-${cleanDay.day.toString().padLeft(2, '0')}";

        for (var slot in newSlots) {
          final startParts = slot['start']!.split(':');
          final endParts = slot['end']!.split(':');
          final startMinutes =
              (int.parse(startParts[0]) * 60) + int.parse(startParts[1]);
          final endMinutes =
              (int.parse(endParts[0]) * 60) + int.parse(endParts[1]);
          final duracion = (endMinutes - startMinutes).toString();

          final slotData = {
            'user_id': userId,
            'start_time': slot['start'],
            'end_time': slot['end'],
            'date': dateString,
            'duracion': duracion,
          };

          tareasParalelas
              .add(createUserSubjectSlot(token, slotData).then((response) {
            if (response['success'] == true || response['success'] == 'true' || response['status'] == 'success' || response.containsKey('id')) {
              savedCount++;
            } else {
              final errorMsg = response['message']?.toString() ?? 'Error desconocido';
              print("❌ El servidor rechazó el bloque de $dateString: $errorMsg");
              errors.add("$dateString: $errorMsg");
            }
          }).catchError((error) {
            print('❌ Error de red guardando slot en $dateString: $error');
            errors.add("$dateString: Error de conexión");
          }));
        }
      }

      await Future.wait(tareasParalelas);

      if (savedCount > 0) {
        await loadAvailableSlots(token, userId, forceRefresh: true);
      }

    } catch (e) {
      print('❌ Error crítico en el guardado masivo: $e');
      errors.add('Error crítico: $e');
    } finally {
      _isMutating = false;
      notifyListeners();
    }

    return {
      'success': savedCount == totalCount,
      'savedCount': savedCount,
      'totalCount': totalCount,
      'errors': errors,
      'partialSuccess': savedCount > 0 && savedCount < totalCount,
    };
  }
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
  // LÓGICA DE RESERVAS (CLASES PROGRAMADAS)
  List<ReservationItem> _reservations = [];
  List<ReservationItem> get reservations => _reservations;

  final Set<DateTime> _daysWithClasses = {};

  bool _isLoadingBookings = false;
  bool get isLoadingBookings => _isLoadingBookings;

  Future<void> loadReservations(String token, int userId) async {
    _isLoadingBookings = true;
    notifyListeners();

    try {
      _reservations = await ReservationsService.fetchUserReservations(token, userId);
      
      _daysWithClasses.clear();
      for (var res in _reservations) {
        if (res.start != null) {
          _daysWithClasses.add(DateTime(res.start!.year, res.start!.month, res.start!.day));
        }
      }
    } catch (e) {
      print("❌ Error cargando reservas: $e");
    } finally {
      _isLoadingBookings = false;
      notifyListeners();
    }
  }

  bool hasClasses(DateTime day) {
    return _daysWithClasses.contains(DateTime(day.year, day.month, day.day));
  }

  List<ReservationItem> getReservationsForDay(DateTime day) {
    return _reservations.where((res) {
      if (res.start == null) return false;
      return res.start!.year == day.year &&
             res.start!.month == day.month &&
             res.start!.day == day.day;
    }).toList();
  }
}