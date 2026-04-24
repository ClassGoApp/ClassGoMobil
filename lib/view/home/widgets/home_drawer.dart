import 'package:flutter/material.dart';
import 'package:flutter_projects/helpers/auth_helper.dart';
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
              color: AppColors.brandBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 13,
              left: 20,
              right: 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset('assets/images/logo_classgo.png', height: 30),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildDrawerItem(Icons.bolt, 'Tutor al instante',
                      isPrimary: true, onTap: () {
                    Navigator.pop(context);
                    AuthHelper.requireAuth(context,
                        customTitle: 'Tutor',
                        customMessage: 'Inicia sesión primero.');
                  }),
                  _buildDrawerItem(Icons.search, 'Buscar Tutores', onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SearchTutorsScreen()));
                  }),
                  _buildDrawerItem(Icons.people_outline, 'Sobre Nosotros',
                      onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => AboutUsScreen()));
                  }),
                  _buildDrawerItem(Icons.help_outline, 'Preguntas', onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => SupportScreen()));
                  }),
                ],
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => LoginScreen()));
                  },
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text('Iniciar Sesión',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'outfit')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 30),
                const SocialLinksWidget(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title,
      {bool isPrimary = false, required VoidCallback onTap}) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 30.0, vertical: 4.0),
      leading: Icon(icon,
          color: isPrimary ? AppColors.brandOrange : AppColors.brandBlue,
          size: 26),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'outfit',
          color: isPrimary ? AppColors.brandOrange : AppColors.textLightPrimary,
          fontSize: 18,
          fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}
