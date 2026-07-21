import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_projects/view/student/instant_tutoring/widgets/tutor_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_projects/api_structure/api_service.dart';

class RadarController extends ChangeNotifier {
  final String subjectId;
  final int initialSeconds;

  int currentSeconds = 0;
  bool isSearching = true;
  bool isTimeout = false;
  List<TutorResponse> acceptedTutors = [];
  String? batchId;
  bool isProcessing = false;
  bool isCancelling = false;

  Timer? _countdownTimer;
  Timer? _pollingTimer;

  RadarController({required this.subjectId, this.initialSeconds = 300}) {
    currentSeconds = initialSeconds;
    _initSearch();
  }

  // CREAR BATCH Y BUSCAR
  Future<void> _initSearch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) return;

      print("🕵️‍♂️ TIEMPO LOCAL INICIAL: $currentSeconds segundos");

      final data = await startRadarSearch(subjectId, token);

      batchId = data['batch_id']?.toString() ?? data['id']?.toString();
      print("✅ BATCH CREADO - ID: $batchId");
      
      final bool isAlreadyActive = data['already_active'] == true;

      if (batchId != null && batchId!.isNotEmpty && !isAlreadyActive) {
        sendRadarEmails(int.parse(batchId!), token);
      }

      currentSeconds = initialSeconds;

      _startTimers(token);
      notifyListeners();
    } catch (e) {
      print("🔥 Error Búsqueda: $e");
    }
  }

  // INICIAR RELOJ Y POLLING
  void _startTimers(String token) {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (currentSeconds > 0) {
        currentSeconds--;
        notifyListeners();
      } else {
        _triggerTimeout();
      }
    });

    // Preguntar al backend si alguien aceptó (Cada 3s)
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (batchId == null || isTimeout) return;
      try {
        final jsonResponse = await pollAcceptedTutors(batchId!, token);

        final String status =
            jsonResponse['status']?.toString().toLowerCase() ?? '';
        final List<dynamic> candidatosNuevos = jsonResponse['data'] ?? [];

        if (candidatosNuevos.isNotEmpty) {
          isSearching = false;
          acceptedTutors = candidatosNuevos.map<TutorResponse>((json) {
            String img = json['image'] ?? 'assets/images/default_avatar.png';
            
            // TODO: PRODUCCIÓN - Esta URL base debe ser dinámica (del .env o config)
            if (!img.startsWith('http') && !img.startsWith('assets')) {
              img = !img.startsWith('/') ? '/$img' : img;
              img = 'https://classgoapp.com$img';
            }

            return TutorResponse(
              id: json['id'] ?? 0,
              name: "${json['first_name'] ?? 'Tutor'} ${json['last_name'] ?? ''}".trim(),
              avatarUrl: img,
              isVerified: json['is_verified'] == 1 || json['is_verified'] == true,
              pricePerHour: "${json['price'] ?? '0.00'} Bs",
              rating: double.tryParse(json['rating']?.toString() ?? '5.0') ?? 5.0,
            );
          }).toList();
          
          print("👀 ${candidatosNuevos.length} Tutor(es) listos encontrados!");
          notifyListeners();
          return;
        }

        if (status == 'done' || status == 'failed' || status == 'expired') {
          print("🛑 El backend cerró el radar temprano con estado: $status");
          _triggerTimeout();
        }
      } catch (e) {
        print("Error silencioso en polling: $e");
      }
    });
  }

  void _triggerTimeout() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    currentSeconds = 0;
    isTimeout = true;
    notifyListeners();
  }

  // DESCARTAR TUTOR
  void removeTutor(int index) {
    acceptedTutors.removeAt(index);
    if (acceptedTutors.isEmpty) {
      isSearching = true;
    }
    notifyListeners();
  }

  // CANCELAR BÚSQUEDA
  Future<bool> cancelBatch() async {
    if (batchId == null || isCancelling) return false;

    isCancelling = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) return false;

      final result = await cancelRadarSearch(int.parse(batchId!), token);

      if (result['success'] == true) {
        _triggerTimeout();
        return true;
      }
      return false;
    } catch (e) {
      print("Error al cancelar batch: $e");
      return false;
    } finally {
      isCancelling = false;
      notifyListeners();
    }
  }

  // 5. CONFIRMAR (Ir a pago)
  Future<Map<String, dynamic>> confirmTutor(int itemId) async {
    isProcessing = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      return await reserveTutor(int.parse(batchId!), itemId, token);
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
