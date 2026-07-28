import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter/material.dart';

enum BookingStatus {
  aceptado(1, 'Aceptado'),
  pendiente(2, 'Pendiente'),
  noCompletado(3, 'No completado'),
  rechazado(4, 'Rechazado'),
  completado(5, 'Completado'),
  cursando(6, 'Cursando');

  final int id;
  final String displayName;
  const BookingStatus(this.id, this.displayName);

  static BookingStatus fromString(String? status) {
    if (status == null) return BookingStatus.pendiente;
    final normalized = status.trim().toLowerCase();
    return BookingStatus.values.firstWhere(
      (s) => s.displayName.toLowerCase() == normalized,
      orElse: () => BookingStatus.pendiente,
    );
  }

  bool get isActive => this == BookingStatus.aceptado || this == BookingStatus.cursando;
  bool get isFinished => this == BookingStatus.completado || this == BookingStatus.noCompletado || this == BookingStatus.rechazado;
  bool get canStart => this == BookingStatus.aceptado;
  bool get isInProgress => this == BookingStatus.cursando;
  bool get isPending => this == BookingStatus.pendiente;

  String get displayLabel {
    switch (this) {
      case BookingStatus.pendiente:
        return 'Pendiente';
      case BookingStatus.aceptado:
        return 'Aceptada';
      case BookingStatus.cursando:
        return 'En curso';
      case BookingStatus.completado:
        return 'Completada';
      case BookingStatus.rechazado:
        return 'Rechazada';
      case BookingStatus.noCompletado:
        return 'No completada';
    }
  }

  Color get statusColor {
    switch (this) {
      case BookingStatus.pendiente:
        return AppColors.brandOrange;
      case BookingStatus.aceptado:
        return AppColors.neonGreen;
      case BookingStatus.cursando:
        return AppColors.brandCyan;
      case BookingStatus.completado:
        return Colors.grey;
      case BookingStatus.rechazado:
        return AppColors.redColor;
      case BookingStatus.noCompletado:
        return AppColors.yellowColor;
    }
  }

  IconData get statusIcon {
    switch (this) {
      case BookingStatus.cursando:
        return Icons.play_circle_fill;
      default:
        return Icons.access_time_rounded;
    }
  }
}
