import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/view/tutor/dashboard_tutor.dart';
import 'package:flutter_projects/view/layout/main_shell.dart';

class RoleBasedNavigation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {

        // 1️⃣ Esperar a que la sesión cargue
        if (!authProvider.isSessionLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2️⃣ MODO VISITANTE (NO LOGUEADO)
        if (!authProvider.isLoggedIn) {
          return const MainShell();
        }

        // 3️⃣ TUTOR
        if (authProvider.isTutor) {
          return DashboardTutor();
        }

        // 4️⃣ ESTUDIANTE
        return const MainShell();
      },
    );
  }
}
