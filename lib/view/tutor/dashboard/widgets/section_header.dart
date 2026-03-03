import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/tutor/dashboard/widgets/theme_toggle_button.dart';

class SectionHeader extends StatelessWidget {
  final String title;              // "Agenda", "Materias", etc.
  final String? profileImageUrl;
  final VoidCallback? onActionTap; // Acción del botón derecho
  final IconData? actionIcon;      // Icono del botón derecho
  final bool showAction;           // Si queremos mostrar el botón extra o no

  const SectionHeader({
    Key? key,
    required this.title,
    this.profileImageUrl,
    this.onActionTap,
    this.actionIcon,
    this.showAction = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. IZQUIERDA: Foto + Título
          Row(
            children: [
              // Foto pequeña
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: ClipOval(
                  child: profileImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: profileImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: Colors.grey[200]),
                          errorWidget: (_, __, ___) => const Icon(Icons.person, size: 20),
                        )
                      : const Icon(Icons.person, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              
              // Título y Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900, // Extra Bold
                      color: theme.colorScheme.onSurface,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.verified, size: 10, color: AppColors.brandCyan),
                        SizedBox(width: 2),
                        Text(
                          "VERIFICADO",
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.brandCyan),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),

          // 2. DERECHA: Botones
          Row(
            children: [
              // Botón de Tema (Siempre presente)
              const ThemeToggleButton(),
              
              // Botón de Acción Opcional (Ej: "Ir a Hoy" o "Agregar")
              if (showAction && actionIcon != null) ...[
                const SizedBox(width: 8),
                _ActionButton(
                  icon: actionIcon!,
                  onTap: onActionTap ?? () {},
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
          boxShadow: !isDark 
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] 
              : [],
        ),
        child: Icon(icon, size: 18, color: isDark ? Colors.white : Colors.black87),
      ),
    );
  }
}