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
    try {
      print('AuthHelper: Iniciando login después de verificación...');
      print('AuthHelper: Token: ${token.substring(0, 20)}...');
      print('AuthHelper: UserData: $userData');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Guardar token
      print('AuthHelper: Guardando token...');
      await authProvider.setToken(token);
      print('AuthHelper: Token guardado');

      // Guardar datos del usuario con estructura correcta
      print('AuthHelper: Guardando datos de usuario...');
      await authProvider.setUserData({'user': userData});
      print('AuthHelper: Datos de usuario guardados');

      // Configurar autenticación completa (con manejo de errores)
      print('AuthHelper: Configurando autenticación completa...');
      try {
        await authProvider.setAuthToken(token);
        print('AuthHelper: Autenticación completa configurada');
      } catch (e) {
        print('AuthHelper: Error en setAuthToken (probablemente FCM): $e');
        print('AuthHelper: Continuando sin FCM...');
        // No propagamos el error para no bloquear el login
      }

      // Dar tiempo a que se notifiquen los listeners
      await Future.delayed(Duration(milliseconds: 500));
      print('AuthHelper: Login después de verificación completado');

      // Verificar que todo se guardó correctamente
      print('AuthHelper: Verificando estado de autenticación...');
      print('AuthHelper: isLoggedIn: ${authProvider.isLoggedIn}');
      print('AuthHelper: userId: ${authProvider.userId}');
      print('AuthHelper: userData: ${authProvider.userData}');
    } catch (e) {
      print('AuthHelper: Error durante login después de verificación: $e');
      // Solo propagamos errores que no sean de FCM
      if (!e.toString().contains('SERVICE_NOT_AVAILABLE') &&
          !e.toString().contains('firebase_messaging')) {
        rethrow;
      } else {
        print(
            'AuthHelper: Error de FCM ignorado, login completado exitosamente');
      }
    }
  }
}
