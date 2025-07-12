import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'dart:convert';

class TutoriasProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  TutoriasProvider({required this.authProvider});

  List<Map<String, dynamic>> _tutorias = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidity = Duration(minutes: 5);

  List<Map<String, dynamic>> get tutorias => _tutorias;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTutorias({bool forceRefresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('tutorias_cache');
      final lastUpdate = prefs.getString('tutorias_last_update');
      bool useCache = false;
      if (!forceRefresh && cachedData != null && lastUpdate != null) {
        final lastUpdateTime = DateTime.parse(lastUpdate);
        if (DateTime.now().difference(lastUpdateTime) < _cacheValidity) {
          final List<dynamic> cachedTutorias = jsonDecode(cachedData);
          final List<Map<String, dynamic>> parsedTutorias =
              cachedTutorias.map((t) {
            final tMap = Map<String, dynamic>.from(t);
            if (tMap['date'] is String) {
              tMap['date'] = DateTime.parse(tMap['date']);
            }
            return tMap;
          }).toList();
          _tutorias = parsedTutorias;
          useCache = true;
        }
      }
      if (!useCache) {
        final token = authProvider.token;
        final userId = authProvider.userId;
        if (token == null || userId == null) {
          throw Exception('Usuario no autenticado');
        }
        final bookings = await getUserBookingsById(token, userId);
        final List<Map<String, dynamic>> tutorias = bookings.map((booking) {
          final startTime =
              DateTime.tryParse(booking['start_time'] ?? '') ?? DateTime.now();
          final status = (booking['status'] ?? '').toString().toLowerCase();
          final subjectName = booking['subject_name'] ?? 'Tutoría';
          return {
            'id': booking['id'],
            'title': subjectName,
            'date': startTime,
            'hour':
                '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
            'status': status,
            'start_time': booking['start_time'],
            'end_time': booking['end_time'],
            'tutor_name': booking['tutor_name'] ?? 'Tutor',
            'subject_name': subjectName,
          };
        }).toList();
        _tutorias = tutorias;
        await _saveTutoriasToCache(tutorias);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshTutorias() async {
    await loadTutorias(forceRefresh: true);
  }

  Future<void> _saveTutoriasToCache(List<Map<String, dynamic>> tutorias) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> serializableTutorias = tutorias.map((t) {
        final tCopy = Map<String, dynamic>.from(t);
        if (tCopy['date'] is DateTime) {
          tCopy['date'] = (tCopy['date'] as DateTime).toIso8601String();
        }
        return tCopy;
      }).toList();
      await prefs.setString('tutorias_cache', jsonEncode(serializableTutorias));
      await prefs.setString(
          'tutorias_last_update', DateTime.now().toIso8601String());
    } catch (e) {
      // Ignorar errores de caché
    }
  }

  List<Map<String, dynamic>> getTutoriasForDay(DateTime day) {
    final dateKey = DateUtils.dateOnly(day);
    return _tutorias
        .where((t) => DateUtils.isSameDay(t['date'], dateKey))
        .toList();
  }

  List<Map<String, dynamic>> getFilteredTutorias(String filter) {
    final sorted = List<Map<String, dynamic>>.from(_tutorias)
      ..sort((a, b) => b['date'].compareTo(a['date']));
    if (filter == 'todas') return sorted;
    return sorted.where((t) => t['status'] == filter).toList();
  }
}
