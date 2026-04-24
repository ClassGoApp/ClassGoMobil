import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_projects/api_structure/api_service.dart';

class PaymentController extends ChangeNotifier {
  File? receiptImage;
  bool isSubmitting = false;
  bool isWaitingForTutor = false;

  final ImagePicker _picker = ImagePicker();

  // 1. SELECCIONAR IMAGEN DE LA GALERÍA
  Future<void> pickImage(Function(String) onError) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        receiptImage = File(image.path);
        notifyListeners();
      }
    } catch (e) {
      onError('Error al abrir la galería');
    }
  }

  // 2. QUITAR IMAGEN SELECCIONADA
  void removeImage() {
    receiptImage = null;
    notifyListeners();
  }

  // 3. SUBIR COMPROBANTE AL BACKEND
  Future<void> submitPayment({
    required int bookingId,
    required Function(String meetLink) onTutorAccepted,
    required VoidCallback onTutorRejected,
    required Function(String error) onError,
  }) async {
    if (receiptImage == null) return;

    isSubmitting = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final miToken = prefs.getString('token') ?? '';

      if (miToken.isEmpty) {
        throw Exception(
            "No tienes una sesión activa. Vuelve a iniciar sesión.");
      }

      final uploadResponse =
          await subirComprobante(bookingId, receiptImage!.path, miToken);

      if (uploadResponse['ok'] == true || uploadResponse['success'] == true) {
        // Mostrar pantalla de "comprobante enviado" y redirigir tras 3 segundos.
        isSubmitting = false;
        isWaitingForTutor = true;
        notifyListeners();

        // Espera 3 segundos y luego notifica aceptación para que la UI navegue.
        await Future.delayed(const Duration(seconds: 3));
        isWaitingForTutor = false;
        notifyListeners();

        String linkGenerado =
            uploadResponse['meeting_link'] ?? 'https://meet.google.com/...';
        onTutorAccepted(linkGenerado);
      } else {
        throw Exception(
            uploadResponse['message'] ?? 'Error al subir el comprobante');
      }
    } catch (e) {
      isSubmitting = false;
      notifyListeners();
      onError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
