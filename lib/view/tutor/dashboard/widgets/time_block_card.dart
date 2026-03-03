import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class TimeBlockCard extends StatelessWidget {
  final String timeRange; // Ej: "10:00 - 11:00"
  final VoidCallback onDelete;

  const TimeBlockCard({
    Key? key,
    required this.timeRange,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colores dinámicos Neoclean
    final bgColor = isDark ? const Color(0xFF151A24) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24), // Bordes estilo píldora/cápsula
        // Sombra en Light Mode, borde sutil en Dark Mode
        boxShadow: !isDark 
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ] 
            : [
                BoxShadow(
                  color: Colors.white.withOpacity(0.02),
                  spreadRadius: 1,
                )
              ],
      ),
      child: Row(
        children: [
          // 1. ICONO DE RELOJ (Cyan)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.brandCyan.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.access_time_rounded, 
              color: AppColors.brandCyan, 
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // 2. TEXTO DE LA HORA
          Expanded(
            child: Text(
              timeRange,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w800, // Extra Bold
                letterSpacing: 0.5,
              ),
            ),
          ),

          // 3. BOTÓN DE ELIMINAR (Rojo)
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact(); // Vibración al intentar borrar
              onDelete();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.stateUrgent.withOpacity(0.15), // Rojo claro
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded, 
                color: AppColors.stateUrgent, 
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}