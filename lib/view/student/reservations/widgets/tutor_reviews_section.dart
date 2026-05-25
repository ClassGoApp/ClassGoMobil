import 'package:flutter/material.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/student/reservations/services/TutorReviewDto.dart';
import 'package:provider/provider.dart';

class TutorReviewsSection extends StatefulWidget {
  final List<TutorReviewDto> reviewList;
  final Function(double rating, String comment) onReviewSubmitted;

  const TutorReviewsSection({
    Key? key,
    required this.reviewList,
    required this.onReviewSubmitted,
  }) : super(key: key);

  @override
  State<TutorReviewsSection> createState() => _TutorReviewsSectionState();
}

class _TutorReviewsSectionState extends State<TutorReviewsSection> {
  final TextEditingController _reviewController = TextEditingController();
  double _userRating = 0.0;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bool hasAlreadyReviewed = widget.reviewList
        .any((review) => review.reviewerId == authProvider.userId);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =================================================================
          // 1. SECCIÓN PARA AÑADIR UNA NUEVA RESEÑA
          // =================================================================
          if (hasAlreadyReviewed)
            // 🚫 SI YA TIENE RESEÑA: Mostrar mensaje
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ya has dejado una valoración para este tutor. ¡Gracias por tu opinión!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // ✅ SI NO TIENE RESEÑA: Mostrar formulario
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deja tu valoración',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Fila de Estrellas interactivas
                Row(
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _userRating = index + 1.0;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(
                          index < _userRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),

                // Campo de texto para el comentario
                TextField(
                  controller: _reviewController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '¿Cómo fue tu experiencia con este tutor?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),

                // Botón de Enviar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final comment = _reviewController.text.trim();
                      widget.onReviewSubmitted(_userRating, comment);
                      _reviewController.clear();
                      setState(() {
                        _userRating = 0.0;
                      });
                    },
                    child: const Text(
                      'Publicar reseña',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ), // FIN del Column del formulario

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 20),

          // =================================================================
          // 2. SECCIÓN DE RESEÑAS EXISTENTES
          // =================================================================
          const Text(
            'Reseñas de estudiantes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Validación: Si está vacío muestra el texto, sino dibuja la lista
          if (widget.reviewList.isEmpty)
            const Text(
              'Este tutor todavía no tiene reseñas. ¡Sé el primero en opinar!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            )
          else
            ...widget.reviewList.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildReviewCard(
                  item.fullName,
                  item.rating,
                  item.comment,
                  item.timeAgo,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
      String name, double rating, String comment, String time) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dividerLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.greyFadeColor,
                child: const Icon(Icons.person,
                    color: AppColors.textLightPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLightPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textLightSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textLightSecondary,
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
          Text(
            comment,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textLightPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
