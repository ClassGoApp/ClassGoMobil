import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/view/student/reservations/services/TutorReviewDto.dart';

class TutorReviewsService {
  /// Obtiene las reseñas del tutor desde el backend API.
  static Future<List<TutorReviewDto>> fetchReviews(
      String token, String tutorId) async {
    final response = await getReviewTutor(token, tutorId);
    List<dynamic> rawReviews = [];
    if (response['data'] != null) {
      if (response['data'] is List) {
        rawReviews = response['data'] as List<dynamic>;
      } else if (response['data'] is Map && response['data']['data'] is List) {
        rawReviews = response['data']['data'] as List<dynamic>;
      }
    } else if (response['reviews'] != null && response['reviews'] is List) {
      rawReviews = response['reviews'] as List<dynamic>;
    }

    return rawReviews
        .map((item) => TutorReviewDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Envía una nueva reseña para un tutor.
  static Future<Map<String, dynamic>> submitReview({
    required String token,
    required int userId,
    required String tutorId,
    required double rating,
    required String comment,
  }) async {
    final tutorIdInt = int.tryParse(tutorId) ?? 0;
    return await createReview(
      token,
      userId,
      tutorIdInt,
      comment,
      rating,
    );
  }
}
