import 'package:flutter/material.dart';
import 'package:flutter_projects/view/auth/tutor_subject_selection_screen.dart';
import 'package:flutter_projects/view/student/reservations/services/reservations_service.dart';
import 'package:flutter_projects/view/tutor/features/home/providers/tutor_home_provider.dart';
import 'package:flutter_projects/view/tutor/features/home/widgets/banner_terms_section.dart';
import 'package:flutter_projects/view/tutor/features/home/widgets/banner_verification.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';

import 'package:flutter_projects/api_structure/api_service.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TutorHomeProvider>(context, listen: false)
          .loadHomeData(context);
      _loadIdentityStatus();
    });
  }

  Future<void> _loadIdentityStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final userId = authProvider.userId;
    if (token == null || userId == null) return;
    try {
      final response = await getIdentityVerificationStatus(token, userId);
      if (!mounted) return;
      if (response['success'] == true && response['data'] != null) {
        final status = response['data']['status'];
        if (status != null && authProvider.identityVerificationStatus != 'accepted') {
          await authProvider.setIdentityStatus(status.toString());
        }
      }
    } catch (e) {
      print('Error loading identity status: $e');
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
          child: BannerTermsSection(role: 'tutor'),
        ),
      );
    }

    if (identityStatus == 'accepted') {
      if (homeProvider.showVerifiedBanner) {
        alerts.add(
          Align(
            alignment: Alignment.topCenter,
            child: BannerVerification.verified(context, homeProvider),
          ),
        );
      }
    } else if (!isVerified) {
      if (identityStatus == 'rejected') {
        alerts.add(
          Align(
            alignment: Alignment.topCenter,
            child: BannerVerification.rejected(context),
          ),
        );
      } else if (identityStatus == 'pending') {
        alerts.add(
          Align(
            alignment: Alignment.topCenter,
            child: BannerVerification.pending(context),
          ),
        );
      } else {
        alerts.add(
          Align(
            alignment: Alignment.topCenter,
            child: BannerVerification.onboarding(context),
          ),
        );
      }
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

    final double rating = profile['avg_rating'] != null
        ? (profile['avg_rating'] is num
            ? (profile['avg_rating'] as num).toDouble()
            : double.tryParse(profile['avg_rating'].toString()) ?? 4.9)
        : 4.9;

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
          rating: rating,
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
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: activeAlerts.isNotEmpty
                        ? Column(
                            key: const ValueKey('alerts'),
                            children: [
                              const SizedBox(height: 5),
                              _ActionCarouselSection(alerts: activeAlerts),
                            ],
                          )
                        : const SizedBox(key: ValueKey('no_alerts')),
                  ),

                  QuickAccessSection(onNavigate: widget.onNavigate),

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
          height: 300,
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
            padding: const EdgeInsets.only(top: 0.0, bottom: 2.0),
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
