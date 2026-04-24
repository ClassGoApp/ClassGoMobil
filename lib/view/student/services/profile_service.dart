import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileService {
  /// Obtiene la URL de la imagen de perfil del usuario.
  /// Devuelve `null` si no está disponible o si ocurre un error.
  static Future<String?> fetchProfileImage(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('https://classgoapp.com/api/user/$userId/profile-image'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['profile_image'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
