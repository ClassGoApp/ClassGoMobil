import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart'; // Importamos TUS colores
import 'package:flutter_projects/view/student/instant_tutoring/widgets/tutor_model.dart';

// 🎯 FUENTES CENTRALIZADAS
const String _kFontFamily = 'manrope';
const String _kTitleFont = 'outfit';

class TutorCardWidget extends StatelessWidget {
  final TutorResponse tutor;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const TutorCardWidget({
    super.key,
    required this.tutor,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.blackColor.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          // Info del Tutor
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(tutor.avatarUrl),
                backgroundColor: AppColors.fadeColor,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tutor.name,
                            style: const TextStyle(fontFamily: _kTitleFont, fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.blackColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (tutor.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: AppColors.brandBlue, size: 16),
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Disponible ahora", 
                      style: TextStyle(fontFamily: _kFontFamily, fontSize: 13, color: AppColors.stateSuccess, fontWeight: FontWeight.w600)
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    tutor.pricePerHour, 
                    style: const TextStyle(fontFamily: _kTitleFont, fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.brandBlue)
                  ),
                  const Text(
                    "Total aprox.", 
                    style: TextStyle(fontFamily: _kFontFamily, fontSize: 11, color: AppColors.greyColor)
                  ),
                ],
              )
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: AppColors.dividerColor),
          ),
          
          // Botones
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onReject,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Rechazar", style: TextStyle(fontFamily: _kFontFamily, color: AppColors.greyColor, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandCyan, // Usamos Cyan para que resalte como botón de acción principal
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Aceptar", style: TextStyle(fontFamily: _kFontFamily, color: AppColors.whiteColor, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}