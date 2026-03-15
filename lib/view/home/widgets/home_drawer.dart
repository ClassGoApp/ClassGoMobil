import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/home/widgets/social_links.dart'; 

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.cardLight, 
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textLightPrimary, size: 28),
                    onPressed: () => Navigator.pop(context), 
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 10),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildDrawerItem(Icons.bolt, 'Tutor al instante', isPrimary: true),
                    _buildDrawerItem(Icons.search, 'Buscar Tutores'),
                    _buildDrawerItem(Icons.people_outline, 'Mis Tutores'),
                    _buildDrawerItem(Icons.calendar_today_outlined, 'Mis Sesiones'),
                    _buildDrawerItem(Icons.account_balance_wallet_outlined, 'Mi Billetera'),
                  ],
                ),
              ),
            ),

            const Divider(color: AppColors.dividerLight, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                children: [
                  _buildDrawerItem(Icons.settings_outlined, 'Configuración'),
                  const SizedBox(height: 30),
                  const SocialLinksWidget(), 
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, {bool isPrimary = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 4.0),
      leading: Icon(
        icon, 
        color: isPrimary ? AppColors.brandOrange : AppColors.brandBlue, 
        size: 26,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'outfit',
          color: isPrimary ? AppColors.brandOrange : AppColors.textLightPrimary,
          fontSize: 18,
          fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      onTap: () {
        debugPrint("Navegar a $title");
      },
    );
  }
}