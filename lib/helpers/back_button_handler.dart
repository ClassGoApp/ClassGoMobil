import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class BackButtonHandler {
  /// Maneja el botón de volver del dispositivo de manera inteligente
  /// 
  /// [context] - El contexto de la aplicación
  /// [isLoading] - Si la pantalla está en estado de carga
  /// [showExitDialog] - Si mostrar el diálogo de confirmación para salir (default: true)
  /// 
  /// Retorna true si se debe permitir el cierre, false en caso contrario
  static Future<bool> handleBackButton(
    BuildContext context, {
    bool isLoading = false,
    bool showExitDialog = true,
  }) async {
    // Si está cargando, no permitir salir
    if (isLoading) {
      return false;
    }
    
    // Si el teclado está abierto, solo cerrarlo
    if (MediaQuery.of(context).viewInsets.bottom > 0) {
      FocusScope.of(context).unfocus();
      return false;
    }
    
    // Si no se debe mostrar el diálogo, permitir salir
    if (!showExitDialog) {
      return true;
    }
    
    // Mostrar diálogo de confirmación para salir
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Salir de la aplicación',
          style: TextStyle(
            fontSize: FontSize.scale(context, 18),
            color: AppColors.blackColor,
            fontFamily: 'SF-Pro-Text',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '¿Estás seguro de que quieres salir de la aplicación?',
          style: TextStyle(
            fontSize: FontSize.scale(context, 14),
            color: AppColors.blackColor,
            fontFamily: 'SF-Pro-Text',
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                fontSize: FontSize.scale(context, 14),
                color: AppColors.primaryGreen,
                fontFamily: 'SF-Pro-Text',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Salir',
              style: TextStyle(
                fontSize: FontSize.scale(context, 14),
                color: AppColors.redColor,
                fontFamily: 'SF-Pro-Text',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }
}
