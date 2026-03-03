import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class ReservationDetailsDialog extends StatelessWidget {
  final String subject;
  final String studentName;
  final String studentType;
  final String studentImageUrl;
  final String date;
  final String time;
  final String message;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ReservationDetailsDialog({
    Key? key,
    required this.subject,
    required this.studentName,
    required this.studentType,
    required this.studentImageUrl,
    required this.date,
    required this.time,
    required this.message,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colores Neoclean para el modal
    final dialogBgColor = isDark ? const Color(0xFF1A1D24) : Colors.white;
    final cardBgColor = isDark ? const Color(0xFF22252D) : const Color(0xFFF4F6F9); // Gris muy suave
    final titleColor = isDark ? Colors.white : AppColors.brandBlue;
    final subtitleColor = isDark ? Colors.white54 : Colors.grey[500];

    return Dialog(
      backgroundColor: Colors.transparent, // Transparente para usar nuestro propio Container
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: dialogBgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Se adapta al contenido
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. BOTÓN CERRAR (X) Y TÍTULO
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    "Reserva: $subject",
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w900, // Black font
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close_rounded, color: subtitleColor, size: 24),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 2. TARJETA DEL ESTUDIANTE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: studentImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Icon(Icons.person, color: Colors.grey),
                        errorWidget: (_, __, ___) => const Icon(Icons.person, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Nombres
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w800, // Extra Bold
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          studentType,
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. FILA DE FECHA Y HORA
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    label: "FECHA",
                    value: date,
                    bgColor: cardBgColor,
                    textColor: titleColor,
                    labelColor: subtitleColor!,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCard(
                    label: "HORA",
                    value: time,
                    bgColor: cardBgColor,
                    textColor: titleColor,
                    labelColor: subtitleColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 4. CAJA DE MENSAJE (Borde Punteado)
            CustomPaint(
              painter: _DashedRectPainter(
                color: isDark ? Colors.white30 : Colors.grey[400]!,
                strokeWidth: 1.5,
                dash: 6.0,
                gap: 4.0,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Text(
                  "“$message”",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey[600],
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 5. BOTONES DE ACCIÓN
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.grey[300]!, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      "Cancelar",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey[700],
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : AppColors.brandBlue,
                      foregroundColor: isDark ? AppColors.brandBlue : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Confirmar",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
}

// =============================================================================
// 🧩 WIDGETS INTERNOS
// =============================================================================

// Tarjeta pequeña para Fecha y Hora
class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final Color bgColor;
  final Color textColor;
  final Color labelColor;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.bgColor,
    required this.textColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w900, // Black
            ),
          ),
        ],
      ),
    );
  }
}

// 🎨 CUSTOM PAINTER PARA EL BORDE PUNTEADO NATIVO (Sin paquetes extra)
class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;

  _DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
    this.dash = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Crea el rectángulo con bordes redondeados
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16), // El radio de las esquinas del borde punteado
    );

    Path path = Path()..addRRect(rrect);
    Path dashPath = Path();

    // Lógica para cortar el trazo en puntitos (Dashes)
    for (ui.PathMetric measurePath in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < measurePath.length) {
        dashPath.addPath(
          measurePath.extractPath(distance, distance + dash),
          Offset.zero,
        );
        distance += dash + gap;
      }
    }
    
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}