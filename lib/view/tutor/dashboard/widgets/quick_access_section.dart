import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/models/tutor_subject.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/provider/tutor_subjects_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/tutor/features/subjects/tutor_subjects_screen.dart';
import 'package:provider/provider.dart';

class QuickAccessSection extends StatelessWidget {
  final Function(int) onNavigate;
  
  const QuickAccessSection({Key? key, required this.onNavigate}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            "Accesos Rápidos",
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.brandBlue,
              fontSize: 20,
              fontFamily: 'outfit',
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 15), 
          child: Row(
            children: [
              _QuickAccessCard(
                icon: Icons.calendar_today_rounded,
                title: "Mi Agenda",
                themeColor: AppColors.brandCyan,
                onTap: () => onNavigate(1),
              ),
              const SizedBox(width: 15),
             // ACCESO 2: LAS MATERIAS
              _QuickAccessCard(
                icon: Icons.menu_book_rounded,
                title: "Mis Materias",
                themeColor: AppColors.brandOrange, 
                onTap: () => onNavigate(2),
              ),
              const SizedBox(width: 15),
              _QuickAccessCard(
                icon: Icons.person_pin_rounded,
                title: "Ver Perfil",
                themeColor: isDark ? Colors.white : AppColors.brandBlue,
                onTap: () => onNavigate(3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color themeColor;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.themeColor,
    required this.onTap,
  });

  @override
  State<_QuickAccessCard> createState() => _QuickAccessCardState();
}

class _QuickAccessCardState extends State<_QuickAccessCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Configuración de colores dinámica
    final bgColor = isDark ? const Color(0xFF1E222A) : Colors.white;
    final borderColor = isDark 
        ? (_isPressed ? widget.themeColor.withOpacity(0.5) : Colors.white10)
        : (_isPressed ? widget.themeColor.withOpacity(0.3) : Colors.black.withOpacity(0.05));

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        // Efecto de escala y traslación
        transform: Matrix4.identity()
          ..scale(_isPressed ? 0.96 : 1.0)
          ..translate(0.0, _isPressed ? 2.0 : 0.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: _isPressed 
            ? [] // La sombra desaparece al "tocar" el suelo
            : [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.3) : widget.themeColor.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono con círculo de fondo suave
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.themeColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: widget.themeColor, size: 22),
            ),
            const SizedBox(width: 14),
            Text(
              widget.title,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.brandBlue,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}