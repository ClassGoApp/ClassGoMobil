import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/profile/edit_profile_screen.dart';
import 'package:flutter_projects/view/profile/skeleton/profile_image_skeleton.dart';
import 'package:flutter_projects/view/settings/account_settings.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../provider/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  final bool showAppBar;

  const ProfileScreen({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = false;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isLoggedIn) return;

      final int? userId = authProvider.userId;
      if (userId != null) {
        try {
          final response = await http.get(
            Uri.parse('https://classgoapp.com/api/user/$userId/profile-image'),
          );
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            setState(() {
              profileImageUrl = data['profile_image'] as String?;
            });
          }
        } catch (_) {}
      }
    });
  }

  void showCustomToast(BuildContext context, String message, bool isSuccess) {
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 1.0,
        left: 16.0,
        right: 16.0,
        child: CustomToast(
          message: message,
          isSuccess: isSuccess,
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 1), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // 🔒 MODO INVITADO (NO LOGUEADO)
    if (!authProvider.isLoggedIn) {
      return _GuestProfile();
    }

    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.blackColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Mi Perfil',
            style: TextStyle(
              color: AppColors.blackColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _buildProfileContent(context),
      );
    } else {
      return _buildProfileContent(context);
    }
  }

  Widget _buildProfileContent(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;
    final String? fullName = userData != null && userData['user'] != null
        ? (userData['user']['profile']['full_name'] ??
            (userData['user']['profile']['first_name'] != null &&
                    userData['user']['profile']['last_name'] != null
                ? '${userData['user']['profile']['first_name']} ${userData['user']['profile']['last_name']}'
                : userData['user']['profile']['first_name'] ??
                    userData['user']['profile']['last_name']))
        : null;
    final String? email = userData != null && userData['user'] != null
        ? userData['user']['email']
        : null;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Column(
        children: [
          // Información del perfil
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Foto de perfil
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.transparent,
                    child: ClipOval(
                      child:
                          profileImageUrl != null && profileImageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: profileImageUrl!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      ProfileImageSkeleton(radius: 50),
                                  errorWidget: (context, url, error) =>
                                      CircleAvatar(
                                    radius: 50,
                                    backgroundColor:
                                        AppColors.primaryGreen.withOpacity(0.1),
                                    child: Icon(Icons.person,
                                        color: AppColors.primaryGreen,
                                        size: 50),
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 50,
                                  backgroundColor:
                                      AppColors.primaryGreen.withOpacity(0.1),
                                  child: Icon(
                                    Icons.person,
                                    size: 50,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  fullName ?? 'Estudiante',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blackColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  email ?? 'email@ejemplo.com',
                  style: TextStyle(
                    color: AppColors.greyColor,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlueColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Estudiante',
                    style: TextStyle(
                      color: AppColors.lightBlueColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Opciones del perfil
          _buildProfileOption(
            icon: Icons.edit,
            title: 'Editar Perfil',
            subtitle: 'Modificar información personal',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(),
                ),
              );
            },
          ),
          SizedBox(height: 12),
          _buildProfileOption(
            icon: Icons.security,
            title: 'Configuración de Cuenta',
            subtitle: 'Cambiar contraseña y configuración',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AccountSettings(),
                ),
              );
            },
          ),
          SizedBox(height: 12),
          _buildProfileOption(
            icon: Icons.help_outline,
            title: 'Ayuda',
            subtitle: 'Centro de ayuda y soporte',
            onTap: () {
              // TODO: Navegar a ayuda
            },
          ),
          SizedBox(height: 12),
          _buildProfileOption(
            icon: Icons.logout,
            title: 'Cerrar Sesión',
            subtitle: 'Salir de la aplicación',
            color: Colors.red,
            onTap: () {
              _showLogoutDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? AppColors.primaryGreen).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color ?? AppColors.primaryGreen,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.blackColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.greyColor,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppColors.greyColor,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Cerrar Sesión',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.blackColor,
            ),
          ),
          content: Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(
              color: AppColors.greyColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: AppColors.greyColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    setState(() {
      isLoading = true;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        showCustomToast(context, 'Error al cerrar sesión', false);
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}

class _GuestProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.white.withOpacity(0.85),
              ),
              const SizedBox(height: 24),
              Text(
                'Inicia sesión para acceder a tu perfil',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Revisa tu historial, estadísticas, pagos y configuración personal.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightBlueColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Iniciar sesión',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
