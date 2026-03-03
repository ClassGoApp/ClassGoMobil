import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class VideoPresentationDialog extends StatelessWidget {
  const VideoPresentationDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colores "Neoclean"
    final dialogBgColor = isDark ? const Color(0xFF1A1D24) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandBlue;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey[700];
    final videoPlaceholderColor = isDark ? const Color(0xFF0C0E12) : Colors.grey[200];

    // Usamos Dialog para el centrado y márgenes automáticos
    return Dialog(
      backgroundColor: Colors.transparent, // Hacemos transparente el fondo del Dialog nativo
      insetPadding: const EdgeInsets.symmetric(horizontal: 20), // Margen lateral de la pantalla
      child: Container(
        // Contenedor principal con diseño Neoclean
        decoration: BoxDecoration(
          color: dialogBgColor,
          borderRadius: BorderRadius.circular(24), // Bordes redondeados completos
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.2),
              blurRadius: 25,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Título
                Text(
                  "VIDEO DE PRESENTACIÓN",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900, // Black font
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Placeholder del Video (Aspect Ratio 16:9)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: videoPlaceholderColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                        width: 1.5
                      ),
                    ),
                    child: Center(
                      // Icono de Play
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.brandCyan.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Descripción
                Text(
                  "Hola, soy Sarah. En este breve video te cuento un poco más sobre mi metodología de enseñanza. ¡Espero verte pronto!",
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                // 4. LOS DOS BOTONES FALTANTES
                Row(
                  children: [
                    // Botón Cerrar (Secundario - Outlined)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: isDark ? Colors.white24 : Colors.grey[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          "Cerrar",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey[700],
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Botón Ver Video (Primario - Filled Cyan)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          print("Navegar a pantalla de video completo");
                          Navigator.pop(context); // Cierra el diálogo primero
                          // Aquí navegarías a la vista de reproductor
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandCyan,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0, // Sin sombra extra para que se vea limpio
                        ),
                        child: const Text(
                          "Ver Video",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}