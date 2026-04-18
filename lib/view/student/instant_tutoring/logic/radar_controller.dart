import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_projects/view/student/instant_tutoring/widgets/tutor_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
// Asegúrate de importar tu TutorRes  ponse y constantes

class RadarController extends ChangeNotifier {
  final String subjectId;
  final int initialSeconds;

  int currentSeconds = 0;
  bool isSearching = true;
  List<TutorResponse> acceptedTutors = [];
  String? batchId;
  bool isProcessing = false; 

  Timer? _countdownTimer;
  Timer? _pollingTimer;

  RadarController({required this.subjectId, this.initialSeconds = 300}) {
    currentSeconds = initialSeconds;
    _initSearch();
  }

  // 1. INICIAR BÚSQUEDA
  Future<void> _initSearch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) return; 

      final data = await startRadarSearch(subjectId, token);

      batchId = data['batch_id']?.toString() ?? data['id']?.toString();
      print("✅ BATCH ID GUARDADO: $batchId");

      if (batchId != null && batchId!.isNotEmpty) {
        sendRadarEmails(
            int.parse(batchId!), token);
      }

      final String? expiresAtStr = data['expires_at'];
      if (expiresAtStr != null) {
        final DateTime expiresAt = DateTime.parse(expiresAtStr);
        final int secondsLeft = expiresAt.difference(DateTime.now()).inSeconds;
        currentSeconds = secondsLeft > 0 ? secondsLeft : 0;
      }

      _startTimers(token);
      notifyListeners();
    } catch (e) {
      print("🔥 Error en la búsqueda: $e");
    }
  }

  // 2. MANEJO DE TIMERS (Reloj y Polling)
  void _startTimers(String token) {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (currentSeconds > 0) {
        currentSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });

    // Polling al backend (3 segundos) usando la nueva API
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (batchId == null) return;
      try {
        final jsonResponse =
            await pollAcceptedTutors(batchId!, token);
        final List<dynamic> candidatosNuevos = jsonResponse['data'] ?? [];

        if (candidatosNuevos.isNotEmpty) {
          isSearching = false;
          acceptedTutors = candidatosNuevos.map<TutorResponse>((json) {
            // Lógica de formateo de imagen
            String img = json['image'] ?? 'assets/images/default_avatar.png';
            if (!img.startsWith('http') && !img.startsWith('assets')) {
              img = !img.startsWith('/') ? '/$img' : img;
              img = 'https://classgoapp.com/$img'; 
            }

            return TutorResponse(
              id: json['id'] ?? 0, 
              name: "${json['first_name'] ?? 'Tutor'} ${json['last_name'] ?? ''}".trim(),
              avatarUrl: img,
              isVerified:json['is_verified'] == 1 || json['is_verified'] == true,
              pricePerHour: "${json['price'] ?? '0.00'} Bs",
              rating:
                  double.tryParse(json['rating']?.toString() ?? '5.0') ?? 5.0,
            );
          }).toList();
          notifyListeners();
        }
      } catch (e) {
        print("Error silencioso en polling: $e");
      }
    });
  }

  // 3. RECHAZAR TUTOR LOCALMENTE
  void removeTutor(int index) {
    acceptedTutors.removeAt(index);
    if (acceptedTutors.isEmpty) {
      isSearching = true;
    }
    notifyListeners();
  }

  // 4. RESERVAR TUTOR (Checkout)
  Future<Map<String, dynamic>> confirmTutor(int itemId) async {
    isProcessing = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final resultado = await reserveTutor(int.parse(batchId!), itemId, token);
      return resultado;
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }
}
