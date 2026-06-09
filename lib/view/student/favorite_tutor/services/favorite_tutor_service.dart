import 'package:flutter_projects/api_structure/api_service.dart';

class FavoriteTutorService {
  static Future<String?> getFavoriteName(
      {required String? token, required int studentId}) async {
    try {
      final favs = await getFavourites(token, studentId);
      for (final fav in favs) {
        // Intentar extraer el campo 'name' en distintas formas
        final name = fav['name'] ??
            fav['full_name'] ??
            fav['user']?['name'] ??
            fav['user']?['full_name'];

        if (name != null && name.toString().trim().isNotEmpty) {
          final n = name.toString().trim();
          return n;
        }
      }
    } catch (e) {
      // Ignorar y retornar null si algo falla
      print('Error en getFavoriteName: $e');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> fetchFavoriteDetails(
      {required String? token, required int studentId}) async {
    try {
      final favs = await getFavourites(token, studentId);
      if (favs.isEmpty) return [];

      final names = favs
          .map((fav) => fav['name'] ?? fav['full_name'] ?? fav['user']?['name'])
          .where((name) => name != null && name.toString().trim().isNotEmpty)
          .map((name) => name.toString().trim())
          .toSet()
          .toList();

      if (names.isEmpty) return [];

      final responses = await Future.wait(
        names.map(
          (name) => getVerifiedTutors(
            token,
            page: 1,
            perPage: 10,
            tutorName: name,
          ),
        ),
      );

      final List<Map<String, dynamic>> allTutors = [];
      final Set<String> seenIds = <String>{};

      for (final response in responses) {
        final tutorsList = _extractTutorsFromAvailableResponse(response);
        for (final tutor in tutorsList) {
          final idKey = (tutor['id'] ??
                  tutor['user_id'] ??
                  tutor['slug'] ??
                  tutor['name'])
              .toString();
          if (idKey.isEmpty || seenIds.contains(idKey)) continue;
          seenIds.add(idKey);
          allTutors.add(tutor);
        }
      }

      return allTutors;
    } catch (e) {
      print('Error al obtener detalles del tutor favorito: $e');
      return [];
    }
  }

  static List<Map<String, dynamic>> _extractTutorsFromAvailableResponse(
      Map<String, dynamic> response) {
    List<dynamic> tutorsList = [];

    if (response['data'] is List) {
      tutorsList = response['data'] as List<dynamic>;
    } else if (response['data'] is Map) {
      final data = response['data'] as Map;
      if (data['data'] is List) {
        tutorsList = data['data'] as List<dynamic>;
      } else if (data['list'] is List) {
        tutorsList = data['list'] as List<dynamic>;
      }
    }

    return tutorsList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<Map<String, dynamic>> removeFavorite({
    required String token,
    required int studentId,
    required int tutorId,
  }) async {
    try {
      // 👇 aquí llamas a tu función existente
      final response = await deleteFavourite(token, studentId, tutorId);

      return response;
    } catch (e) {
      throw Exception('Error removing favorite: $e');
    }
  }

  static Future<Map<String, dynamic>> addFavorite({
    required String token,
    required int studentId,
    required int tutorId,
  }) async {
    try {
      final response = await addFavourite(token, studentId, tutorId);

      return response;
    } catch (e) {
      throw Exception('Error adding favorite: $e');
    }
  }
}
