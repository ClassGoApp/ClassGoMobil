import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class ConnectivityProvider with ChangeNotifier {
  bool _isConnected = true;
  final Connectivity _connectivity = Connectivity();

  ConnectivityProvider() {
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    checkInitialConnection();
  }

  bool get isConnected => _isConnected;

  Future<void> checkInitialConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    _isConnected = connectivityResult != ConnectivityResult.none;
    notifyListeners();
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    _isConnected = result != ConnectivityResult.none;
    notifyListeners();
  }
}
