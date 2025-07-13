import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/view/components/auth_required_modal.dart';

class AuthHelper {
  /// Verifica si el usuario está autenticado y muestra el modal si no lo está
  static bool requireAuth(
    BuildContext context, {
    String? customTitle,
    String? customMessage,
  }) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.token == null || authProvider.userId == null) {
      AuthRequiredModal.show(
        context,
        title: customTitle ?? 'Iniciar sesión requerido',
        message: customMessage ??
            'Para acceder a esta función, necesitas iniciar sesión en tu cuenta.',
      );
      return false;
    }

    return true;
  }

  /// Verifica si el usuario está autenticado sin mostrar modal
  static bool isAuthenticated(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.token != null && authProvider.userId != null;
  }

  /// Ejecuta una función solo si el usuario está autenticado
  static void executeIfAuthenticated(
    BuildContext context,
    VoidCallback onAuthenticated, {
    String? customTitle,
    String? customMessage,
  }) {
    if (requireAuth(context,
        customTitle: customTitle, customMessage: customMessage)) {
      onAuthenticated();
    }
  }

  static Future<void> loginAfterVerification(
      BuildContext context, String token, Map<String, dynamic> userData) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.setToken(token);
    await authProvider
        .setUserData({'user': userData}); // Asegura estructura correcta
    await authProvider.setAuthToken(token);
    await Future.delayed(
        Duration(milliseconds: 200)); // Da tiempo a notificar listeners
  }
}
