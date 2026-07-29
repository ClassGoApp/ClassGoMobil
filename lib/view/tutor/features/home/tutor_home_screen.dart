import 'package:flutter/material.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
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
import 'package:flutter_projects/view/tutor/features/home/widgets/solicitud_flexible_card.dart';

class TutorHomeScreen extends StatefulWidget {
  final Function(int) onNavigate;

  const TutorHomeScreen({Key? key, required this.onNavigate}) : super(key: key);

  @override
  State<TutorHomeScreen> createState() => _TutorHomeScreenState();
}

class _TutorHomeScreenState extends State<TutorHomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TutorHomeProvider>(context, listen: false)
          .loadHomeData(context);
      _loadIdentityStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print(
          '📱 [TutorHomeScreen] App reanudada desde segundo plano. Cargando solicitudes flexibles...');
      try {
        final homeProvider =
            Provider.of<TutorHomeProvider>(context, listen: false);
        homeProvider.loadPendingFlexibleRequestsFromStorage();
      } catch (e) {
        print('Error reanudando solicitudes flexibles: $e');
      }
    }
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
        if (status != null &&
            authProvider.identityVerificationStatus != 'accepted') {
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
          child:
              SolicitudTutoriaCard(data: homeProvider.pendingTutoringRequest!),
        ),
      );
    }

    for (int i = 0; i < homeProvider.pendingFlexibleRequests.length; i++) {
      final reqData = homeProvider.pendingFlexibleRequests[i];
      alerts.add(
        Align(
          alignment: Alignment.topCenter,
          child: SolicitudFlexibleCard(
            key: ValueKey('flexible_req_${i}_${reqData['token'] ?? reqData.hashCode}'),
            data: reqData,
          ),
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
    final String userName = user != null ? (user['name'] ?? AppLocalizations.of(context)!.defaultTutorName) : AppLocalizations.of(context)!.defaultTutorName;

    String? imageUrl = profile['image'] ?? profile['profile_image'];

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
                            key: ValueKey(
                                'alerts_${activeAlerts.length}_${homeProvider.pendingFlexibleRequest != null}'),
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
                          subjectName: booking['subject_name'] ?? AppLocalizations.of(context)!.defaultSubjectName,
                          tutorName: booking['tutor_name'] ?? AppLocalizations.of(context)!.defaultTutorName,
                          studentName: booking['student_name'] ?? AppLocalizations.of(context)!.defaultStudentName,
                          start: start,
                          end: end,
                          status: booking['status'] ?? AppLocalizations.of(context)!.defaultPendingStatus,
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

  const _ActionCarouselSection({Key? key, required this.alerts})
      : super(key: key);

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
  void didUpdateWidget(covariant _ActionCarouselSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.alerts.length > oldWidget.alerts.length) {
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
      setState(() {
        _currentPage = 0;
      });
    }
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
      // TODO: mover las traducciones al onboarding
      //   ],
      // ),
      // child: Column(
      //   crossAxisAlignment: CrossAxisAlignment.start,
      //   children: [
      //     Row(
      //       children: [
      //         Container(
      //           padding: const EdgeInsets.all(8),
      //           decoration: BoxDecoration(
      //             color: Colors.white.withOpacity(0.2),
      //             shape: BoxShape.circle,
      //           ),
      //           child: const Icon(Icons.rocket_launch_rounded,
      //               color: Colors.white, size: 24),
      //         ),
      //         const SizedBox(width: 12),
      //         Expanded(
      //           child: Text(
      //             AppLocalizations.of(context)!.onboardingBannerTitle,
      //             style: TextStyle(
      //               fontFamily: 'outfit',
      //               fontSize: 18,
      //               fontWeight: FontWeight.bold,
      //               color: Colors.white,
      //             ),
      //           ),
      //         ),
      //       ],
      //     ),
      //     const SizedBox(height: 12),
      //     Text(
      //       AppLocalizations.of(context)!.onboardingBannerSubtitle,
      //       style: TextStyle(
      //         fontFamily: 'manrope',
      //         fontSize: 14,
      //         color: Colors.white.withOpacity(0.9),
      //         height: 1.4,
      //       ),
      //     ),
      //     const SizedBox(height: 16),
      //     SizedBox(
      //       width: double.infinity,
      //       height: 48,
      //       child: ElevatedButton(
      //         onPressed: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(
      //                 builder: (context) => const TutorOnboardingScreen()),
      //           );
      //         },
      //         style: ElevatedButton.styleFrom(
      //           backgroundColor: Colors.white,
      //           foregroundColor: const Color(0xFFF76B1C),
      //           elevation: 0,
      //           shape: RoundedRectangleBorder(
      //               borderRadius: BorderRadius.circular(12)),
      //         ),
      //         child: Text(
      //           AppLocalizations.of(context)!.onboardingBannerButton,
      //           style: TextStyle(
      //             fontFamily: 'outfit',
      //             fontSize: 16,
      //             fontWeight: FontWeight.bold,
      //           ),
      //         ),
      //       ),
      //     ),
      //   ],
      // ),
    );
  }
}
