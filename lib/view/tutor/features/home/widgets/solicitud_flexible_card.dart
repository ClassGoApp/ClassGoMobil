import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/view/tutor/features/agenda/schedule_request_detail_screen.dart';
import 'package:flutter_projects/view/tutor/features/home/providers/tutor_home_provider.dart';

class SolicitudFlexibleCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onClose;

  const SolicitudFlexibleCard({
    Key? key,
    required this.data,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TutorHomeProvider? homeProvider;
    try {
      homeProvider = Provider.of<TutorHomeProvider>(context, listen: false);
    } catch (_) {}

    // Extraer datos de la notificación
    var decodificado = data['data_tutor'];
    String? token;
    String? personName;
    String? subjectName;
    String? status;

    if (decodificado != null) {
      if (decodificado is String) {
        try {
          var parsed = jsonDecode(decodificado);
          if (parsed is String) {
            parsed = jsonDecode(parsed);
          }
          decodificado = parsed;
        } catch (_) {}
      }
      if (decodificado is Map) {
        token = decodificado['token']?.toString() ??
            decodificado['accept_token']?.toString();
        personName = decodificado['nombre'] ??
            decodificado['student_name'] ??
            decodificado['tutor_name'] ??
            decodificado['estudiante_nombre'] ??
            decodificado['user_name'];
        subjectName = decodificado['materia'] ??
            decodificado['subject_name'] ??
            decodificado['subject'];
        status = decodificado['status']?.toString();
      }
    }

    token ??= data['token']?.toString() ?? data['accept_token']?.toString();
    personName ??= data['nombre'] ??
        data['student_name'] ??
        data['tutor_name'] ??
        data['estudiante_nombre'];
    subjectName ??= data['materia'] ?? data['subject_name'];
    status ??= data['status']?.toString();

    final bool isCountered = status == 'countered_by_tutor';

    final String titleText = isCountered
        ? '¡NUEVA CONTRAOFERTA DE HORARIO!'
        : '¡PROPUESTA DE HORARIO FLEXIBLE!';

    final String subtitleText = isCountered
        ? ((personName != null && personName.isNotEmpty)
            ? '$personName ha enviado una contraoferta de horario${subjectName != null ? " para tu clase de $subjectName" : ""}.'
            : 'Un tutor ha enviado una nueva propuesta de horario.')
        : ((personName != null && personName.isNotEmpty)
            ? '$personName ha actualizado una propuesta de horario${subjectName != null ? " de $subjectName" : ""}.'
            : 'Tienes una actualización de propuesta de horario flexible.');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2E1065), // Deep Violet
            Color(0xFF581C87), // Rich Purple
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF581C87).withOpacity(0.35),
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
                  color: const Color(0xFFA855F7).withOpacity(0.15),
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
                      // Icono estilizado
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA855F7).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Color(0xFFE9D5FF),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleText,
                              style: const TextStyle(
                                fontFamily: 'outfit',
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: Color(0xFFE9D5FF),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitleText,
                              style: TextStyle(
                                fontFamily: 'manrope',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withOpacity(0.95),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (onClose != null) {
                            onClose!();
                          } else {
                            homeProvider?.removePendingFlexibleRequest(data);
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close_rounded,
                            size: 20, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Botón de acción
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9333EA).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (token != null && token.isNotEmpty) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ScheduleRequestDetailScreen(token: token!),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'No se encontró el código de la propuesta.'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9333EA),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Revisar y Responder',
                            style: TextStyle(
                              fontFamily: 'outfit',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios_rounded, size: 16),
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
