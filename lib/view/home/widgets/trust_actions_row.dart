import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/home/widgets/alliance_card.dart';
import 'package:flutter_projects/view/home/widgets/suport_screen.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';

class TrustActionsRow extends StatelessWidget {
  const TrustActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(
            child: _SmallActionCard(
              title: l10n.ourAlliances,
              subtitle: l10n.institutions,
              icon: Icons.handshake_rounded,
              iconColor: AppColors.brandCyan,
              onTap: () {
                debugPrint("Navegar a pantalla de Alianzas");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AlliancesScreen()),
                );
              },
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: _SmallActionCard(
              title: l10n.needHelp,
              subtitle: l10n.support247,
              icon: Icons.support_agent_rounded,
              iconColor: AppColors.brandOrange,
              onTap: () {
                // --- CONEXIÓN AQUÍ ---
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SupportScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _SmallActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.dividerLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono con fondo sutil
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: AppFonts.heading,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.brandBlue,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            // Subtítulo
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 11,
                color: AppColors.textLightSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
