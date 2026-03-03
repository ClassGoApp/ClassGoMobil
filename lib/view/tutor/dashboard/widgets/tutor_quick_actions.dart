import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class TutorQuickActions extends StatelessWidget {
  final VoidCallback onManageSubjects;
  final VoidCallback onDefineSchedule;
  final VoidCallback onMyTutorials;

  const TutorQuickActions({
    Key? key,
    required this.onManageSubjects,
    required this.onDefineSchedule,
    required this.onMyTutorials,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.darkBlue.withOpacity(0.9),
            AppColors.darkBlue.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.lightBlueColor.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(),
          const SizedBox(height: 20),
          _buildButtonsGrid(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.lightBlueColor, AppColors.primaryGreen],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.flash_on, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildButtonsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 0,
      childAspectRatio: 1.2,
      children: [
        _ActionButton(
          title: 'Gestionar\nMaterias',
          icon: Icons.auto_stories,
          colors: const [AppColors.primaryGreen, Color(0xFF4CAF50)],
          onTap: onManageSubjects,
        ),
        _ActionButton(
          title: 'Definir\nHorarios',
          icon: Icons.access_time_filled,
          colors: const [AppColors.orangeprimary, Color(0xFFFF7043)],
          onTap: onDefineSchedule,
        ),
        _ActionButton(
          title: 'Mis\nTutorías',
          icon: Icons.video_camera_front,
          colors: const [AppColors.lightBlueColor, Color(0xFF42A5F5)],
          onTap: onMyTutorials,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors[0].withOpacity(0.2),
                colors[1].withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors[0].withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: colors[0].withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}