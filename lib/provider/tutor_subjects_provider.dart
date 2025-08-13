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
        print('🔍 DEBUG - Datos crudos de materias recibidos:');
        for (int i = 0; i < subjectsData.length; i++) {
          final subject = subjectsData[i];
          print('   Materia $i: ID=${subject['id']}, Subject ID=${subject['subject_id']}, Nombre=${subject['subject']?['name'] ?? 'N/A'}');
        }
        
        _subjects =
            subjectsData.map((json) => TutorSubject.fromJson(json)).toList();
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
    print('🚀 DEBUG - Iniciando proceso de eliminación de materia...');
    
    if (authProvider.token == null) {
      _error = 'No hay token de autenticación';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔍 DEBUG - Eliminando materia con ID: $subjectId');
      print('🔍 DEBUG - ID del tutor: ${authProvider.userId}');
      
      // Buscar la materia para mostrar su nombre
      final subjectToDelete = _subjects.firstWhere(
        (subject) => subject.id == subjectId,
        orElse: () => TutorSubject(
          id: 0,
          userId: 0,
          subjectId: 0,
          description: '',
          status: 'unknown',
          subject: Subject(
            id: 0,
            name: 'Desconocida',
            subjectGroupId: 0,
          ),
        ),
      );
      print('🔍 DEBUG - Materia a eliminar: "${subjectToDelete.subject.name}" (ID: $subjectId)');
      print('🔍 DEBUG - ID de relación: $subjectId, ID de materia base: ${subjectToDelete.subjectId}');
      
      // Usar subjectId en lugar de id para la eliminación
      final response = await deleteTutorSubject(
        authProvider.token!,
        authProvider.userId!,
        subjectToDelete.subjectId, // ← Usar subjectId en lugar de id
      );

      print('🔍 DEBUG - Respuesta de eliminación: $response');

      if (response['success'] == true) {
        print('🔍 DEBUG - Eliminación exitosa, recargando materias...');
        // Recargar las materias después de eliminar
        await loadTutorSubjects(authProvider);
        print('🔍 DEBUG - Materias recargadas después de eliminar');
        return true;
      } else {
        _error = response['message'] ?? 'Error al eliminar la materia';
        print('🔍 DEBUG - Error en eliminación: $_error');
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
