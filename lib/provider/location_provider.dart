import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';

class LocationProvider with ChangeNotifier {
  List<Map<String, dynamic>> countries = [];
  List<Map<String, dynamic>> states = [];

  bool isLoadingCountries = false;
  bool isLoadingStates = false;

  void clearStates() {
    states = [];
    isLoadingStates = false;
    notifyListeners();
  }

  Future<void> Countries(String token) async {
    isLoadingCountries = true;
    notifyListeners();
    
    final response = await fetchCountries(token);
    if (response['success'] == true) {
      countries = List<Map<String, dynamic>>.from(response['data']);
    }
    isLoadingCountries = false;
    notifyListeners();
  }

  Future<void> States(String token, int countryId) async {
    states = [];
    isLoadingStates = true;
    notifyListeners();
    
    if (countryId == 0) {
      isLoadingStates = false;  
      notifyListeners();
      return;
    }

    final response = await fetchStates(token, countryId);
    if (response['success'] == true) {
      states = List<Map<String, dynamic>>.from(response['data']);
    } else {
      states = [];
    }
    isLoadingStates = false;
    notifyListeners();
  }
}