import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class StartSessionDialog extends StatelessWidget {
  final String studentName;
  final String duration;
  final VoidCallback onConfirm;

  const StartSessionDialog({
    Key? key,
    required this.studentName,
    this.duration = "20 Minutos", 
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.brandBlue;
    final bgLight = isDark ? const Color(0xFF1B3B48) : Colors.grey.withOpacity(0.05);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151A24) : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        // IMPORTANTE: mainAxisSize.min hace que el modal abrace su contenido y quede centrado en la pantalla
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            // Botón cerrar y centrado de icono
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.grey, size: 20),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.brandOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.videocam_outlined, color: AppColors.brandOrange, size: 36),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              "¿Empezar Sesión?",
              style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'outfit'),
            ),
            const SizedBox(height: 8),
            Text(
              "Estás a punto de iniciar la tutoría de $duration con $studentName.",
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 24),

            // Fila de Duración
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: bgLight, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("DURACIÓN", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(duration, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Fila de Plataforma
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: bgLight, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("PLATAFORMA", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text("ClassGo Meet", style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Botón Naranja Gigante
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context); // 1. Cierra el modal
                  onConfirm(); // 2. Ejecuta la validación y redirección
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text("EMPEZAR REUNIÓN", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                    SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}