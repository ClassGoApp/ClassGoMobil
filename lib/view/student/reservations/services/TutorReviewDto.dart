class TutorReviewDto {
  final int id;
  final int userId;
  final int reviewerId;
  final int reviewId;

  final String createdAt;
  final String updatedAt;

  final int reviewerUserId;
  final String reviewerEmail;

  final int profileId;
  final String firstName;
  final String lastName;
  final String? image;
  final String phoneNumber;
  final String? description;

  final int reviewDetailId;
  final double rating;
  final String comment;
  final String status;

  TutorReviewDto({
    required this.id,
    required this.userId,
    required this.reviewerId,
    required this.reviewId,
    required this.createdAt,
    required this.updatedAt,
    required this.reviewerUserId,
    required this.reviewerEmail,
    required this.profileId,
    required this.firstName,
    required this.lastName,
    required this.image,
    required this.phoneNumber,
    required this.description,
    required this.reviewDetailId,
    required this.rating,
    required this.comment,
    required this.status,
  });

  factory TutorReviewDto.fromJson(Map<String, dynamic> json) {
    final reviewer = json['reviewer'] ?? {};
    final profile = reviewer['profile'] ?? {};
    final review = json['review'] ?? {};

    return TutorReviewDto(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      reviewerId: json['reviewer_id'] ?? 0,
      reviewId: json['review_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      reviewerUserId: reviewer['id'] ?? 0,
      reviewerEmail: reviewer['email'] ?? '',
      profileId: profile['id'] ?? 0,
      firstName: profile['first_name'] ?? '',
      lastName: profile['last_name'] ?? '',
      image: profile['image'],
      phoneNumber: profile['phone_number'] ?? '',
      description: profile['description'],
      reviewDetailId: review['id'] ?? 0,
      rating: double.tryParse(review['rating']?.toString() ?? '0') ?? 0.0,
      comment: review['comment'] ?? '',
      status: review['status'] ?? '',
    );
  }

  String get fullName {
    return '$firstName $lastName'.trim();
  }

  String get timeAgo {
    if (createdAt.isEmpty) return '';

    final date = DateTime.tryParse(createdAt);
    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 mes atrás' : '$months meses atrás';
    }

    if (difference.inDays >= 7) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 semana atrás' : '$weeks semanas atrás';
    }

    if (difference.inDays >= 1) {
      return difference.inDays == 1
          ? '1 día atrás'
          : '${difference.inDays} días atrás';
    }

    if (difference.inHours >= 1) {
      return difference.inHours == 1
          ? '1 hora atrás'
          : '${difference.inHours} horas atrás';
    }

    return 'Hace unos minutos';
  }
}
