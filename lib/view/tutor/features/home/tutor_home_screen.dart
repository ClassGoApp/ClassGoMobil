import 'package:flutter/material.dart';
import 'package:flutter_projects/provider/onboarding_provider.dart';
import 'package:flutter_projects/view/auth/tutor_subject_selection_screen.dart';
import 'package:flutter_projects/view/student/reservations/services/reservations_service.dart';
import 'package:flutter_projects/view/tutor/features/home/providers/tutor_home_provider.dart';
import 'package:flutter_projects/view/tutor/features/home/widgets/terms_acceptance_section.dart';
import 'package:flutter_projects/view/tutor/onboarding/onboarding_provider.dart';
import 'package:flutter_projects/view/tutor/onboarding/onboarding_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';

import 'package:flutter_projects/provider/auth_provider.dart';

import 'package:flutter_projects/view/tutor/dashboard/widgets/quick_access_section.dart';
import 'package:flutter_projects/view/tutor/dashboard/widgets/dashboard_top_section.dart';
import 'package:flutter_projects/view/tutor/dashboard/widgets/next_appointment_section.dart';
import 'package:flutter_projects/view/tutor/features/home/widgets/solicitud_tutoria_card.dart';

class TutorHomeScreen extends StatefulWidget {
  final Function(int) onNavigate;

  const TutorHomeScreen({Key? key, required this.onNavigate}) : super(key: key);

  @override
  State<TutorHomeScreen> createState() => _TutorHomeScreenState();
}

class _TutorHomeScreenState extends State<TutorHomeScreen> {
  bool _hasTriggeredVerifiedBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TutorHomeProvider>(context, listen: false)
          .loadHomeData(context);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    final homeProvider = Provider.of<TutorHomeProvider>(context);
    final profile = authProvider.userData?['user']?['profile'] ?? {};
    final bool isVerified = profile['verified'] == true;

