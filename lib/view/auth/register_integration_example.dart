import 'package:flutter/material.dart';
import 'package:flutter_projects/helpers/registration_helper.dart';
import 'package:flutter_projects/helpers/email_verification_helper.dart';

/// Ejemplo de cómo integrar el sistema de verificación en una pantalla de registro existente
///
/// Para usar este sistema en tu pantalla de registro actual:
///
/// 1. Importa los helpers necesarios:
/// ```dart
/// import 'package:flutter_projects/helpers/registration_helper.dart';
/// import 'package:flutter_projects/helpers/email_verification_helper.dart';
/// ```
///
/// 2. En tu función de registro exitoso, reemplaza la navegación al login por:
/// ```dart
/// RegistrationHelper.handleSuccessfulRegistration(context, userData);
/// ```
///
/// 3. Para manejar errores de registro:
/// ```dart
/// RegistrationHelper.handleRegistrationError(context, errorMessage);
/// ```
///
/// 4. Para validar datos antes del registro:
/// ```dart
/// if (!RegistrationHelper.validateRegistrationData(userData)) {
///   // Mostrar error de validación
///   return;
/// }
/// ```

class RegisterIntegrationExample {
  /// Ejemplo de función de registro que usa el nuevo sistema
  static Future<void> handleUserRegistration(
    BuildContext context,
    Map<String, dynamic> userData,
  ) async {
    try {
      // Validar datos del formulario
      if (!RegistrationHelper.validateRegistrationData(userData)) {
        RegistrationHelper.handleRegistrationError(
          context,
          'Por favor, completa todos los campos correctamente.',
        );
        return;
      }

      // Simular llamada al API de registro
      // En tu implementación real, aquí iría tu llamada al API
      await Future.delayed(Duration(seconds: 2));

      // En caso de éxito, redirigir a la pantalla de verificación
      RegistrationHelper.handleSuccessfulRegistration(context, userData);
    } catch (e) {
      RegistrationHelper.handleRegistrationError(
        context,
        'Error al registrar usuario. Por favor, inténtalo de nuevo.',
      );
    }
  }

  /// Ejemplo de función para reenviar email desde cualquier pantalla
  static Future<void> resendEmailFromAnywhere(
    BuildContext context,
    String email,
  ) async {
    try {
      final result =
          await EmailVerificationHelper.resendVerificationEmail(email);
      EmailVerificationHelper.showResultSnackBar(context, result);
    } catch (e) {
      EmailVerificationHelper.showResultSnackBar(
        context,
        {
          'success': false,
          'message': 'Error al reenviar el email. Inténtalo de nuevo.',
        },
      );
    }
  }

  /// Ejemplo de cómo manejar deep links manualmente
  static void handleManualDeepLink(BuildContext context, String link) {
    // Esto se maneja automáticamente por el DeepLinkService
    // pero puedes usarlo manualmente si es necesario
    print('Deep link recibido: $link');
  }
}

/// Ejemplo de widget que muestra el estado de verificación
class VerificationStatusWidget extends StatelessWidget {
  final bool isVerified;
  final VoidCallback? onResendEmail;
  final String email;

  const VerificationStatusWidget({
    Key? key,
    required this.isVerified,
    this.onResendEmail,
    required this.email,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isVerified
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.warning,
            color: isVerified ? Colors.green : Colors.orange,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVerified
                      ? 'Email verificado'
                      : 'Email pendiente de verificación',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isVerified ? Colors.green : Colors.orange,
                  ),
                ),
                if (!isVerified) ...[
                  SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isVerified && onResendEmail != null) ...[
            TextButton(
              onPressed: onResendEmail,
              child: Text(
                'Reenviar',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
