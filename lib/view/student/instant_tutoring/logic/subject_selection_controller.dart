import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_projects/api_structure/api_service.dart';

class SubjectSelectionController extends ChangeNotifier {
  bool isLoading = true;
  bool isCheckingActive = false;
  List<dynamic> categories = [];
  Map<String, dynamic>? activeBatch;

  Future<void> initialize() async {
    await fetchSubjects(); 
    await checkActiveSession();
    isLoading = false;
    notifyListeners();
  }

  Future<void> checkActiveSession() async {
    isCheckingActive = true;
    notifyListeners(); 
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      final result = await checkActiveBatch(token);
      if (result['active'] == true) {
        activeBatch = result;
      } else {
        activeBatch = null;
      }
    } catch (e) {
      activeBatch = null; 
    } finally {
      isCheckingActive = false;
      notifyListeners();
    }
  }

  Future<void> fetchSubjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final data = await getCategoriasMaterias(token);
      categories = data['data'] ?? [];
    } catch (e) {}
  }

  String getSubjectName(String subjectId) {
    if (categories.isEmpty) return "Tutoría Activa";
    for (var category in categories) {
      if (category['subjects'] != null) {
        for (var subject in category['subjects']) {
          if (subject['id'].toString() == subjectId) {
            return subject['name'];
          }
        }
      }
    }
    return "Tutoría Activa"; 
  }
}