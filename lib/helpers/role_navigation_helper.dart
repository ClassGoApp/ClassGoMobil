import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/view/home/home_screen.dart';
import 'package:flutter_projects/view/tutor/dashboard_tutor.dart';

class RoleNavigationHelper {
  /// Navega al dashboard correspondiente según el rol del usuario
  static void navigateToRoleDashboard(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isTutor) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardTutor()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  /// Obtiene el nombre del rol del usuario
  static String getUserRoleName(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isTutor) {
      return 'Tutor';
    } else if (authProvider.isStudent) {
      return 'Estudiante';
    } else {
      return 'Usuario';
    }
  }

  /// Verifica si el usuario tiene permisos de tutor
  static bool hasTutorPermissions(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.isTutor;
  }

  /// Verifica si el usuario tiene permisos de estudiante
  static bool hasStudentPermissions(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.isStudent;
  }

  /// Muestra un diálogo de confirmación para cambiar de rol
  static void showRoleChangeDialog(BuildContext context, String newRole) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cambiar Rol'),
          content:
              Text('¿Estás seguro de que quieres cambiar tu rol a $newRole?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implementar cambio de rol en el backend
                navigateToRoleDashboard(context);
              },
              child: Text(
                'Confirmar',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }
}
