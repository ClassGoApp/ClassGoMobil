import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:intl/intl.dart';

class ReservationItem {
  final int id;
  final String tutorName;
  final String subjectName;
  final DateTime? start;
  final DateTime? end;
  final String status;
  final String meetingLink;

  ReservationItem({
    required this.id,
    required this.tutorName,
    required this.subjectName,
    required this.start,
    required this.end,
    required this.status,
    required this.meetingLink,
  });
}

class ReservationsService {
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
        if ((tutorName.isEmpty || tutorName == 'Tutor') &&
            (b['tutor_id'] != null)) {
          try {
            final tutorId = b['tutor_id'].toString();
            final tutorResp = await getTutors(token, tutorId);
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
      final response = await getTutorAvailableSlots(token, tutorId);
      final now = DateTime.now();

      bool available = false;

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
  static Future<Map<int, List<String>>> loadTutorAvailableSlots(
      String token, String tutorId) async {
    final Map<int, List<String>> newAvailableDays = {};
    try {
      final response = await getTutorAvailableSlots(token, tutorId);
      dynamic data = response is Map && response.containsKey('data')
          ? response['data']
          : response;

      if (data is List) {
        for (var slot in data) {
          try {
            if (slot['start_time'] == null || slot['end_time'] == null) {
              continue;
            }

            final startTimeUTC =
                DateTime.parse(slot['start_time'].toString().trim());
            final endTimeUTC =
                DateTime.parse(slot['end_time'].toString().trim());

            final startTime = startTimeUTC.subtract(Duration(hours: 4));
            final endTime = endTimeUTC.subtract(Duration(hours: 4));

            DateTime slotDateLocal;
            if (slot.containsKey('date') &&
                slot['date'] != null &&
                slot['date'].toString().isNotEmpty) {
              try {
                final parsed = DateTime.parse(slot['date'].toString());
                slotDateLocal = DateTime(parsed.year, parsed.month, parsed.day);
              } catch (_) {
                slotDateLocal =
                    DateTime(startTime.year, startTime.month, startTime.day);
              }
            } else {
              slotDateLocal =
                  DateTime(startTime.year, startTime.month, startTime.day);
            }

            final nowBolivia =
                DateTime.now().toUtc().subtract(Duration(hours: 4));
            final todayBolivia =
                DateTime(nowBolivia.year, nowBolivia.month, nowBolivia.day);
            final slotDateNormalized = DateTime(
                slotDateLocal.year, slotDateLocal.month, slotDateLocal.day);

            if (slotDateNormalized.isBefore(todayBolivia)) continue;
            if (slotDateNormalized.isAtSameMomentAs(todayBolivia) &&
                !endTime.isAfter(nowBolivia)) continue;

            final dateKey = DateTime(
                slotDateLocal.year, slotDateLocal.month, slotDateLocal.day);
            final timeRange =
                '${_formatTimeSimple(startTime)}-${_formatTimeSimple(endTime)}';

            if (!newAvailableDays.containsKey(dateKey.millisecondsSinceEpoch)) {
              newAvailableDays[dateKey.millisecondsSinceEpoch] = [];
            }
            if (!newAvailableDays[dateKey.millisecondsSinceEpoch]!
                .contains(timeRange)) {
              newAvailableDays[dateKey.millisecondsSinceEpoch]!.add(timeRange);
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      rethrow;
    }

    return newAvailableDays;
  }

  static String _formatTimeSimple(DateTime t) {
    // siempre devolvemos HH:mm
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }
}
