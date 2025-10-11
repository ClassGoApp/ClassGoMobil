import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/view/home/home_screen.dart';
import 'package:flutter_projects/view/tutor/dashboard_tutor.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/splash/splash_screen.dart';

class RoleBasedNavigation extends StatefulWidget {
  @override
  _RoleBasedNavigationState createState() => _RoleBasedNavigationState();
}

class _RoleBasedNavigationState extends State<RoleBasedNavigation> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Mostrar splash screen por 3 segundos
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar splash screen primero
    if (_showSplash) {
      return SplashScreen();
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Mostrar pantalla de carga mientras la sesión no esté lista
        if (!authProvider.isSessionLoaded) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Si no está autenticado, mostrar login
        if (!authProvider.isLoggedIn) {
          return LoginScreen();
        }

        // Si está autenticado, detectar rol y mostrar dashboard correspondiente
        if (authProvider.isTutor) {
          return DashboardTutor();
        } else {
          // Para estudiantes y cualquier otro rol, usar HomeScreen
          return HomeScreen();
        }
      },
    );
  }
}
