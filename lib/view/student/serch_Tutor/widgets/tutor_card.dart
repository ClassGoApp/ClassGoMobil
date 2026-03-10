import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/student/services/text_normalization.dart';

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
  final List<String>? matchedSubjects; // Materias coincidentes con la búsqueda
  final String? searchKeyword; // Keyword de búsqueda para priorizar materias

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
    this.matchedSubjects,
    this.searchKeyword,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con avatar, nombre y favorito
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar circular
                Hero(
                  tag: 'tutor-image-${widget.tutorId}',
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryGreen.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.greyColor.withOpacity(0.1),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.greyColor.withOpacity(0.1),
                          child: const Icon(Icons.person,
                              color: AppColors.greyColor, size: 36),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Nombre, rating, info y favorito (favorito dentro del Expanded para evitar overflow)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row superior: nombre + verificado  + favorito al final
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.blackColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.isVerified) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.verified,
                                    color: AppColors.lightBlueColor,
                                    size: 18,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isFavorite = !_isFavorite;
                                widget.onFavoritePressed(_isFavorite);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isFavorite
                                    ? Colors.red
                                    : AppColors.greyColor.withOpacity(0.6),
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Rating y reseñas (permitir que fluyan y reduzcan tamaño cuando sea necesario)
                      Row(
                        children: [
                          Icon(Icons.star,
                              color: AppColors.starYellow, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            widget.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blackColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '(${widget.reviews} reseñas)',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.greyColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Descripción/Tagline
            if (widget.tagline != null && widget.tagline!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  widget.tagline!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.greyColor.withOpacity(0.9),
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // Chips de materias
            _buildSubjectChipsWrapped(widget.subjectsString),
            const SizedBox(height: 16),
            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onRejectPressed,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.greyColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    child: Text(
                      'Ver Perfil',
                      style: TextStyle(
                        color: AppColors.blackColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onAcceptPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.showStartButton
                              ? Icons.play_circle_fill
                              : Icons.calendar_today,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.showStartButton ? 'Empezar' : 'Agendar',
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
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectChipsWrapped(String subjects,
      {List<String>? matchedSubjects}) {
    final subjectList = subjects
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (subjectList.isEmpty) return SizedBox.shrink();

    // Determinar materias que coinciden (prioridad)
    List<String> matched = [];
    if (matchedSubjects != null && matchedSubjects.isNotEmpty) {
      matched = matchedSubjects
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      // Filtrar solo las que realmente existen en subjectList (comparación normalizada)
      matched = matched
          .where((m) =>
              subjectList.any((s) => normalize(s).contains(normalize(m))))
          .toList();
    } else if (widget.searchKeyword != null &&
        widget.searchKeyword!.trim().isNotEmpty) {
      final key = normalize(widget.searchKeyword!);
      matched = subjectList.where((s) => normalize(s).contains(key)).toList();
    }

    // Construir orden: matched primero (sin duplicados), luego el resto en su orden original
    final matchedLower = matched.map((m) => m.toLowerCase()).toSet();
    final remaining = subjectList
        .where((s) => !matchedLower.contains(s.toLowerCase()))
        .toList();
    final ordered = [...matched, ...remaining];

    // Mostrar solo las primeras 3 del orden resultante
    final displaySubjects =
        ordered.length > 3 ? ordered.take(3).toList() : ordered;

    // Límite de caracteres cuando NO estamos buscando (mostrar puntos suspensivos)
    const int charLimit = 20;
    final bool isSearching =
        widget.searchKeyword != null && widget.searchKeyword!.trim().isNotEmpty;

    String _formatSubject(String s) {
      if (isSearching) return s; // mostrar completo al buscar por materia
      if (s.length <= charLimit) return s;
      final end = min(charLimit - 1, s.length);
      return s.substring(0, end) + '...';
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...displaySubjects.map((subject) => Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.lightBlueColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatSubject(subject),
                style: TextStyle(
                  color: AppColors.lightBlueColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                // Si estamos en búsqueda, permitir que el texto se muestre completo
                overflow:
                    isSearching ? TextOverflow.visible : TextOverflow.ellipsis,
                maxLines: isSearching ? 2 : 1,
              ),
            )),
        // Mostrar contador si hay más materias en el orden completo
        if (ordered.length > displaySubjects.length)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.lightBlueColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${ordered.length - displaySubjects.length}',
              style: TextStyle(
                color: AppColors.lightBlueColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
