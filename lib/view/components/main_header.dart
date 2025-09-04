import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_projects/view/home/home_screen.dart';

class MainHeader extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onProfilePressed;
  final bool showMenuButton;
  final bool showProfileButton;
  final bool showBackButton;

  const MainHeader({
    Key? key,
    this.onMenuPressed,
    this.onProfilePressed,
    this.showMenuButton = true,
    this.showProfileButton = true,
    this.showBackButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primaryGreen, // Color de fondo del AppBar
      automaticallyImplyLeading:
          false, // Controlado por el icono de menú personalizado
      elevation: 0, // Sin sombra
      titleSpacing: 0, // Sin espacio adicional para el título
      centerTitle: true, // Centrar el título/logo
      leading: showBackButton
          ? Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios,
                    color: AppColors.whiteColor, size: 24),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                    (route) => false,
                  );
                },
              ),
            )
          : showMenuButton
              ? Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: IconButton(
                    icon: Icon(Icons.menu,
                        color: AppColors
                            .whiteColor), // Icono de menú de hamburguesa
                    onPressed: onMenuPressed,
                  ),
                )
              : null,
      title: GestureDetector(
        onTap: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomeScreen()),
            (route) => false,
          );
        },
        child: Image.asset(
          'assets/images/logo_classgo.png',
          height: 38, // Ajusta la altura según sea necesario
        ),
      ),
      actions: [
        if (showProfileButton)
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              icon: SvgPicture.asset(
                AppImages.userIcon, // Tu icono de usuario
                color: AppColors.whiteColor,
                height: 24,
              ),
              onPressed: onProfilePressed,
            ),
          ),
      ],
    );
  }
}
