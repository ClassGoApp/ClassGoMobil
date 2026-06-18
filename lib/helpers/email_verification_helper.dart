import 'package:flutter_projects/api_structure/api_service.dart' as api;

class EmailVerificationHelper {
  /// Reenvía el email de verificación
  static Future<Map<String, dynamic>> resendVerificationEmail(
      String token) async {
    return await api.resendEmail(token);
  }

  /// Verifica el email usando el API
  static Future<Map<String, dynamic>> verifyEmail(String id, String hash) async {
    return await api.verifyEmail(id, hash);
  }
}
