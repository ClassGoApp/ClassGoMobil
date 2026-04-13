import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class AboutUsScreen extends StatelessWidget {
  static const String _titleFont = 'outfit';
  static const String _bodyFont = 'manrope';

  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.brandBlue),
        title: const Text(
          'Sobre Nosotros',
          style: TextStyle(
            fontFamily: _titleFont,
            color: AppColors.brandBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(), 
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue,
                  borderRadius: BorderRadius.circular(24), 
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandBlue.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.rocket_launch_rounded,
                        size: 60,
                        color: AppColors.brandOrange, 
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Tu futuro empieza hoy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: _titleFont,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              const Text(
                '¿Quiénes Somos?',
                style: TextStyle(
                  fontFamily: _titleFont,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandBlue,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Somos una plataforma de tutorías en línea que conecta a estudiantes de todas las edades con tutores expertos. Ofrecemos una experiencia accesible y de calidad, independientemente de tu ubicación u horario.',
                style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.blackColor.withOpacity(0.85),
                ),
              ),

              const SizedBox(height: 30),

              _buildInfoCard(
                icon: Icons.flag_rounded,
                iconColor: AppColors.primaryGreen,
                title: 'Misión',
                subtitle: 'Plataforma educativa de tutorías virtuales para compartir conocimientos.',
                bodyText: 'Proporcionamos una plataforma educativa de tutorías virtuales accesibles las 24 horas, dirigida a toda persona que quiera compartir su conocimiento, con contenidos que abarcan desde nivel universitario hasta habilidades técnicas.',
              ),

              _buildInfoCard(
                icon: Icons.visibility_rounded,
                iconColor: AppColors.brandOrange,
                title: 'Visión',
                subtitle: 'Impulsar el crecimiento del aprendizaje.',
                bodyText: 'Ser la plataforma líder en tutorías virtuales, fomentando el aprendizaje continuo y la accesibilidad educativa en todas las áreas del conocimiento.',
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String bodyText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20), 
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: _titleFont,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: _titleFont,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.blackColor, 
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bodyText,
            style: TextStyle(
              fontFamily: _bodyFont,
              fontSize: 14,
              height: 1.6,
              color: AppColors.blackColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}