import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/provider/auth_provider.dart';

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
}
