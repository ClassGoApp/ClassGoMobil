import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/components/tutor_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class FeaturedTutorsSection extends StatelessWidget {
  final List<dynamic> tutors;
  final bool isLoading;
  final VoidCallback? onTutorTap;
  final ScrollController? scrollController;

  const FeaturedTutorsSection({
    Key? key,
    required this.tutors,
    required this.isLoading,
    this.onTutorTap,
    this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingSection();
    }

    if (tutors.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Text(
            'Tutores Destacados',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: tutors.length,
            itemBuilder: (context, index) {
              final tutor = tutors[index];
              return Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 280,
                                  child: TutorCard(
                  name: tutor['profile']['full_name'] ?? 'Tutor',
                  rating: (tutor['rating'] ?? 0.0).toDouble(),
                  reviews: tutor['reviews_count'] ?? 0,
                  imageUrl: tutor['profile']['image'] ?? '',
                  onRejectPressed: () {},
                  onAcceptPressed: onTutorTap ?? () {},
                  tutorProfession: 'Tutor',
                  sessionDuration: '60 min',
                  onFavoritePressed: (bool value) {},
                  subjectsString: (tutor['subjects'] as List?)?.map((s) => s['name']).join(', ') ?? '',
                  description: tutor['profile']['description'] ?? '',
                  isVerified: tutor['is_verified'] ?? false,
                  tutorId: tutor['id']?.toString(),
                  tutorVideo: tutor['profile']['video'],
                ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Shimmer.fromColors(
            baseColor: Colors.white.withOpacity(0.3),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Container(
              height: 20,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: 16),
                child: Shimmer.fromColors(
                  baseColor: Colors.white.withOpacity(0.3),
                  highlightColor: Colors.white.withOpacity(0.1),
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
