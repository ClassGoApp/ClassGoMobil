import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class SocialLinksWidget extends StatelessWidget {
  const SocialLinksWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialIcon(Icons.facebook_outlined, () {
          debugPrint("Abrir Facebook");
        }),
        const SizedBox(width: 20),
        _buildSocialIcon(Icons.camera_alt_outlined, () {
          debugPrint("Abrir Instagram");
        }),
        const SizedBox(width: 20),
        _buildSocialIcon(Icons.tiktok, () {
          debugPrint("Abrir TikTok");
        }),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.dividerLight),
        ),
        child: Icon(icon, color: AppColors.brandBlue, size: 24),
      ),
    );
  }
}