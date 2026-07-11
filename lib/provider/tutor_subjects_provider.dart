import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/models/tutor_subject.dart';
import 'package:flutter_projects/provider/auth_provider.dart';

class TutorSubjectsProvider with ChangeNotifier {
  List<TutorSubject> _subjects = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> subjectGroups = [];
  List<Map<String, dynamic>> availableSubjects = [];
  
  bool isLoadingGroups = false;
  bool isSearching = false;
  
  int currentPage = 1;
  int lastPage = 1;
  bool isFetchingMore = false;

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
        final data = response['data'];
        
        if (data is List) {
          print('🔍 DEBUG - Materias recibidas correctamente: ${data.length}');
          _subjects = data.map((json) => TutorSubject.fromJson(json)).toList();
        } else {
          _subjects = [];
          _error = 'Formato de datos inesperado del servidor';
        }
      } else {
        _subjects = [];
        _error = response['message'] ?? 'Error al cargar las materias';
      }
    } catch (e) {
      _subjects = [];
      _error = 'Error de conexión: $e';
      print('Error loading tutor subjects: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

      if ((response['status'] == 200 || response['status'] == 201 || response['success'] == true)) {
        
        await loadTutorSubjects(authProvider);
        return true;
      } else {
        _error = response['message'] ?? 'Error al agregar la materia';
        print('🔍 DEBUG - Error del servidor al agregar: $response'); 
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      print('Error adding tutor subject: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTutorSubjectFromApi(
    AuthProvider authProvider,
    int subjectId,
  ) async {
    print('🚀 DEBUG - Iniciando proceso de eliminación de materia...');

    if (authProvider.token == null || authProvider.userId == null) {
      _error = 'No hay token de autenticación';
      notifyListeners();
      return false;
    }

    _error = null;
    notifyListeners();

    try {
      final subjectIndex = _subjects.indexWhere((s) => s.id == subjectId);
      
      if (subjectIndex == -1) {
        _error = 'La materia no se encontró localmente';
        notifyListeners();
        return false;
      }

      final subjectToDelete = _subjects[subjectIndex];

      print('🔍 DEBUG - Materia a eliminar: "${subjectToDelete.subject.name}" (ID relación: $subjectId, ID base: ${subjectToDelete.subjectId})');

      final response = await deleteTutorSubject(
        authProvider.token!,
        authProvider.userId!,
        subjectToDelete.subjectId,
      );

      print('🔍 DEBUG - Respuesta de eliminación: $response');

      if ((response['success'] == true || response['status'] == 200)) {
        print('🔍 DEBUG - Eliminación exitosa');

        _subjects.removeAt(subjectIndex);
        notifyListeners();

        await loadTutorSubjects(authProvider);
        return true;
      } else {
        _error = response['message'] ?? 'Error al eliminar la materia';
        print('🔍 DEBUG - Error en eliminación: $_error');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      print('Error deleting tutor subject: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> loadGroups(String token) async {
    isLoadingGroups = true;
    notifyListeners();

    try {
      final response = await fetchSubjectGroups(token); // o ApiService.fetchSubjectGroups...
      
      if (response['success'] == true) {
        final List rawData = response['data'] ?? [];
        subjectGroups = rawData.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        _error = response['message'];
        print('❌ Error de la API al cargar grupos: $_error');
      }
    } catch (e) {
      _error = 'Ocurrió un error: $e';
      print('🔥 Error interno en loadGroups: $e');
    } finally {
      isLoadingGroups = false;
      notifyListeners();
    }
  }
  Future<void> searchSubjects({
    required String token,
    required int userId,
    String? keyword,
    int? groupId,
    bool isRefresh = false,
  }) async {
    if (isRefresh) {
      currentPage = 1;
      isSearching = true;
      notifyListeners();
    } else {
      if (currentPage >= lastPage || isFetchingMore) return;
      currentPage++;
      isFetchingMore = true;
      notifyListeners();
    }

    final response = await fetchAvailableSubjects(
      token: token,
      page: currentPage,
      keyword: keyword,
      groupId: groupId,
      userId: userId,
    );

    if (response['success']) {
      final newSubjects = List<Map<String, dynamic>>.from(response['data']);
      if (isRefresh) {
        availableSubjects = newSubjects;
      } else {
        availableSubjects.addAll(newSubjects);
      }
      lastPage = response['last_page'] ?? 1;
    }

    isSearching = false;
    isFetchingMore = false;
    notifyListeners();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}