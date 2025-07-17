import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/models/tutor_subject.dart';
import 'package:flutter_projects/provider/auth_provider.dart';

class TutorSubjectsProvider with ChangeNotifier {
  List<TutorSubject> _subjects = [];
  bool _isLoading = false;
  String? _error;

  List<TutorSubject> get subjects => _subjects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTutorSubjects(AuthProvider authProvider) async {
    if (authProvider.token == null || authProvider.userId == null) {
      _error = 'No hay token de autenticación o ID de usuario';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await getTutorSubjects(
        authProvider.token!,
        authProvider.userId!,
      );

      if (response['status'] == 200 && response['data'] != null) {
        final List<dynamic> subjectsData = response['data'];
        _subjects =
            subjectsData.map((json) => TutorSubject.fromJson(json)).toList();
        print('DEBUG - Materias cargadas: ${_subjects.length}');
        for (var subject in _subjects) {
          print('DEBUG - Materia: ${subject.subject.name}');
        }
      } else {
        _error = response['message'] ?? 'Error al cargar las materias';
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      print('Error loading tutor subjects: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addTutorSubjectToApi(
    AuthProvider authProvider,
    int subjectId,
    String description,
    String? imagePath,
  ) async {
    if (authProvider.token == null || authProvider.userId == null) {
      _error = 'No hay token de autenticación o ID de usuario';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await addTutorSubject(
        authProvider.token!,
        authProvider.userId!,
        subjectId,
        description,
        imagePath,
      );

      if (response['status'] == 200 || response['status'] == 201) {
        // Recargar las materias después de agregar una nueva
        await loadTutorSubjects(authProvider);
        return true;
      } else {
        _error = response['message'] ?? 'Error al agregar la materia';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      print('Error adding tutor subject: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTutorSubjectFromApi(
    AuthProvider authProvider,
    int subjectId,
  ) async {
    if (authProvider.token == null) {
      _error = 'No hay token de autenticación';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await deleteTutorSubject(
        authProvider.token!,
        subjectId,
      );

      if (response['status'] == 200 || response['status'] == 204) {
        // Recargar las materias después de eliminar
        await loadTutorSubjects(authProvider);
        return true;
      } else {
        _error = response['message'] ?? 'Error al eliminar la materia';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      print('Error deleting tutor subject: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
