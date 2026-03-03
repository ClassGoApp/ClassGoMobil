import 'package:flutter/material.dart';
import 'package:flutter_projects/view/auth/verification_pending_screen.dart';

class RegistrationHelper {
  /// Maneja el registro exitoso y redirige a la pantalla de verificación
  static void handleSuccessfulRegistration(
    BuildContext context,
    Map<String, dynamic> userData,
  ) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => VerificationPendingScreen(userData: userData),
      ),
      (Route<dynamic> route) => false,
    );
  }

  /// Maneja errores de registro
  static void handleRegistrationError(
    BuildContext context,
    String errorMessage,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Valida los datos del formulario de registro
  static bool validateRegistrationData(Map<String, dynamic> data) {
    final requiredFields = ['name', 'email', 'password'];

    for (String field in requiredFields) {
      if (data[field] == null || data[field].toString().trim().isEmpty) {
        return false;
      }
    }

    // Validar formato de email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(data['email'])) {
      return false;
    }

    // Validar longitud de contraseña
    if (data['password'].toString().length < 6) {
      return false;
    }

    return true;
  }
}
