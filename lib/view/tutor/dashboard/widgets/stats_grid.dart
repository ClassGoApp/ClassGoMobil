import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class StatsGrid extends StatelessWidget {
  final String acceptanceRate;
  final String responseTime;
  final VoidCallback onAcceptanceTap;
  final VoidCallback onResponseTap;

  const StatsGrid({
    Key? key,
    required this.acceptanceRate, 
    required this.responseTime, 
    required this.onAcceptanceTap,
    required this.onResponseTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // 1. TARJETA DE ACEPTACIÓN
          Expanded(
            child: _InteractiveStatCard(
              value: acceptanceRate,
              label: "ACEPTACIÓN",
              icon: Icons.show_chart_rounded,
              iconColor: const Color(0xFF2E90FA), 
              onTap: onAcceptanceTap,
            ),
          ),

          const SizedBox(width: 16), // Espacio central

          // 2. TARJETA DE RESPUESTA
          Expanded(
            child: _InteractiveStatCard(
              value: responseTime,
              label: "RESPUESTA",
              icon: Icons.bolt_rounded,
              // Color naranja/ámbar vibrante según imagen
              iconColor: const Color(0xFFFF9800), 
              onTap: onResponseTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveStatCard extends StatefulWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _InteractiveStatCard({
    Key? key,
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_InteractiveStatCard> createState() => _InteractiveStatCardState();
}

class _InteractiveStatCardState extends State<_InteractiveStatCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    
    final cardColor = isDark 
        ? AppColors.cardDark
        : Colors.white;
    // final cardColor = isDark ? const Color(0xFF151A24) : Colors.white;
    
    final valueColor = isDark ? Colors.white : AppColors.brandBlue;
    final labelColor = isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF9AA4B2);

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuad,
        
        // 🚀 EFECTO LEVANTAR: 
        // Si NO está presionado, se levanta un poco (-4 en Y) para parecer flotante.
        // Si está presionado, baja a 0 (efecto click físico).
        transform: Matrix4.translationValues(0, _isPressed ? 0 : -4, 0),
        
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(40), // Bordes muy redondeados (Squircle)
          
          // SOMBRAS (Solo en modo claro para dar volumen)
          boxShadow: !isDark
              ? [
                  BoxShadow(
                    // La sombra cambia si está presionado (se acerca al fondo) o no
                    color: Colors.black.withOpacity(_isPressed ? 0.05 : 0.08),
                    offset: Offset(0, _isPressed ? 4 : 12), // Sombra baja si se levanta
                    blurRadius: _isPressed ? 10 : 20,
                  ),
                ]
              : [
                // En modo oscuro, podemos poner un borde muy sutil en lugar de sombra
                // para que no se pierda en el fondo negro
                BoxShadow(
                   color: Colors.white.withOpacity(0.02),
                   offset: const Offset(0, 0),
                   blurRadius: 0,
                   spreadRadius: 1
                )
              ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ICONO FLOTANTE (Sin círculo de fondo, como en la imagen)
            Icon(
              widget.icon,
              size: 32,
              color: widget.iconColor,
            ),
            
            const SizedBox(height: 16),
            
            // VALOR (Grande y Bold)
            Text(
              widget.value,
              style: TextStyle(
                color: valueColor,
                fontSize: 26,
                fontFamily: 'manrope',
                fontWeight: FontWeight.w900, 
                letterSpacing: -0.5,
                height: 1.2
              ),
            ),
            
            const SizedBox(height: 4),
            
            Text(
              widget.label.toUpperCase(),
              style: TextStyle(
                color: labelColor,
                fontSize: 11,
                fontFamily: 'manrope',
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0, 
              ),
            ),
          ],
        ),
      ),
    );
  }
}