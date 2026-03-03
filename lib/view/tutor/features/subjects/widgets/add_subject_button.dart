import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'dart:ui';

const String kFontFamily = 'outfit';

class AddSubjectButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddSubjectButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onPressed,
      child: CustomPaint(
        painter: _DashedRectPainter(
          color: AppColors.brandCyan.withOpacity(0.5),
          strokeWidth: 1.5,
          gap: 6.0,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.02) : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandCyan.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.brandCyan, size: 24),
              ),
              const SizedBox(height: 12),
              const Text(
                "AÑADIR ESPECIALIDAD",
                style: TextStyle(
                  color: AppColors.brandCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  fontFamily: kFontFamily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Pintor personalizado para lograr la línea punteada perfecta de Figma
class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  _DashedRectPainter({required this.color, required this.strokeWidth, required this.gap});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(28)));

    final PathMetrics pathMetrics = path.computeMetrics();
    final Path dashedPath = Path();

    for (PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        dashedPath.addPath(
          pathMetric.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}