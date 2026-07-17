import 'package:flutter/material.dart';
import 'package:flutter_projects/helpers/auth_helper.dart';
import 'package:flutter_projects/styles/app_design.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/home/widgets/about_us_screen.dart';
import 'package:flutter_projects/view/home/widgets/social_links.dart';
import 'package:flutter_projects/view/home/widgets/suport_screen.dart';
import 'package:flutter_projects/view/student/serch_Tutor/search_tutors_screen.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.cardLight,
      surfaceTintColor: Colors.transparent,
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0E3A4F), AppColors.brandBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppRadius.xl),
                bottomRight: Radius.circular(AppRadius.xl),
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppSpacing.md,
              bottom: AppSpacing.lg,
              left: AppSpacing.xxxl,
              right: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset('assets/images/logo_classgo.png', height: 32),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 26),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildDrawerItem(Icons.bolt_rounded, 'Tutor al instante',
                      isPrimary: true, onTap: () {
                    Navigator.pop(context);
                    AuthHelper.requireAuth(context,
                        customTitle: 'Tutor',
                        customMessage: 'Inicia sesión primero.');
                  }),
                  _buildDrawerItem(Icons.search_rounded, 'Buscar Tutores', onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SearchTutorsScreen()));
                  }),
                  _buildDrawerItem(Icons.people_outline_rounded, 'Sobre Nosotros',
                      onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => AboutUsScreen()));
                  }),
                  _buildDrawerItem(Icons.help_outline_rounded, 'Preguntas Frecuentes', onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => SupportScreen()));
                  }),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xxxl,
              horizontal: AppSpacing.xxxl,
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => LoginScreen()));
                    },
                    icon: const Icon(Icons.login_rounded,
                        color: Colors.white, size: 20),
                    label: const Text('Iniciar Sesión',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: AppFonts.heading,
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandOrange,
                      disabledBackgroundColor: AppColors.brandBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.lg)),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const SocialLinksWidget(),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title,
      {bool isPrimary = false, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: isPrimary ? AppColors.brandOrange.withOpacity(0.05) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxxl,
          vertical: AppSpacing.xxs,
        ),
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isPrimary
                ? AppColors.brandOrange.withOpacity(0.1)
                : AppColors.brandCyan.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon,
              color: isPrimary ? AppColors.brandOrange : AppColors.brandCyan,
              size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: AppFonts.heading,
            color: isPrimary
                ? AppColors.brandOrange
                : AppColors.textLightPrimary,
            fontSize: 16,
            fontWeight:
                isPrimary ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: AppColors.lightGreyColor,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }
}
