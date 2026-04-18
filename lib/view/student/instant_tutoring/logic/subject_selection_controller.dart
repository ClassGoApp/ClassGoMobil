import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_projects/api_structure/api_service.dart';

class SubjectSelectionController extends ChangeNotifier {
  bool isLoading = true;
  bool isCheckingActive = true;
  List<dynamic> categories = [];
  Map<String, dynamic>? activeBatch;

  // 1. CARGA INICIAL
  Future<void> initialize() async {
    await checkActiveSession();
    await fetchSubjects();
    isLoading = false;
    notifyListeners();
  }

  // 2. VERIFICAR SI YA HAY UN RADAR GIRANDO
  Future<void> checkActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      final result = await checkActiveBatch(token);
      if (result['active'] == true) {
        activeBatch = result;
      }
    } catch (e) {
      print("Error revisando sesión activa: $e");
    } finally {
      isCheckingActive = false;
      notifyListeners();
    }
  }

  // 3. OBTENER MATERIAS DEL BACKEND
  Future<void> fetchSubjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final data = await getCategoriasMaterias(token);
      categories = data['data'] ?? [];
    } catch (e) {
      print("Error cargando materias: $e");
    }
  }

  // Limpiar el estado del batch activo una vez recuperado
  void clearActiveBatch() {
    activeBatch = null;
    notifyListeners();
  }
}