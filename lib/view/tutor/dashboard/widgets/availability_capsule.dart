import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class AvailabilityCapsule extends StatelessWidget {
  final bool isAvailable;
  final VoidCallback onTap;

  const AvailabilityCapsule({
    Key? key,
    required this.isAvailable,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final Color stateColor = isAvailable 
        ? AppColors.neonGreen 
        : AppColors.neonOrange;

    final Color capsuleBackground = isDark 
        ? AppColors.cardDark
        : Colors.white;        

    final Color titleColor = isDark 
        ? Colors.white 
        : AppColors.textColor;

    final Color subtitleColor = isDark 
        ? Colors.white.withOpacity(0.6) 
        : const Color(0xFF6C757D); 

    final String titleText = isAvailable ? "Estás Visible" : "Estás Invisible";
    final String subText = isAvailable ? "Pulsa para desactivar" : "Pulsa para activar";

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: capsuleBackground,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isAvailable 
                ? stateColor 
                : (isDark ? stateColor.withOpacity(0.5) : Colors.black.withOpacity(0.1)),
            width: isAvailable ? 2.0 : 1.5,
          ),
          boxShadow: [
            if (isAvailable && isDark)
              BoxShadow(
                color: stateColor.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            if (!isDark) 
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Row(
          children: [
            // 1. Icono Power (CUADRADO REDONDEADO)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 48, 
              height: 48,
              decoration: BoxDecoration(
                color: stateColor, // El botón siempre tiene color vibrante
                borderRadius: BorderRadius.circular(14),
                boxShadow: isAvailable && isDark ? [
                  BoxShadow(
                    color: stateColor.withOpacity(0.5), 
                    blurRadius: 12, 
                    offset: const Offset(0, 2)
                  )
                ] : [],
              ),
              child: const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 26),
            ),
            
            const SizedBox(width: 16),
            
            // 2. Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      titleText,
                      key: ValueKey(isAvailable),
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 20, 
                        fontFamily: 'outfit',
                        fontWeight: FontWeight.w700, 
                        letterSpacing: -0.5
                      ),
                    ),
                  ),
                  // const SizedBox(height: 4),
                  Text(
                    subText, 
                    style: TextStyle(
                      color: subtitleColor,
                      fontFamily: 'manrope',
                      fontWeight: FontWeight.w600,
                      fontSize: 13
                    )
                  ),
                ],
              ),
            ),

            // 3. Switch Visual
            IgnorePointer(
              child: Transform.scale(
                scale: 1.1,
                child: Switch(
                  value: isAvailable,
                  onChanged: (_) {},
                  // Colores del Switch ajustados para ambos temas
                  activeColor: isDark ? const Color(0xFF151A24) : Colors.white,
                  activeTrackColor: stateColor,
                  inactiveThumbColor: isDark ? const Color(0xFF2A303C) : Colors.grey[400],
                  inactiveTrackColor: isDark ? Colors.black.withOpacity(0.3) : Colors.grey[200],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}