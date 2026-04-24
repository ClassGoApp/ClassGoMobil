import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/tutor/features/Instant_tutoring/accept_tutoring_screen.dart';
import 'package:flutter_projects/view/tutor/features/Instant_tutoring/confirmation_tutoring_screen.dart';
import 'package:flutter_projects/view/tutor/features/Instant_tutoring/view_wait_tutoring_screen.dart';
import 'package:flutter_projects/view/tutor/features/home/providers/tutor_home_provider.dart';
import 'package:provider/provider.dart';

class SolicitudTutoriaCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const SolicitudTutoriaCard({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<TutorHomeProvider>(context);
    final isExpired = homeProvider.isRequestExpired;
    final isRejected = homeProvider.isRequestRejected;
    final isChosen = homeProvider.isRequestChosen;
    final isReady = homeProvider.isTutoringReady; // ¡ESTADO FINAL!
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colores de fondo dinámicos según el estado
    List<Color> gradientColors;
    if (isReady) {
      gradientColors = [
        const Color(0xFFFFB74D), // Naranja medio claro
        const Color(0xFFFB8C00), // Naranja vibrante
      ];
    } else if (isChosen) {
      gradientColors = [
        const Color(0xFF065F46), // Emerald-800
        const Color(0xFF0F766E), // Teal-700
      ];
    } else if (isRejected) {
      gradientColors = [
        const Color(0xFF0F172A), // Slate-900
        const Color(0xFF1E293B), // Slate-800
      ];
    } else if (isExpired) {
      gradientColors = [
        isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0),
        isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      ];
    } else {
      gradientColors = [
        const Color(0xFF003049),
        const Color(0xFF005B7F),
      ];
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isReady
                    ? const Color(0xFFFB8C00).withOpacity(0.4)
                    : isChosen
                        ? const Color(0xFF065F46).withOpacity(0.3)
                        : isRejected
                            ? Colors.black.withOpacity(0.3)
                            : isExpired
                                ? Colors.black12
                                : const Color(0xFF003049).withOpacity(0.2)),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Elemento decorativo de fondo (Círculo)
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isReady
                          ? Colors.white
                          : isChosen
                              ? Colors.tealAccent
                              : isRejected
                                  ? Colors.amber
                                  : isExpired
                                      ? Colors.grey
                                      : AppColors.brandCyan)
                      .withOpacity(0.1),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icono con contenedor estilizado
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isReady
                              ? Colors.white.withOpacity(0.2)
                              : isChosen
                                  ? Colors.tealAccent.withOpacity(0.1)
                                  : isRejected
                                      ? Colors.amber.withOpacity(0.15)
                                      : isExpired
                                          ? Colors.grey.withOpacity(0.2)
                                          : AppColors.brandCyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          isReady
                              ? Icons.video_camera_front_rounded
                              : isChosen
                                  ? Icons.verified_rounded
                                  : isRejected
                                      ? Icons.info_rounded
                                      : isExpired
                                          ? Icons.timer_off_outlined
                                          : Icons.bolt_rounded,
                          color: isReady
                              ? Colors.white
                              : isChosen
                                  ? Colors.tealAccent
                                  : isRejected
                                      ? const Color(0xFFFFC107)
                                      : isExpired
                                          ? Colors.grey
                                          : AppColors.brandCyan,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isReady
                                  ? '¡TUTORÍA LISTA!'
                                  : isChosen
                                      ? '¡FUISTE ELEGIDO!'
                                      : isRejected
                                          ? 'SOLICITUD YA TOMADA'
                                          : isExpired
                                              ? 'SOLICITUD EXPIRADA'
                                              : '¡NUEVA SOLICITUD!',
                              style: TextStyle(
                                fontFamily: 'outfit',
                                fontSize: isReady ? 16 : 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: isReady ? 0.3 : 1.2,
                                color: isReady
                                    ? Colors.white
                                    : isChosen
                                        ? Colors.tealAccent
                                        : isRejected
                                            ? const Color(0xFFFFC107)
                                            : isExpired
                                                ? Colors.grey
                                                : AppColors.brandCyan,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isReady
                                  ? 'El pago fue confirmado. ¡Entra a la clase ahora!'
                                  : isChosen
                                      ? 'El estudiante está pagando. Toca para ver detalles.'
                                      : isRejected
                                          ? 'Esta tutoría ya ha sido asignada a otro profesor'
                                          : isExpired
                                              ? 'Esta invitación ya no está disponible'
                                              : 'Un estudiante necesita tu ayuda ahora',
                              style: TextStyle(
                                fontFamily: 'manrope',
                                fontSize: isReady ? 14 : 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isExpired || isRejected || isReady)
                        IconButton(
                          onPressed: () => homeProvider.clearPendingRequest(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close_rounded,
                              size: 20, color: Colors.white70),
                        ),
                    ],
                  ),
                  if (!isExpired && !isRejected) ...[
                    const SizedBox(height: 12),
                    // Botón de acción Premium
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (isReady
                                    ? Colors.black12
                                    : isChosen
                                        ? Colors.teal
                                        : AppColors.brandCyan)
                                .withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          // 1. CASO: Tutoría Lista (Entrar a Meet)
                          if (isReady && homeProvider.activeMeetLink != null) {
                            homeProvider.openMeetLink(context, homeProvider.activeMeetLink!);
                            return;
                          }

                          // 2. CASO: Fuiste elegido (Esperar pago)
                          if (isChosen) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const VistaFuisteElegido(),
                              ),
                            );
                            return;
                          }

                          // 3. CASO: Esperando que el estudiante elija
                          if (homeProvider.confirmationStartTime != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const VistaConfirmacion(),
                              ),
                            );
                            return;
                          }

                          // 4. CASO: Nueva solicitud (Aceptar)
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AcceptTutoringScreen(
                                data_tutor: data['data_tutor'],
                                onEnterWaitingRoom: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const VistaConfirmacion(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isReady
                              ? Colors.white
                              : (isChosen ? Colors.tealAccent : AppColors.brandCyan),
                          foregroundColor: isReady
                              ? const Color(0xFFE65100)
                              : (isChosen ? const Color(0xFF065F46) : Colors.white),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isReady
                                  ? 'Unirse a la Clase'
                                  : (isChosen
                                      ? 'Ver Estado de Pago'
                                      : 'Revisar Solicitud'),
                              style: const TextStyle(
                                fontFamily: 'outfit',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                                isReady
                                    ? Icons.video_call_rounded
                                    : (isChosen
                                        ? Icons.rocket_launch_rounded
                                        : Icons.arrow_forward_ios_rounded),
                                size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
