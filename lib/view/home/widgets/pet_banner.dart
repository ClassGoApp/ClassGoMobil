import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class MascotBanner extends StatelessWidget {
  const MascotBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          // Un fondo cyan muy suave para que combine con el diseño NeoClean
          color: AppColors.brandCyan.withOpacity(0.08), 
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.brandCyan.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            // --- TEXTO MOTIVACIONAL ---
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Te acompañamos!',
                    style: TextStyle(
                      fontFamily: AppFonts.heading,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandBlue,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Encuentra al tutor ideal para ti y alcanza tus metas hoy mismo.',
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 14,
                      color: AppColors.textLightSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 15),

            // --- EL AVE ANIMADA ---
            Image.asset(
              'assets/images/ave_animada.gif', 
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}