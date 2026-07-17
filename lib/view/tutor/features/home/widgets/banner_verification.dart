import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/provider/onboarding_provider.dart';
import 'package:flutter_projects/view/tutor/onboarding/onboarding_screen.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/tutor/features/home/providers/tutor_home_provider.dart';
import 'banner_card.dart';

class BannerVerification {
  static Widget onboarding(BuildContext context) {
    const Color cardBg = Color(0xFFF76B1C);
    return BannerCard(
      gradientColors: [const Color(0xFFF5A623), cardBg],
      leading: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 24),
      title: _title('¡Estás a un paso\nde enseñar!'),
      description:
          'Completa tu identidad y credenciales para mantener la plataforma segura y recibir estudiantes.',
      button: _buildButton(
        'COMPLETAR PERFIL',
        cardBg,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider(
                create: (_) => OnboardingProvider(),
                child: const OnboardingScreen(role: 'tutor'),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget pending(BuildContext context) {
    const Color pendingBg = Color(0xFF4A90E2);
    return BannerCard(
      gradientColors: [const Color(0xFF5BA0F0), pendingBg],
      leading: const Icon(Icons.hourglass_empty_rounded, color: Colors.white, size: 24),
      title: _title('Verificación en proceso'),
      description:
          'Tus datos están siendo revisados por nuestro equipo. Te notificaremos cuando el proceso haya terminado.',
      button: _buildCancelButton(context, pendingBg),
    );
  }

  static Widget verified(BuildContext context, TutorHomeProvider homeProvider) {
    return BannerCard(
      gradientColors: [const Color(0xFF27AE60), const Color(0xFF2ECC71)],
      leading: const Icon(Icons.verified_rounded, color: Colors.white, size: 24),
      title: _title('¡Tutor Verificado!'),
      description:
          'Tu identidad ha sido verificada exitosamente. Ya puedes recibir estudiantes.',
    );
  }

  static Widget rejected(BuildContext context) {
    const Color rejectedBg = Color(0xFFE74C3C);
    return BannerCard(
      gradientColors: [const Color(0xFFC0392B), rejectedBg],
      leading: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 24),
      title: _title('Verificación Rechazada'),
      description:
          'Hubo un problema con tus documentos. Vuelve a intentar con fotos más claras y legibles.',
      button: _buildButton(
        'REINTENTAR',
        rejectedBg,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider(
                create: (_) => OnboardingProvider(),
                child: const OnboardingScreen(role: 'tutor'),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _title(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'outfit',
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        height: 1.2,
      ),
    );
  }

  static Widget _buildButton(String text, Color foregroundColor, VoidCallback onPressed) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: foregroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'outfit',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  static Widget _buildCancelButton(BuildContext context, Color pendingBg) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.brandOrange, size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cancelar verificación',
                      style: TextStyle(
                        fontFamily: 'outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandBlue,
                      ),
                    ),
                  ),
                ],
              ),
              content: const Text(
                'Si cancelas, tu solicitud de verificación será eliminada y deberás volver a enviar tus documentos desde cero.',
                style: TextStyle(
                  fontFamily: 'manrope',
                  fontSize: 14,
                  color: AppColors.textLightSecondary,
                  height: 1.4,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text(
                    'MANTENER',
                    style: TextStyle(
                        fontFamily: 'outfit', fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'CANCELAR & REENVIAR',
                    style: TextStyle(
                      fontFamily: 'outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          );
          if (confirmed != true) return;

          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          final token = authProvider.token;
          final userId = authProvider.userId;
          if (token == null || userId == null) return;

          final result = await cancelIdentityVerification(token, userId);
          if (result['success'] == true) {
            await authProvider.setIdentityStatus(null);
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider(
                    create: (_) => OnboardingProvider(),
                    child: const OnboardingScreen(role: 'tutor'),
                  ),
                ),
                (route) => false,
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: pendingBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        icon: const Icon(Icons.refresh_rounded, size: 20),
        label: const Text(
          'CANCELAR & REENVIAR',
          style: TextStyle(
            fontFamily: 'outfit',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
