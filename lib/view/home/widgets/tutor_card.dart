import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter_projects/styles/app_styles.dart';


class TutorCard extends StatefulWidget {
  final Map<String, dynamic> tutor;
  final int index;
  final Function(int) onVideoTap;
  final Function(
          String, String, String, String, String, double, List<String>, int)
      onTutorTap;
  final Function(Map<String, dynamic>, Map<String, dynamic>, List, List)
      onStartTutoring;
  // ✅ OPTIMIZACIÓN: Pasar variables necesarias como parámetros
  final Map<int, String> highResTutorImages;
  final String baseImageUrl;
  final String baseVideoUrl;
  final double tutorCardWidth;
  final double tutorCardPadding;
  final double tutorCardImageHeight;
  final int? playingIndex;
  final VideoPlayerController? activeController;
  final bool isVideoLoading;
  final Function(String, int) buildVideoThumbnail;
  final Function(String) buildAvatarWithShimmer;

  const TutorCard({
    required this.tutor,
    required this.index,
    required this.onVideoTap,
    required this.onTutorTap,
    required this.onStartTutoring,
    required this.highResTutorImages,
    required this.baseImageUrl,
    required this.baseVideoUrl,
    required this.tutorCardWidth,
    required this.tutorCardPadding,
    required this.tutorCardImageHeight,
    required this.playingIndex,
    required this.activeController,
    required this.isVideoLoading,
    required this.buildVideoThumbnail,
    required this.buildAvatarWithShimmer,
  });

  @override
  State<TutorCard> createState() => _TutorCardState();
}

class _TutorCardState extends State<TutorCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive =>
      false; // ✅ OPTIMIZACIÓN: No mantener en memoria para reducir uso de RAM

  // ✅ OPTIMIZACIÓN: Método local para construir URLs
  String _getFullUrl(String path, String base) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return base + path;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Requerido por AutomaticKeepAliveClientMixin

    final tutor = widget.tutor;
    final profile = tutor['profile'] ?? {};
    final name = profile['full_name'] ?? 'Sin nombre';
    final List subjects = (tutor['subjects'] as List?) ?? [];
    final validSubjects = (subjects as List)
        .where((s) => s['status'] == 'active' && s['deleted_at'] == null)
        .map((s) => s['name'].toString())
        .toList();
    final rating =
        double.tryParse(tutor['avg_rating']?.toString() ?? '0.0') ?? 0.0;
    final imagePath = profile['image'] ?? '';
    final videoPath = profile['intro_video'] ?? '';
    final imageUrl = widget.highResTutorImages[tutor['id']] ??
        _getFullUrl(imagePath, widget.baseImageUrl);
    final videoUrl = _getFullUrl(videoPath, widget.baseVideoUrl);
    final completed = tutor['completed_courses_count'] ?? 0;
    final total = 18;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.tutorCardPadding),
      child: Container(
        width: widget.tutorCardWidth,
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: widget.tutorCardWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border:
                        Border.all(color: AppColors.lightBlueColor, width: 4),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: widget.tutorCardImageHeight,
                          child: widget.playingIndex == widget.index &&
                                  widget.activeController != null
                              ? (widget.isVideoLoading
                                  ? Positioned.fill(
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.lightBlueColor,
                                          strokeWidth: 4,
                                        ),
                                      ),
                                    )
                                  : Stack(
                                      children: [
                                        SizedBox.expand(
                                          child: VideoPlayer(
                                              widget.activeController!),
                                        ),
                                        Positioned.fill(
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () => widget
                                                  .onVideoTap(widget.index),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ))
                              : FittedBox(
                                  fit: BoxFit.cover,
                                  clipBehavior: Clip.hardEdge,
                                  child: SizedBox(
                                    width: widget.tutorCardWidth,
                                    height: widget.tutorCardImageHeight,
                                    child: widget.buildVideoThumbnail(
                                        videoUrl, widget.index),
                                  ),
                                ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.lightBlueColor,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.only(left: 65, right: 8),
                        child: GestureDetector(
                          onTap: () {
                            widget.onTutorTap(
                              tutor['id'].toString(),
                              profile['full_name'] ?? 'Sin nombre',
                              widget.highResTutorImages[tutor['id']] ??
                                  _getFullUrl(profile['image'] ?? '',
                                      widget.baseImageUrl),
                              profile['intro_video'] ?? '',
                              profile['description'] ?? 'Sin descripción',
                              rating,
                              validSubjects,
                              completed,
                            );
                          },
                          child: Text(
                            name,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Avatar sobrepuesto al borde inferior del video
                Positioned(
                  top: widget.tutorCardImageHeight - 24,
                  left: 16,
                  child: GestureDetector(
                    onTap: () {
                      widget.onTutorTap(
                        tutor['id'].toString(),
                        profile['full_name'] ?? 'Sin nombre',
                        widget.highResTutorImages[tutor['id']] ??
                            _getFullUrl(
                                profile['image'] ?? '', widget.baseImageUrl),
                        profile['intro_video'] ?? '',
                        profile['description'] ?? 'Sin descripción',
                        rating,
                        validSubjects,
                        completed,
                      );
                    },
                    child: widget.buildAvatarWithShimmer(imageUrl),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Indicador de materias
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 2.0, bottom: 2.0),
                      child: Text(
                        'Materias que imparte',
                        style: TextStyle(
                          color: AppColors.lightBlueColor.withOpacity(0.85),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  // Materias en chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: subjects
                          .map<Widget>((subject) => Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.lightBlueColor
                                      .withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  subject['name'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Cursos completados
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlueColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.menu_book,
                            color: AppColors.lightBlueColor, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '$completed/$total cursos completados',
                          style: const TextStyle(
                            color: AppColors.lightBlueColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Botón Empezar tutoría
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onStartTutoring(
                            tutor, profile, subjects, validSubjects);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orangeprimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_circle_fill,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Empezar tutoría',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}