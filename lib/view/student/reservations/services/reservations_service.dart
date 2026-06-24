import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:intl/intl.dart';

class ReservationItem {
  final int id;
  final String tutorName;
  final String studentName;
  final String subjectName;
  final DateTime? start;
  final DateTime? end;
  final String status;
  final String meetingLink;

  ReservationItem({
    required this.id,
    required this.tutorName,
    this.studentName = 'Estudiante',
    required this.subjectName,
    required this.start,
    required this.end,
    required this.status,
    required this.meetingLink,
  });
}

class ReservationsService {
  static DateTime _nowBolivia() {
    return DateTime.now().toUtc().subtract(const Duration(hours: 4));
  }

  static List<ReservationItem> filterRecentReservations(
    List<ReservationItem> reservations, {
    required DateTime now,
    int maxResults = 3,
    Duration lookback = const Duration(days: 30),
  }) {
    final lowerBound = now.subtract(lookback);

    final filtered = reservations.where((reservation) {
      if (reservation.start == null) return false;
      return !reservation.start!.isBefore(lowerBound);
    }).toList();

    filtered.sort((a, b) {
      final aTime = a.start ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.start ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return filtered.take(maxResults).toList();
  }

  static int _extractMonthInt(dynamic value) {
    if (value is int && value >= 1 && value <= 12) return value;
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null && parsed >= 1 && parsed <= 12) return parsed;
    return DateTime.now().month;
  }

  static Map<dynamic, dynamic>? _extractDateMap(dynamic source) {
    if (source is! Map) return null;

    if (source['Date'] is Map) {
      return source['Date'] as Map<dynamic, dynamic>;
    }

    if (source['date'] is Map) {
      return source['date'] as Map<dynamic, dynamic>;
    }

    if (source['data'] is Map) {
      final data = source['data'];
      if (data is Map && data['Date'] is Map) {
        return data['Date'] as Map<dynamic, dynamic>;
      }
      if (data is Map && data['date'] is Map) {
        return data['date'] as Map<dynamic, dynamic>;
      }
    }

    return null;
  }

  static DateTime? _parseHm(String? time) {
    if (time == null) return null;
    final parts = time.trim().split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return DateTime(1, 1, 1, hour, minute);
  }

  /// Obtiene y parsea las reservas del usuario
  static Future<List<ReservationItem>> fetchUserReservations(
      String token, int userId) async {
    final List<ReservationItem> out = [];

    final bookings = await getUserBookingsById(
      token,
      userId,
    );

    for (var b in bookings) {
      try {
        final int id = (b['id'] is int)
            ? b['id'] as int
            : int.tryParse(b['id']?.toString() ?? '') ?? 0;

        // Fecha inicio/fin: varios posibles campos
        DateTime? parseDate(String? s) {
          if (s == null) return null;
          try {
            return DateTime.parse(s);
          } catch (_) {
            return null;
          }
        }

        DateTime? start = parseDate(b['start_time']?.toString() ??
            b['start_date']?.toString() ??
            b['start']?.toString() ??
            b['booked_at']?.toString());
        DateTime? end = parseDate(b['end_time']?.toString() ??
            b['end_date']?.toString() ??
            b['end']?.toString());

        // Estado y meeting link
        final String status = b['status']?.toString() ?? '';
        final String meeting =
            b['meeting_link']?.toString() ?? b['meet_link']?.toString() ?? '';

        // Tutor name: prefer fields in booking, otherwise fetch tutor
        String tutorName =
            (b['tutor_name']?.toString() ?? b['tutor']?.toString() ?? 'Tutor');
        final int tId = int.tryParse(b['tutor_id']?.toString() ?? '') ?? 0;

        if (tutorName.isEmpty && tId > 0) {
          if (tId == userId) {
            tutorName = "Tutor";
          } else {
            try {
              final tutorResp = await getTutors(token, tId.toString());
              // posibles shapes
              if (tutorResp.containsKey('user')) {
                final u = tutorResp['user'];
                tutorName =
                    (u['first_name'] ?? '') + ' ' + (u['last_name'] ?? '');
              } else if (tutorResp.containsKey('name')) {
                tutorName = tutorResp['name'].toString();
              } else if (tutorResp.containsKey('full_name')) {
                tutorName = tutorResp['full_name'].toString();
              }
            } catch (_) {}
          }
        }

        // Student name
        String studentName =
            b['student_name']?.toString() ?? b['student']?.toString() ?? '';
        final int sId = int.tryParse(b['student_id']?.toString() ?? '') ?? 0;

        if (studentName.isEmpty && sId > 0) {
          if (sId == userId) {
            studentName = "Estudiante";
          } else {
            try {
              final studentResp = await getProfile(token, sId);
              if (studentResp.containsKey('user')) {
                final u = studentResp['user'];
                studentName =
                    (u['first_name'] ?? '') + ' ' + (u['last_name'] ?? '');
              } else if (studentResp.containsKey('first_name')) {
                studentName = (studentResp['first_name'] ?? '') +
                    ' ' +
                    (studentResp['last_name'] ?? '');
              } else if (studentResp.containsKey('name')) {
                studentName = studentResp['name'].toString();
              }
            } catch (_) {}
          }
        }

        // Subject name: prefer booking subject fields, otherwise call API
        String subjectName =
            b['subject_name']?.toString() ?? b['subject']?.toString() ?? '';
        if (subjectName.isEmpty && b['subject_id'] != null) {
          try {
            final sid = int.tryParse(b['subject_id'].toString()) ?? 0;
            if (sid > 0) {
              final subjResp = await getSubjectNameById(token, sid);
              if (subjResp.containsKey('name'))
                subjectName = subjResp['name'].toString();
              else if (subjResp.containsKey('data') &&
                  subjResp['data'] is Map &&
                  subjResp['data'].containsKey('name')) {
                subjectName = subjResp['data']['name'].toString();
              }
            }
          } catch (_) {}
        }

        out.add(ReservationItem(
          id: id,
          tutorName: tutorName.isNotEmpty ? tutorName : 'Tutor',
          studentName: studentName.isNotEmpty ? studentName : 'Estudiante',
          subjectName: subjectName.isNotEmpty ? subjectName : 'Materia',
          start: start,
          end: end,
          status: status,
          meetingLink: meeting,
        ));
      } catch (_) {
        // skip problematic booking
      }
    }

    return out;
  }

  /// Verifica si un tutor tiene disponibilidad instantánea actualmente.
  /// Devuelve `true` si hay algún slot cuyo rango contiene `now`.
  static Future<bool> isTutorInstantAvailable(
      String token, String tutorId) async {
    try {
      final now = _nowBolivia();
      final response = await getTutorAvailableSlots(
        token,
        tutorId,
        now.year,
        now.month,
      );

      bool available = false;

      final dateMap = _extractDateMap(response);
      if (dateMap != null) {
        final todaySlots = dateMap['${now.day}'];
        if (todaySlots is List) {
          for (final raw in todaySlots) {
            if (raw is! Map) continue;

            final status = (raw['status'] ?? '').toString().toLowerCase();
            if (status != 'free') continue;

            final startOnly = _parseHm(raw['time']?.toString());
            if (startOnly == null) continue;

            final start = DateTime(
              now.year,
              now.month,
              now.day,
              startOnly.hour,
              startOnly.minute,
            );
            final end = start.add(const Duration(minutes: 20));

            if ((now.isAfter(start) || now.isAtSameMomentAs(start)) &&
                now.isBefore(end)) {
              return true;
            }
          }
        }
      }

      final Map<String, dynamic> responseMap = response;
      final dynamic data =
          responseMap.containsKey('data') ? responseMap['data'] : responseMap;

      if (data is Map) {
        data.forEach((groupName, subjects) {
          if (available) return;
          if (subjects is Map) {
            subjects.forEach((subjectName, subjectData) {
              if (available) return;
              final List<dynamic> slots = subjectData['slots'] ?? [];
              for (final slot in slots) {
                try {
                  final start =
                      DateTime.parse((slot['start_time'] as String).trim());
                  final end =
                      DateTime.parse((slot['end_time'] as String).trim());
                  if ((now.isAfter(start) || now.isAtSameMomentAs(start)) &&
                      now.isBefore(end)) {
                    available = true;
                    break;
                  }
                } catch (_) {}
              }
            });
          }
        });
      } else if (data is List) {
        for (final slot in data) {
          try {
            final start = DateTime.parse((slot['start_time'] as String).trim());
            final end = DateTime.parse((slot['end_time'] as String).trim());
            if ((now.isAfter(start) || now.isAtSameMomentAs(start)) &&
                now.isBefore(end)) {
              available = true;
              break;
            }
          } catch (_) {}
        }
      }

      return available;
    } catch (e) {
      return false;
    }
  }

  /// Carga y parsea los slots disponibles de un tutor.
  /// Devuelve un mapa donde la clave es millisecondsSinceEpoch de la fecha
  /// (sin tiempo) y el valor es la lista de rangos de hora 'HH:mm-HH:mm'.
  static Future<Map<int, List<Map<String, dynamic>>>> loadTutorAvailableSlots(
    String token,
    String tutorId, {
    int? year,
    int? month,
  }) async {
    final Map<int, List<Map<String, dynamic>>> newAvailableDays = {};
    final nowBolivia = _nowBolivia();
    final todayBolivia =
        DateTime(nowBolivia.year, nowBolivia.month, nowBolivia.day);
    final targetMonth = DateTime(
      year ?? nowBolivia.year,
      month ?? nowBolivia.month,
      1,
    );

    try {
      final response = await getTutorAvailableSlots(
        token,
        tutorId,
        targetMonth.year,
        targetMonth.month,
      );

      final dateMap = _extractDateMap(response);
      if (dateMap != null) {
        for (final entry in dateMap.entries) {
          final int? day = int.tryParse(entry.key.toString());
          if (day == null || day <= 0) continue;

          final DateTime slotDate =
              DateTime(targetMonth.year, targetMonth.month, day);

          if (slotDate.month != targetMonth.month) continue;
          if (slotDate.isBefore(todayBolivia)) continue;

          final daySlots = entry.value;
          if (daySlots is! List) continue;

          for (final raw in daySlots) {
            if (raw is! Map) continue;

            final status = (raw['status'] ?? '').toString().toLowerCase();
            if (status == 'occupied') continue;

            final startOnly = _parseHm(raw['time']?.toString());
            if (startOnly == null) continue;

            final DateTime startTimeLocal = DateTime(
              slotDate.year,
              slotDate.month,
              slotDate.day,
              startOnly.hour,
              startOnly.minute,
            );
            final DateTime endTimeLocal =
                startTimeLocal.add(const Duration(minutes: 20));

            if (slotDate.isAtSameMomentAs(todayBolivia) &&
                !endTimeLocal.isAfter(nowBolivia)) {
              continue;
            }

            final int slotId = raw['slot_id'] is int
                ? raw['slot_id']
                : int.tryParse(raw['slot_id']?.toString() ?? '') ?? 0;

            final int dateKey =
                DateTime(slotDate.year, slotDate.month, slotDate.day)
                    .millisecondsSinceEpoch;

            final Map<String, dynamic> slotData = {
              'id': slotId,
              'date': DateFormat('yyyy-MM-dd').format(slotDate),
              'start': _formatTime12h(startTimeLocal),
              'end': _formatTime12h(endTimeLocal),
              'range':
                  '${_formatTime24h(startTimeLocal)}-${_formatTime24h(endTimeLocal)}',
              'start24': _formatTime24h(startTimeLocal),
              'end24': _formatTime24h(endTimeLocal),
              'raw_start_time': raw['time']?.toString(),
              'raw_end_time': _formatTime24h(endTimeLocal),
              'bookings_count': 0,
              'students': const [],
              'status': status,
              'is_twenty_min_block': true,
            };

            newAvailableDays.putIfAbsent(dateKey, () => []);

            final alreadyExists = newAvailableDays[dateKey]!.any(
              (item) =>
                  item['id'] == slotId &&
                  item['start24'] == slotData['start24'],
            );

            if (!alreadyExists) {
              newAvailableDays[dateKey]!.add(slotData);
            }
          }
        }

        for (final daySlots in newAvailableDays.values) {
          daySlots.sort((a, b) {
            final sa = a['start24']?.toString() ?? '';
            final sb = b['start24']?.toString() ?? '';
            return sa.compareTo(sb);
          });
        }

        return newAvailableDays;
      }

      final dynamic data = response is Map && response.containsKey('data')
          ? response['data']
          : response;

      if (data is List) {
        for (final slot in data) {
          try {
            if (slot['start_time'] == null ||
                slot['end_time'] == null ||
                slot['date'] == null) {
              continue;
            }

            final int slotId = slot['id'] is int
                ? slot['id']
                : int.tryParse(slot['id']?.toString() ?? '') ?? 0;

            final DateTime startTimeUtc =
                DateTime.parse(slot['start_time'].toString().trim()).toUtc();
            final DateTime endTimeUtc =
                DateTime.parse(slot['end_time'].toString().trim()).toUtc();

            // Bolivia UTC-4
            final DateTime startTimeLocal =
                startTimeUtc.subtract(const Duration(hours: 4));
            final DateTime endTimeLocal =
                endTimeUtc.subtract(const Duration(hours: 4));

            // La fecha real SIEMPRE viene de "date"
            final DateTime parsedDate =
                DateTime.parse(slot['date'].toString().trim());
            final DateTime slotDate =
                DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

            final DateTime nowBolivia =
                DateTime.now().toUtc().subtract(const Duration(hours: 4));
            final DateTime todayBolivia =
                DateTime(nowBolivia.year, nowBolivia.month, nowBolivia.day);

            if (slotDate.isBefore(todayBolivia)) continue;

            // Si el slot es de hoy, validar que aún no haya terminado
            if (slotDate.isAtSameMomentAs(todayBolivia) &&
                !endTimeLocal.isAfter(nowBolivia)) {
              continue;
            }

            final int dateKey = slotDate.millisecondsSinceEpoch;

            final Map<String, dynamic> slotData = {
              'id': slotId,
              'date': slot['date'].toString(),
              'start': _formatTime12h(startTimeLocal),
              'end': _formatTime12h(endTimeLocal),
              'range':
                  '${_formatTime24h(startTimeLocal)} - ${_formatTime24h(endTimeLocal)}',
              'start24': _formatTime24h(startTimeLocal),
              'end24': _formatTime24h(endTimeLocal),
              'raw_start_time': slot['start_time'],
              'raw_end_time': slot['end_time'],
              'bookings_count': slot['bookings_count'] ?? 0,
              'students': slot['students'] ?? [],
            };

            newAvailableDays.putIfAbsent(dateKey, () => []);

            final alreadyExists = newAvailableDays[dateKey]!.any(
              (item) => item['id'] == slotId,
            );

            if (!alreadyExists) {
              newAvailableDays[dateKey]!.add(slotData);
            }
          } catch (_) {
            // omitir slot inválido
          }
        }
      }
    } catch (e) {
      rethrow;
    }

    print('Parsed available slots for tutor $tutorId: $newAvailableDays');

    return newAvailableDays;
  }

  static String _formatTime24h(DateTime t) {
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }

  static String _formatTime12h(DateTime t) {
    final hour = t.hour == 0
        ? 12
        : t.hour > 12
            ? t.hour - 12
            : t.hour;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
