import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class ReservationDetailsDialog extends StatelessWidget {
  final String subject;
  final String studentName;
  final String date;
  final String time;
  final String endTime;
  final String message;

  const ReservationDetailsDialog({
    Key? key,
    required this.subject,
    required this.studentName,
    required this.date,
    required this.time,
    required this.endTime,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF151A24) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandBlue;
    final boxColor = isDark ? const Color(0xFF1B3B48) : Colors.grey.withOpacity(0.05);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header (Título y botón X)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Reserva: $subject",
                    style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'outfit'),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.grey, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. Perfil del Estudiante
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: boxColor, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.brandBlue.withOpacity(0.1),
                    child: const Icon(Icons.person, color: AppColors.brandBlue),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(studentName, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                      const Text("Estudiante", style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Fecha y Hora (En dos columnas)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: boxColor, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("FECHA", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(date, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: boxColor, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("HORA", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("$time - $endTime", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Mensaje del estudiante (Caja con borde)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
              ),
              child: Text(
                '"$message"',
                style: const TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic, height: 1.4),
              ),
            ),
            const SizedBox(height: 24),

            // 5. Botones Finales
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Cerrar", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Lógica futura para editar
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandBlue, // Azul oscuro
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text("Editar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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