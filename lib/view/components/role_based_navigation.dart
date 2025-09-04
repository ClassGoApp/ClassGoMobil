import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/view/home/home_screen.dart';
import 'package:flutter_projects/view/tutor/dashboard_tutor.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';

class RoleBasedNavigation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
