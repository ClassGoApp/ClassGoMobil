import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class QuickActionsRow extends StatelessWidget {
  final VoidCallback onInstantTutorTap;
  final VoidCallback onScheduleTap;
  final VoidCallback onExploreTap;

  const QuickActionsRow({
    super.key,
    required this.onInstantTutorTap,
    required this.onScheduleTap,
    required this.onExploreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          // 1. TUTOR AL INSTANTE
          Expanded(
            child: _ActionCard(
              title: 'Tutor al\nInstante',
              imageAsset: 'assets/images/aguilaTI.png',
              fallbackIcon: Icons.flash_on_rounded,
              isHighlighted: true,
              onTap: onInstantTutorTap,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 2. AGENDAR TUTORÍA
          Expanded(
            child: _ActionCard(
              title: 'Agendar\nTutoría',
              imageAsset: 'assets/images/calendario.png',
              fallbackIcon: Icons.calendar_month_rounded,
              isHighlighted: false,
              onTap: onScheduleTap,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 3. EXPLORAR TUTORES
          Expanded(
            child: _ActionCard(
              title: 'Explorar\nTutores',
              imageAsset: 'assets/images/Buscar.png',
              fallbackIcon: Icons.search_rounded,
              isHighlighted: false,
              onTap: onExploreTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String imageAsset;
  final IconData fallbackIcon;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.imageAsset,
    required this.fallbackIcon,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: isHighlighted ? AppColors.brandOrange.withOpacity(0.05) : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: isHighlighted 
              ? Border.all(color: AppColors.brandOrange, width: 2) 
              : Border.all(color: AppColors.dividerLight, width: 1),
          boxShadow: [
            if (!isHighlighted) 
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imageAsset,
              height: 50,
              width: 50,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high, 
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  fallbackIcon,
                  size: 50, 
                  color: isHighlighted ? AppColors.brandOrange : AppColors.brandCyan,
                );
              },
            ),
            
            const SizedBox(height: 10),
            
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.heading,
                  fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 14, 
                  color: isHighlighted ? AppColors.brandOrange : AppColors.brandBlue,
                  height: 1.1, 
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}