    if (isVerified && !_hasTriggeredVerifiedBanner) {
      _hasTriggeredVerifiedBanner = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        homeProvider.showVerifiedBannerBriefly();
      });
    } else if (!isVerified) {
      _hasTriggeredVerifiedBanner = false;
    }
  }

  List<Widget> _buildActiveAlerts(
    BuildContext context,
    TutorHomeProvider homeProvider,
    String? identityStatus,
    bool isVerified,
    bool hasAcceptedTerms,
  ) {
    List<Widget> alerts = [];

    if (homeProvider.pendingTutoringRequest != null) {
      alerts.add(
        Align(
          alignment: Alignment.topCenter,
          child: SolicitudTutoriaCard(data: homeProvider.pendingTutoringRequest!),
        ),
      );
    }

    if (!hasAcceptedTerms) {
      alerts.add(
        const Align(
          alignment: Alignment.topCenter,
          child: TermsAcceptanceSection(role: 'tutor'),
        ),
      );
    }

    if (!isVerified) {
      if (identityStatus == 'rejected') {
        alerts.add(
          Align(
            alignment: Alignment.topCenter,
            child: _buildRejectedBanner(context),
          ),
        );
      } else if (identityStatus == 'pending') {
        alerts.add(
          Align(
            alignment: Alignment.topCenter,
            child: _buildPendingBanner(context),
          ),
        );
      } else {
        alerts.add(
          Align(
            alignment: Alignment.topCenter,
            child: _buildOnboardingBanner(context),
          ),
        );
      }
    } else if (homeProvider.showVerifiedBanner) {
      alerts.add(
        Align(
          alignment: Alignment.topCenter,
          child: _buildVerifiedBanner(context, homeProvider),
        ),
      );
    }

    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final homeProvider = Provider.of<TutorHomeProvider>(context);

    final user = authProvider.userData?['user'];
    final profile = user?['profile'] ?? {};
    final String userName = user != null ? (user['name'] ?? 'Tutor') : 'Tutor';

    String? imageUrl =
        profile['image'] ?? profile['profile_image'];

    final bool isVerified = profile['verified'] == true;
    final bool hasAcceptedTerms = user?['terms_accepted'] == true;
    final String? identityStatus = authProvider.identityVerificationStatus;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl
          .contains('https://classgoapp.com/storagehttps://classgoapp.com')) {
        imageUrl = imageUrl.replaceFirst(
            'https://classgoapp.com/storagehttps://classgoapp.com',
            'https://classgoapp.com');
      } else if (imageUrl.contains('/storage/storage/')) {
        imageUrl = imageUrl.replaceFirst('/storage/storage/', '/storage/');
      }
    }

    final activeAlerts = _buildActiveAlerts(
      context,
      homeProvider,
      identityStatus,
      isVerified,
      hasAcceptedTerms,
    );

    return Column(
      children: [
        DashboardTopSection(
          tutorName: userName,
          profileImageUrl: imageUrl,
          rating: 4.9,
          isVerified: isVerified,
          isLoadingImage: homeProvider.isLoading,
          isAvailable: homeProvider.isAvailable,
          onLogoutTap: () => authProvider.logout(),
          onAvailabilityToggle: (newState) =>
              homeProvider.handleAvailabilityToggle(context, newState),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.brandCyan,
            displacement: 20,
            onRefresh: () async {
              await homeProvider.refreshOnlySubjects(context);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                children: [
                  if (activeAlerts.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    _ActionCarouselSection(alerts: activeAlerts),
                  ] else ...[
                    const SizedBox(height: 25), // Espacio normal si no hay ninguna alerta
                  ],
                  // CARROUSEL DE BANNERS
                  // if (homeProvider.pendingTutoringRequest != null ||
                  //     showOnboardingBanner) ...[
                  //   const SizedBox(height: 15),
                  //   SizedBox(
                  //     height: 230,  
                  //     child: PageView(
                  //       physics: const BouncingScrollPhysics(),
                  //       controller: PageController(viewportFraction: 0.92),
                  //       children: [
                  //         if (homeProvider.pendingTutoringRequest != null)
                  //           SolicitudTutoriaCard(
                  //               data: homeProvider.pendingTutoringRequest!),

                  //         // COMENTADO TEMPORALMENTE HASTA TENER LÓGICA
                  //         if (showOnboardingBanner)
                  //           _buildOnboardingBanner(context),
                  //       ],
                  //     ),
                  //   ),
                  // ],

                  // if (homeProvider.pendingTutoringRequest == null &&
                  //     !showOnboardingBanner)
                  //   const SizedBox(height: 25),

                  QuickAccessSection(onNavigate: widget.onNavigate),

                  
                  // if (!hasAcceptedTerms)
                  //   const TermsAcceptanceSection(role: 'tutor')
                  // else
                  //   const SizedBox.shrink(),

                  NextAppointmentSection(
                    isAvailable: homeProvider.isAvailable,
                    onNavigate: widget.onNavigate,
                    appointments: homeProvider.nextBooking!.map((booking) {
                      final start =
                          DateTime.tryParse(booking['start_time'] ?? '') ??
                              DateTime.now();
                      final end =
                          DateTime.tryParse(booking['end_time'] ?? '') ??
                              start.add(const Duration(minutes: 20));
                              
                      return ReservationItem(
                          id: booking['id'] ?? 0,
                          subjectName: booking['subject_name'] ?? 'Tutoría',
                          tutorName: booking['tutor_name'] ?? 'Tutor',
                          studentName: booking['student_name'] ?? 'Estudiante',
                          start: start,
                          end: end,
                          status: booking['status'] ?? 'pendiente',
                          meetingLink: booking['meeting_link'] ?? '');
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOnboardingBanner(BuildContext context) {const Color cardBg = Color(0xFFF76B1C); 
    const Color cardGradientStart = Color(0xFFF5A623); 
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Vertical reducido para encajar bien en el PageView
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [cardGradientStart, cardBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cardBg.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                ),
                child: BackdropFilter(
                  filter: ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 50,
                          spreadRadius: 15,
                        )
                      ]
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '¡Estás a un paso\nde enseñar!',
                          style: TextStyle(
                            fontFamily: 'outfit',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Completa tu identidad y credenciales para mantener la plataforma segura y recibir estudiantes.',
                    style: TextStyle(
                      fontFamily: 'manrope',
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: cardBg,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      ),
                      child: const Text(
                        'COMPLETAR PERFIL',
                        style: TextStyle(
                          fontFamily: 'outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
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

  Widget _buildPendingBanner(BuildContext context) {
    const Color pendingBg = Color(0xFF4A90E2);
    const Color pendingStart = Color(0xFF5BA0F0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [pendingStart, pendingBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: pendingBg.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -40, top: -40,
              child: Container(
                width: 130, height: 130,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.hourglass_empty_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Verificación en proceso',
                          style: TextStyle(
                            fontFamily: 'outfit',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tus datos están siendo revisados por nuestro equipo. Te notificaremos cuando el proceso haya terminado.',
                    style: TextStyle(
                      fontFamily: 'manrope',
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
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

  Widget _buildVerifiedBanner(BuildContext context, TutorHomeProvider homeProvider) {
    const Color verifiedBg = Color(0xFF2ECC71);
    const Color verifiedStart = Color(0xFF27AE60);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [verifiedStart, verifiedBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: verifiedBg.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -40, top: -40,
              child: Container(
                width: 130, height: 130,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '¡Tutor Verificado!',
                          style: TextStyle(
                            fontFamily: 'outfit',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tu identidad ha sido verificada exitosamente. Ya puedes recibir estudiantes.',
                    style: TextStyle(
                      fontFamily: 'manrope',
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
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

  Widget _buildRejectedBanner(BuildContext context) {
    const Color rejectedBg = Color(0xFFE74C3C);
    const Color rejectedStart = Color(0xFFC0392B);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [rejectedStart, rejectedBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: rejectedBg.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -40, top: -40,
              child: Container(
                width: 130, height: 130,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Verificación Rechazada',
                          style: TextStyle(
                            fontFamily: 'outfit',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hubo un problema con tus documentos. Vuelve a intentar con fotos más claras y legibles.',
                    style: TextStyle(
                      fontFamily: 'manrope',
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: rejectedBg,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      ),
                      child: const Text(
                        'REINTENTAR',
                        style: TextStyle(
                          fontFamily: 'outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
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
}

class _ActionCarouselSection extends StatefulWidget {
  final List<Widget> alerts;

  const _ActionCarouselSection({Key? key, required this.alerts}) : super(key: key);

  @override
  State<_ActionCarouselSection> createState() => _ActionCarouselSectionState();
}

class _ActionCarouselSectionState extends State<_ActionCarouselSection> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.95);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showIndicators = widget.alerts.length > 1;

    return Column(
      children: [
        SizedBox(
          height: 400,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: widget.alerts.length,
            itemBuilder: (context, index) {
              return widget.alerts[index];
            },
          ),
        ),
        if (showIndicators)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.alerts.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  height: 4.0,
                  width: _currentPage == index ? 24.0 : 12.0,
                  decoration: BoxDecoration(
                    color: _currentPage == index 
                        ? AppColors.brandCyan 
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
