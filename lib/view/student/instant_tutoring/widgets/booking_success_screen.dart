import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

// Asegúrate de importar tu modelo
import 'tutor_model.dart'; 

const String _kFontFamily = 'manrope';
const String _kTitleFont = 'outfit';

class BookingSuccessScreen extends StatelessWidget {
  final TutorResponse tutor;
  final String subjectName;

  const BookingSuccessScreen({
    super.key,
    required this.tutor,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            physics: const BouncingScrollPhysics(),
            child: Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blackColor.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. ÍCONO DE ÉXITO (Gigante y verde)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.stateSuccess.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.stateSuccess,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. TÍTULOS
                  const Text(
                    "¡Clase Confirmada!",
                    style: TextStyle(
                      fontFamily: _kTitleFont,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blackColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Tu solicitud para la clase de $subjectName ha sido procesada exitosamente.",
                    style: const TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 15,
                      color: AppColors.greyColor,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // 3. TARJETA DE DETALLES (Gris clarito)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.fadeColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Detalles de la sesión",
                          style: TextStyle(
                            fontFamily: _kTitleFont,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blackColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Fila del Tutor
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(tutor.avatarUrl),
                              backgroundColor: AppColors.whiteColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          tutor.name,
                                          style: const TextStyle(fontFamily: _kFontFamily, fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.blackColor),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (tutor.isVerified) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.verified, color: AppColors.brandBlue, size: 14),
                                      ]
                                    ],
                                  ),
                                  const Text(
                                    "Tutor asignado",
                                    style: TextStyle(fontFamily: _kFontFamily, fontSize: 12, color: AppColors.greyColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1, color: AppColors.dividerColor),
                        ),

                        // Filas de Info (Dummy Date por ahora)
                        _buildDetailRow(Icons.calendar_month_rounded, "Fecha y hora", "Hoy, en unos minutos"),
                        const SizedBox(height: 12),
                        _buildDetailRow(Icons.payments_rounded, "Precio", tutor.pricePerHour),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 4. BOTONES DE ACCIÓN
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        print("🚀 Ir a la sala de espera o videollamada");
                        // TODO: Navegar a la sala de chat/video
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        "Ir a la clase",
                        style: TextStyle(fontFamily: _kFontFamily, color: AppColors.whiteColor, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Navegar de vuelta al dashboard/inicio (Borra el historial del radar)
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.dividerColor, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        "Volver al inicio",
                        style: TextStyle(fontFamily: _kFontFamily, color: AppColors.greyColor, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget de apoyo para las filas de detalles
  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.greyColor),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontFamily: _kFontFamily, fontSize: 14, color: AppColors.greyColor)),
        const Spacer(),
        Text(value, style: const TextStyle(fontFamily: _kTitleFont, fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.blackColor)),
      ],
    );
  }
}