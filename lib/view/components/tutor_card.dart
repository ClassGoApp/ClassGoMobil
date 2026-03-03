import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class TutorCard extends StatefulWidget {
  final String name;
  final double rating;
  final int reviews;
  final String imageUrl;
  final VoidCallback onRejectPressed;
  final VoidCallback onAcceptPressed;
  final String tutorProfession;
  final String sessionDuration;
  final bool isFavoriteInitial;
  final ValueChanged<bool> onFavoritePressed;
  final String subjectsString; // Renombrado
  final String description; // Nuevo campo para la descripción real
  final String? tagline; // Nuevo campo para el tagline
  final bool isVerified;
  final String? tutorId;
  final String? tutorVideo;
  final bool showStartButton; // Nuevo parámetro

  const TutorCard({
    Key? key,
    required this.name,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    required this.onRejectPressed,
    required this.onAcceptPressed,
    required this.tutorProfession,
    required this.sessionDuration,
    this.isFavoriteInitial = false,
    required this.onFavoritePressed,
    required this.subjectsString, // Renombrado
    required this.description, // Nuevo
    this.tagline,
    required this.isVerified,
    this.tutorId,
    this.tutorVideo,
    this.showStartButton = false, // Valor por defecto
  }) : super(key: key);

  @override
  State<TutorCard> createState() => _TutorCardState();
}

class _TutorCardState extends State<TutorCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavoriteInitial;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      color: AppColors.primaryGreen,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: AppColors.dividerColor, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'tutor-image-${widget.tutorId}',
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: CachedNetworkImage(
                          imageUrl: widget.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 60,
                            height: 60,
                            color: AppColors.dividerColor,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 60,
                            height: 60,
                            color: AppColors.dividerColor,
                            child: const Icon(Icons.person,
                                color: AppColors.greyColor, size: 32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.name,
                                    style: AppTextStyles.heading2
                                        .copyWith(color: AppColors.whiteColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.isVerified)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: Icon(
                                      Icons.verified,
                                      color: AppColors.blueColor,
                                      size: 18,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.star,
                              color: AppColors.starYellow, size: 16),
                          Text(
                            '${widget.rating}',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.whiteColor),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isFavorite = !_isFavorite;
                                widget.onFavoritePressed(_isFavorite);
                              });
                            },
                            child: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isFavorite
                                  ? AppColors.blueColor
                                  : AppColors.lightGreyColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.tagline ?? 'Tutor de ClassGo',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.lightGreyColor,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.book, color: AppColors.greyColor, size: 20),
                const SizedBox(width: 5),
                Expanded(
                  child: _buildSubjectChipsHorizontal(widget.subjectsString),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onRejectPressed, // Llamar al callback
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      minimumSize: const Size(double.infinity, 28),
                    ),
                    child: Text(
                      'Ver Perfil',
                      style: AppTextStyles.button
                          .copyWith(color: AppColors.whiteColor),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        widget.onAcceptPressed, // Puedes cambiar el callback
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orangeprimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      minimumSize: const Size(double.infinity, 28),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        widget.showStartButton
                            ? const Icon(Icons.play_circle_fill,
                                color: Colors.white, size: 22)
                            : const Icon(Icons.calendar_today,
                                color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.showStartButton
                                ? 'Empezar tutoría'
                                : 'Agendar',
                            style: AppTextStyles.button.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15, // Puedes bajarlo a 15 o 14 si sigue el problema
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectChipsHorizontal(String subjects) {
    // Separa las materias por coma y limpia espacios
    final subjectList = subjects
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (subjectList.isEmpty) {
      return Text(
        'Sin materias especificadas',
        style: AppTextStyles.body.copyWith(
          color: AppColors.lightGreyColor,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Si hay más de 4 materias, mostrar solo las primeras 3 + contador
    final displaySubjects =
        subjectList.length > 4 ? subjectList.take(3).toList() : subjectList;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...displaySubjects
              .map((subject) => Container(
                    margin: EdgeInsets.only(right: 6),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      border: Border.all(
                          color: AppColors.blueColor.withOpacity(0.8),
                          width: 1.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      subject,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.whiteColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ))
              .toList(),

          // Mostrar contador si hay más de 4 materias
          if (subjectList.length > 4)
            Container(
              margin: EdgeInsets.only(right: 6),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.orangeprimary.withOpacity(0.8),
                border: Border.all(
                    color: AppColors.orangeprimary.withOpacity(0.3), width: 1),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.orangeprimary.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '+${subjectList.length - 3}',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.whiteColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
