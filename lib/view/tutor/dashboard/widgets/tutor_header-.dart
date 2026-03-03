import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/tutor/dashboard/widgets/theme_toggle_button.dart';

class TutorHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBackTap;
  final VoidCallback? onLogoutTap;

  const TutorHeader({
    Key? key,
    required this.title,
    this.onBackTap,
    this.onLogoutTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Colores basados en tu diseño exacto
    final textColor = isDark ? Colors.white : AppColors.brandBlue;
    final circleBgColor = isDark ? const Color(0xFF1E2128) : Colors.white; // Círculos oscuros en dark mode
    final borderColor = isDark ? Colors.white10 : Colors.black.withOpacity(0.05);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. IZQUIERDA: Botón Atrás + Título
          Row(
            children: [
              if (onBackTap != null) ...[
                GestureDetector(
                  onTap: onBackTap,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: circleBgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor),
                      boxShadow: !isDark 
                          ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] 
                          : [],
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 18),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900, // Extra Bold
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          // 2. DERECHA: Tema y Logout
          Row(
            children: [
              const ThemeToggleButton(),
              if (onLogoutTap != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onLogoutTap,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: circleBgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor),
                      boxShadow: !isDark 
                          ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] 
                          : [],
                    ),
                    child: const Icon(Icons.logout_rounded, color: AppColors.stateUrgent, size: 20),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}