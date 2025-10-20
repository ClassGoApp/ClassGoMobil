import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/register_screen.dart' show RegistrationScreen;

class BecomeTutorScreen extends StatefulWidget {
  @override
  _BecomeTutorScreenState createState() => _BecomeTutorScreenState();
}

class _BecomeTutorScreenState extends State<BecomeTutorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryGreen,
                    AppColors.darkBlue,
                  ],
                ),
              ),
            ),
            // Content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    // Close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Image.asset(
                          'assets/images/logo_classgo.png',
                          height: 35,
                        ),
                        SizedBox(width: 48), // Balance with back button
                      ],
                    ),
                    SizedBox(height: 30),
                    // Main title with animation - Centrado
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              '💰 Gana dinero',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: AppColors.orangeColor,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'compartiendo tu',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'conocimiento',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: AppColors.lightBlueColor,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Solo necesitas dominar una materia para empezar. Tú defines tus tarifas y horarios.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 40),
                    // Benefits cards with animation
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            _buildBenefitCard(
                              icon: Icons.school,
                              iconColor: AppColors.lightBlueColor,
                              title: 'Requisito simple',
                              description:
                                  'Solo necesitas dominar una materia. Si sabes enseñarla, ya puedes ser tutor.',
                              delay: 0,
                            ),
                            SizedBox(height: 16),
                            _buildBenefitCard(
                              icon: Icons.price_change,
                              iconColor: AppColors.lightGreenColor,
                              title: 'Tú defines tu precio',
                              description:
                                  'Establece tus propias tarifas por hora. Tú decides cuánto vale tu tiempo.',
                              delay: 100,
                            ),
                            SizedBox(height: 16),
                            _buildBenefitCard(
                              icon: Icons.schedule,
                              iconColor: AppColors.orangeColor,
                              title: 'Horario flexible',
                              description:
                                  'Tú decides cuándo trabajar. Perfecta compatibilidad con tus actividades.',
                              delay: 200,
                            ),
                            SizedBox(height: 16),
                            _buildBenefitCard(
                              icon: Icons.laptop_mac,
                              iconColor: AppColors.yellowColor,
                              title: '100% remoto',
                              description:
                                  'Desde tu hogar. Solo necesitas una conexión a internet estable.',
                              delay: 300,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    // Stats section
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat('500+', 'Tutores activos'),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            _buildStat('10k+', 'Clases dadas'),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            _buildStat('4.8★', 'Valoración'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    // CTA Button
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.orangeColor,
                              AppColors.orangeprimary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.orangeColor.withOpacity(0.4),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              // Navegar a registro
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegistrationScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '🚀 Empezar a ganar dinero',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Secondary info
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Center(
                        child: Text(
                          'Registro gratuito • Sin compromisos',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required int delay,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.orangeColor,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

