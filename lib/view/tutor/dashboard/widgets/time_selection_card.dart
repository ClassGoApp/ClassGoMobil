import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class TimeSelectionCard extends StatefulWidget {
  final String startTime;
  final String endTime;
  final VoidCallback onConfirm;
  final VoidCallback onAddTap; // Para el icono '+' de arriba a la derecha

  const TimeSelectionCard({
    Key? key,
    required this.startTime,
    required this.endTime,
    required this.onConfirm,
    required this.onAddTap,
  }) : super(key: key);

  @override
  State<TimeSelectionCard> createState() => _TimeSelectionCardState();
}

class _TimeSelectionCardState extends State<TimeSelectionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // El color verde suave de tu diseño
    const Color cardColor = Color(0xFFA8D5BA);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32), // Bordes súper redondos
        boxShadow: [
          // Sombra suave tintada de verde para que parezca que brilla un poco
          BoxShadow(
            color: cardColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ENCABEZADO Y BOTÓN "+"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "HORARIO SELECCIONADO",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0, // Letras espaciadas
                ),
              ),
              GestureDetector(
                onTap: widget.onAddTap,
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 24,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),

          // 2. HORAS GIGANTES ("19:00 > 20:00")
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // Hora de inicio (Fuerte)
              Text(
                widget.startTime,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900, // Extra Bold
                  letterSpacing: -1.5,
                  height: 1.0,
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.5),
                  size: 32,
                ),
              ),
              
              // Hora de fin (Suave)
              Text(
                widget.endTime,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6), // Más transparente
                  fontSize: 40, // Un poco más pequeña para dar jerarquía
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  height: 1.0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // 3. BOTÓN "CONFIRMAR HORARIO"
          GestureDetector(
            onTapDown: (_) {
              HapticFeedback.lightImpact();
              setState(() => _isPressed = true);
            },
            onTapUp: (_) {
              setState(() => _isPressed = false);
              widget.onConfirm();
            },
            onTapCancel: () => setState(() => _isPressed = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutQuad,
              width: double.infinity,
              height: 56, // Altura cómoda para tocar
              transform: Matrix4.translationValues(0, _isPressed ? 2 : 0, 0), // Se hunde un poco
              decoration: BoxDecoration(
                color: AppColors.brandBlue, // Azul oscuro Neoclean
                borderRadius: BorderRadius.circular(16),
                boxShadow: _isPressed
                    ? []
                    : [
                        BoxShadow(
                          color: AppColors.brandBlue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Confirmar Horario",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}