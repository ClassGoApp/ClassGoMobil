import 'package:flutter/material.dart';

class CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool isDestructive; // Para ponerlo rojito si es "Cerrar sesión"
  final Color? customIconColor;

  const CircleActionButton({
    Key? key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.isDestructive = false,
    this.customIconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colores inteligentes: Si es destructivo (logout), lo pintamos rojo.
    final Color finalIconColor = isDestructive 
        ? const Color(0xFFFF453A) 
        : (customIconColor ?? Colors.white);

    final Color bgColor = isDestructive
        ? const Color(0xFFFF453A).withOpacity(0.15)
        : Colors.white.withOpacity(0.15);

    final Color borderColor = isDestructive
        ? const Color(0xFFFF453A).withOpacity(0.3)
        : Colors.white.withOpacity(0.3);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: finalIconColor, size: 20),
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
        splashRadius: 24, // Efecto de onda al tocar
      ),
    );
  }
}