import 'package:flutter/material.dart';
import 'package:flutter_projects/helpers/social_media_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // 👈 IMPORTANTE
import 'package:flutter_projects/styles/app_styles.dart';

class SocialLinksWidget extends StatelessWidget {
  const SocialLinksWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildSocialIcon(
          icon: FontAwesomeIcons.facebook,
          iconColor: const Color(0xFF1877F2),
          onTap: () => LauncherHelper.launchURL(
              "https://www.facebook.com/profile.php?id=61586980560794"),
        ),

        _buildInstagramIcon(
          onTap: () =>
              LauncherHelper.launchURL("https://www.instagram.com/classgo_app"),
        ),

        _buildSocialIcon(
          icon: FontAwesomeIcons.tiktok,
          iconColor: Colors.black,
          onTap: () =>
              LauncherHelper.launchURL("https://www.tiktok.com/@classgoapp"),
        ),

        // // YOUTUBE
        // _buildSocialIcon(
        //   icon: FontAwesomeIcons.youtube,
        //   iconColor: const Color(0xFFFF0000),
        //   onTap: () => LauncherHelper.launchURL("https://youtube.com/c/tu_canal"),
        // ),

        // LINKEDIN
        _buildSocialIcon(
          icon: FontAwesomeIcons.linkedinIn,
          iconColor: const Color(0xFF0A66C2),
          onTap: () => LauncherHelper.launchURL(
              "https://www.linkedin.com/company/classgoapp/about/?viewAsMember=true"),
        ),
      ],
    );
  }

  Widget _buildSocialIcon(
      {required dynamic icon,
      required Color iconColor,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.dividerLight),
        ),
        child: FaIcon(icon, color: iconColor, size: 22),
      ),
    );
  }

  Widget _buildInstagramIcon({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.dividerLight),
        ),
        child: ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              colors: [
                Color(0xFF833AB4),
                Color(0xFFFD1D1D),
                Color(0xFFF56040),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ).createShader(bounds);
          },
          child: const FaIcon(
            FontAwesomeIcons.instagram,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
