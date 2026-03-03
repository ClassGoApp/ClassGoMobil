import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_projects/api_structure/api_service.dart'; // Ajusta tus rutas

class TutorProvider with ChangeNotifier {
  List<dynamic> _featuredTutors = [];
  bool _isLoadingTutors = false;

  List<dynamic> get featuredTutors => _featuredTutors;
  bool get isLoadingTutors => _isLoadingTutors;

  Future<void> fetchFeaturedAndVerified(String? token) async {
    if (token == null) return;
    
    _isLoadingTutors = true;
    notifyListeners();

    try {
      // 1. Obtener datos de API en paralelo (más rápido)
      final results = await Future.wait([
        findTutors(token, perPage: 1000),
        getVerifiedTutors(token, perPage: 1000),
      ]);

      final response = results[0];
      final verifiedResponse = results[1];

      // 2. Extraer listas (Lógica que antes ensuciaba la Home)
      List<dynamic> tutors = _extractList(response);
      List<dynamic> verifiedTutors = _extractList(verifiedResponse);

      // 3. Unir sin duplicados
      final allTutorsMap = <int, dynamic>{};
      for (var t in tutors) {
        if (t['id'] != null) allTutorsMap[t['id']] = t;
      }
      for (var t in verifiedTutors) {
        if (t['id'] != null) allTutorsMap[t['id']] = t;
      }

      // 4. Filtrar y guardar
      _featuredTutors = allTutorsMap.values
          .where((t) => t['subjects'] != null && (t['subjects'] as List).isNotEmpty)
          .toList();

    } catch (e) {
      print('❌ Error en TutorProvider: $e');
      rethrow; // Dejamos que la UI decida si muestra un SnackBar
    } finally {
      _isLoadingTutors = false;
      notifyListeners();
    }
  }

  // Método de apoyo para limpiar el JSON
  List<dynamic> _extractList(Map<String, dynamic> response) {
    if (response.containsKey('data')) {
      final data = response['data'];
      if (data is Map) {
        if (data.containsKey('list')) return data['list'];
        if (data.containsKey('data')) return data['data'];
      }
      if (data is List) return data;
    }
    return [];
  }
}