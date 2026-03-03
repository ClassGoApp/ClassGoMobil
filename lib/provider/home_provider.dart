import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart' as api;

class HomeProvider extends ChangeNotifier {
  // Featured Tutors
  List<dynamic> _featuredTutors = [];
  bool _isLoadingTutors = false;
  String? _tutorsError;

  // Subjects
  List<dynamic> _subjects = [];
  bool _isLoadingSubjects = false;
  String? _subjectsError;

  // Alliances
  List<dynamic> _alliances = [];
  bool _isLoadingAlliances = false;
  String? _alliancesError;

  // Today's Bookings
  List<Map<String, dynamic>> _todaysBookings = [];
  bool _isLoadingBookings = false;
  String? _bookingsError;

  // Getters
  List<dynamic> get featuredTutors => _featuredTutors;
  bool get isLoadingTutors => _isLoadingTutors;
  String? get tutorsError => _tutorsError;

  List<dynamic> get subjects => _subjects;
  bool get isLoadingSubjects => _isLoadingSubjects;
  String? get subjectsError => _subjectsError;

  List<dynamic> get alliances => _alliances;
  bool get isLoadingAlliances => _isLoadingAlliances;
  String? get alliancesError => _alliancesError;

  List<Map<String, dynamic>> get todaysBookings => _todaysBookings;
  bool get isLoadingBookings => _isLoadingBookings;
  String? get bookingsError => _bookingsError;

  // Methods
  Future<void> fetchFeaturedTutors() async {
    if (_isLoadingTutors) return;

    _isLoadingTutors = true;
    _tutorsError = null;
    notifyListeners();

    try {
      // Simular la carga de tutores destacados
      // En una implementación real, esto vendría de la API
      await Future.delayed(Duration(milliseconds: 500));
      _featuredTutors = [];
      _tutorsError = null;
    } catch (e) {
      _tutorsError = e.toString();
      _featuredTutors = [];
    } finally {
      _isLoadingTutors = false;
      notifyListeners();
    }
  }

  Future<void> fetchSubjects(String? token) async {
    if (_isLoadingSubjects) return;

    _isLoadingSubjects = true;
    _subjectsError = null;
    notifyListeners();

    try {
      final response = await api.getSubjects(token);
      _subjects = response['data'] ?? [];
      _subjectsError = null;
    } catch (e) {
      _subjectsError = e.toString();
      _subjects = [];
    } finally {
      _isLoadingSubjects = false;
      notifyListeners();
    }
  }

  Future<void> fetchAlliances() async {
    if (_isLoadingAlliances) return;

    _isLoadingAlliances = true;
    _alliancesError = null;
    notifyListeners();

    try {
      final response = await api.fetchAlliances();
      _alliances = response['data'] ?? [];
      _alliancesError = null;
    } catch (e) {
      _alliancesError = e.toString();
      _alliances = [];
    } finally {
      _isLoadingAlliances = false;
      notifyListeners();
    }
  }

  Future<void> fetchTodaysBookings(String? token) async {
    if (_isLoadingBookings) return;

    _isLoadingBookings = true;
    _bookingsError = null;
    notifyListeners();

    try {
      // Simular la carga de reservas de hoy
      // En una implementación real, esto vendría de la API
      await Future.delayed(Duration(milliseconds: 300));
      _todaysBookings = [];
      _bookingsError = null;
    } catch (e) {
      _bookingsError = e.toString();
      _todaysBookings = [];
    } finally {
      _isLoadingBookings = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll(String? token) async {
    await Future.wait([
      fetchFeaturedTutors(),
      fetchSubjects(token),
      fetchAlliances(),
      fetchTodaysBookings(token),
    ]);
  }

  void clearErrors() {
    _tutorsError = null;
    _subjectsError = null;
    _alliancesError = null;
    _bookingsError = null;
    notifyListeners();
  }
}
