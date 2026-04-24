import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_projects/styles/app_styles.dart';

class RadarPainter extends CustomPainter {
  final double animationValue;

  RadarPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Garantiza un cuadrado exacto para simetría perfecta
    final double side = min(size.width, size.height);
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = side / 2;

    // 1. CÍRCULOS CONCÉNTRICOS (Usando tu AppColors.brandBlue muy tenue)
    final Paint circlePaint = Paint()
      ..color = AppColors.brandBlue.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius, circlePaint);
    canvas.drawCircle(center, radius * 0.75, circlePaint);
    canvas.drawCircle(center, radius * 0.50, circlePaint);
    canvas.drawCircle(center, radius * 0.25, circlePaint);

    // Ejes invisibles
    final Paint linePaint = Paint()
      ..color = AppColors.brandBlue.withOpacity(0.02)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), linePaint);
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), linePaint);

    // 2. EL BARRIDO (Luz con tu AppColors.brandCyan)
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          AppColors.brandCyan.withOpacity(0.02),
          AppColors.brandCyan.withOpacity(0.2),
          AppColors.brandCyan.withOpacity(0.5),
        ],
        stops: const [0.0, 0.4, 0.85, 1.0],
        transform: GradientRotation(animationValue * 2 * pi - pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      animationValue * 2 * pi - pi / 2 - pi / 3, 
      pi / 3, 
      true,
      sweepPaint,
    );

    // 3. PUNTITOS FLOTANTES
    final Paint dotPaint = Paint()..color = AppColors.brandCyan.withOpacity(0.6);
    canvas.drawCircle(Offset(center.dx + radius * 0.45, center.dy - radius * 0.4), 4, dotPaint);
    canvas.drawCircle(Offset(center.dx - radius * 0.55, center.dy - radius * 0.15), 5, dotPaint);
    canvas.drawCircle(Offset(center.dx + radius * 0.15, center.dy + radius * 0.5), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}