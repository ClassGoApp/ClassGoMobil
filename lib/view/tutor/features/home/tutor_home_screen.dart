import 'package:flutter/material.dart';
import 'package:flutter_projects/view/tutor/features/home/providers/tutor_home_provider.dart';
import 'package:flutter_projects/view/tutor/features/home/widgets/tutor_home_header.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';

// PROVIDERS (Los Cerebros)
import 'package:flutter_projects/provider/auth_provider.dart';

// WIDGETS
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
    // El Cerebro Local (TutorHomeProvider) descarga las citas y disponibilidad
    // Esto SÓLO ocurre cuando entras a la pestaña de Inicio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TutorHomeProvider>(context, listen: false)
          .loadHomeData(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos al Cerebro Global (Auth) y al Cerebro Local (Home)
    final authProvider = Provider.of<AuthProvider>(context);
    final homeProvider = Provider.of<TutorHomeProvider>(context);

    // 1. Extraemos tu nombre del AuthProvider global
    final user = authProvider.userData?['user'];
    final String userName = user != null ? (user['name'] ?? 'Tutor') : 'Tutor';

    // 2. Extraemos la foto de perfil del AuthProvider global
    String? imageUrl =
        user?['profile']?['image'] ?? user?['profile']?['profile_image'];

    // Limpiamos la URL por si la API la manda duplicada
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
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
          const SizedBox(height: 55),
          QuickAccessSection(onNavigate: widget.onNavigate),
          const SizedBox(height: 10),
          if (homeProvider.isLoading)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.brandBlue)),
            )
          else
            NextAppointmentSection(
                appointments: homeProvider.nextBooking!.map((booking) {
              final start = DateTime.tryParse(booking['start_time'] ?? '') ??
                  DateTime.now();
              final end = DateTime.tryParse(booking['end_time'] ?? '') ??
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
            }).toList()),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
