import 'package:flutter/material.dart';
import 'package:flutter_projects/view/tutor/features/home/providers/tutor_home_provider.dart';
import 'package:flutter_projects/view/tutor/onboarding/tutor_onboarding_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';

import 'package:flutter_projects/provider/auth_provider.dart';

import 'package:flutter_projects/view/tutor/dashboard/widgets/quick_access_section.dart';
import 'package:flutter_projects/view/tutor/dashboard/widgets/dashboard_top_section.dart';
import 'package:flutter_projects/view/tutor/dashboard/widgets/next_appointment_section.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final homeProvider = Provider.of<TutorHomeProvider>(context);

    final user = authProvider.userData?['user'];
    final String userName = user != null ? (user['name'] ?? 'Tutor') : 'Tutor';

    String? imageUrl =
        user?['profile']?['image'] ?? user?['profile']?['profile_image'];

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

    final bool isProfileComplete = false;

    return Column(
      children: [
        DashboardTopSection(
          tutorName: userName,
          profileImageUrl: imageUrl,
          rating: 4.9,
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
                  if (!isProfileComplete) ...[
                    const SizedBox(height: 10),
                    _buildOnboardingBanner(context),
                    const SizedBox(height: 20),
                  ] else ...[
                    const SizedBox(height: 25),
                  ],

                  // SECCIONES LIBRES
                  QuickAccessSection(onNavigate: widget.onNavigate),

                  const SizedBox(height: 20),

                  NextAppointmentSection(
                    isAvailable: homeProvider.isAvailable,
                    appointments:homeProvider.nextBooking!.map((booking) {
                      final start =
                          DateTime.tryParse(booking['start_time'] ?? '') ??
                              DateTime.now();
                      final end =
                          DateTime.tryParse(booking['end_time'] ?? '') ??
                              start.add(const Duration(minutes: 20));

                      final dateFormatted =
                          '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year}';
                      final time =
                          '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
                      final timeEnd =
                          '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

                      return AppointmentModel(
                          id: booking['id'] ?? 0,
                          title: booking['subject_name'] ?? 'Tutoría',
                          studentName: booking['student_name'] ?? 'Estudiante',
                          date: dateFormatted,
                          time: time,
                          endTime: timeEnd,
                          status: booking['status'] ?? 'pendiente',
                          meetLink: booking['meeting_link'] ?? '');
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

  Widget _buildOnboardingBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5A623), Color(0xFFF76B1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF76B1C).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rocket_launch_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '¡Estás a un paso de enseñar!',
                  style: TextStyle(
                    fontFamily: 'outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tu perfil está incompleto. Configúralo ahora para empezar a recibir estudiantes.',
            style: TextStyle(
              fontFamily: 'manrope',
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TutorOnboardingScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFF76B1C),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Completar mi perfil ahora',
                style: TextStyle(
                  fontFamily: 'outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
