import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:flutter_projects/models/booking_status.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tarjeta reutilizable de reserva/tutoría.
///
/// Muestra horario + estado, materia, persona (tutor/estudiante) y materiales
/// adjuntos. Sin lógica de navegación: el padre decide qué ocurre en [onTap].
///
/// El texto de ayuda va fuera de este widget, una sola vez debajo de la lista.
class ReservationCard extends StatelessWidget {
  final String startTime;
  final String endTime;
  final String status;
  final String subjectName;
  final String personName;
  final String? personLabel;
  final int attachmentCount;
  final String meetingLink;
  final VoidCallback? onTap;

  const ReservationCard({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.subjectName,
    required this.personName,
    this.personLabel,
    this.attachmentCount = 0,
    this.meetingLink = '',
    this.onTap,
  });

  Color get _statusColor {
    final normalized = status.trim().toLowerCase();
    if (normalized.contains('cancel')) {
      return AppColors.greyColor;
    }
    final booking = BookingStatus.fromString(status);
    return booking.statusColor;
  }

  String _statusText(AppLocalizations l10n) {
    final normalized = status.trim().toLowerCase();
    if (normalized.contains('cancel')) {
      return l10n.statusCancelled;
    }
    switch (BookingStatus.fromString(status)) {
      case BookingStatus.aceptado:
        return l10n.statusAccepted;
      case BookingStatus.pendiente:
        return l10n.statusPending;
      case BookingStatus.noCompletado:
        return l10n.statusNotCompleted;
      case BookingStatus.rechazado:
        return l10n.statusRejected;
      case BookingStatus.completado:
        return l10n.statusCompleted;
      case BookingStatus.cursando:
        return l10n.statusInProgress;
    }
  }

  Future<void> _openMeetLink(BuildContext context) async {
    var url = meetingLink.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.meetLinkNotAvailable),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _statusColor;
    final label = personLabel ?? l10n.tutorLabel;
    final hasMeet = meetingLink.trim().isNotEmpty;

    return Material(
      color: AppColors.studentCardWhite,
      borderRadius: BorderRadius.circular(24),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.07),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // Línea vertical del estado. Se pinta con el mismo radio que la
            // tarjeta (24) siguiendo la curva de las esquinas por el interior:
            // en cada extremo la franja acompaña el arco del redondeado en
            // lugar de cortar en línea recta al llegar a la esquina.
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 5,
              child: CustomPaint(
                painter: _StatusStripPainter(color: statusColor),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila 1: horario en pill + estado (punto + texto)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.timePillBackground,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '$startTime - $endTime',
                          style: const TextStyle(
                            fontFamily: AppFonts.heading,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: AppColors.timePillText,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        _statusText(l10n),
                        style: TextStyle(
                          fontFamily: AppFonts.body,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Título (hasta 2 líneas) + persona + chevron a la derecha
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subjectName,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: AppFonts.heading,
                                fontWeight: FontWeight.w700,
                                fontSize: 15.5,
                                height: 1.25,
                                color: AppColors.textLightPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$label$personName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: 12.5,
                                color: AppColors.textLightSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: AppColors.chevronGrey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Divisor punteado
                  const SizedBox(
                    width: double.infinity,
                    height: 1,
                    child: CustomPaint(painter: _DashedDividerPainter()),
                  ),
                  const SizedBox(height: 8),
                  // Materiales adjuntos + botón Meet
                  Row(
                    children: [
                      Icon(
                        Icons.attach_file_rounded,
                        size: 16,
                        color: AppColors.greyColor.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          attachmentCount > 0
                              ? l10n.materialsAttached(attachmentCount)
                              : l10n.noMaterialsAttached,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 12.5,
                            color: AppColors.textLightSecondary,
                          ),
                        ),
                      ),
                      if (hasMeet) ...[
                        const Spacer(),
                        _MeetButton(
                          label: l10n.meetButton,
                          onPressed: () => _openMeetLink(context),
                        ),
                      ],
                    ],
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

/// Botón compacto "Meet" que abre el enlace de la sesión.
class _MeetButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _MeetButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.neonGreen.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_rounded,
                  size: 15, color: AppColors.neonGreen),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppFonts.heading,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.neonGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pinta la franja vertical de estado siguiendo el arco de las esquinas
/// redondeadas de la tarjeta (radio 24) por el interior.
class _StatusStripPainter extends CustomPainter {
  final Color color;

  static const double _stripWidth = 5;
  static const double _cornerRadius = 24;

  const _StatusStripPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    const w = _stripWidth;
    const r = _cornerRadius;
    final h = size.height;

    // Altura donde el arco de la esquina (centro en (r, r)) cruza el borde
    // interior de la franja (x = w).
    final yTop = r - math.sqrt(r * r - (r - w) * (r - w));
    final yBottom = h - yTop;

    if (h <= yTop * 2) {
      return;
    }

    final path = Path()
      ..moveTo(0, r)
      // Arco superior: sigue la curva de la esquina de la tarjeta.
      ..arcToPoint(Offset(w, yTop),
          radius: const Radius.circular(r), clockwise: true)
      ..lineTo(w, yBottom)
      // Arco inferior: misma curva al llegar a la esquina baja.
      ..arcToPoint(Offset(0, h - r),
          radius: const Radius.circular(r), clockwise: true)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StatusStripPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Pinta una línea horizontal punteada (divisor de la tarjeta).
class _DashedDividerPainter extends CustomPainter {
  const _DashedDividerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.dashedDivider
      ..strokeWidth = 1;

    const dash = 4.0;
    const gap = 3.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedDividerPainter oldDelegate) => false;
}
