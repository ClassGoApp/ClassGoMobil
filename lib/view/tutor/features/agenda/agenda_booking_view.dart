import 'package:flutter/material.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/view/components/reservation_card.dart';
import 'package:flutter_projects/view/student/reservations/materials/tutoring_details_sheet.dart';
import 'package:flutter_projects/view/tutor/features/agenda/providers/tutor_agenda_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:flutter_projects/styles/app_styles.dart';

class AgendaBookingView extends StatefulWidget {
  final DateTime selectedDate;

  const AgendaBookingView({Key? key, required this.selectedDate})
      : super(key: key);

  @override
  State<AgendaBookingView> createState() => _AgendaBookingViewState();
}

class _AgendaBookingViewState extends State<AgendaBookingView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final agendaProvider =
          Provider.of<TutorAgendaProvider>(context, listen: false);

      final token = authProvider.token ?? '';
      final user = authProvider.userData?['user'];
      final String userIdStr =
          user != null ? (user['id']?.toString() ?? '') : '';
      final int userId = int.tryParse(userIdStr) ?? authProvider.userId ?? 0;
      if (token.isNotEmpty && userId > 0) {
        if (agendaProvider.reservations.isEmpty) {
          agendaProvider.loadReservations(token, userId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final agendaProvider = context.watch<TutorAgendaProvider>();
    final dailyClasses =
        agendaProvider.getReservationsForDay(widget.selectedDate);

    if (agendaProvider.isLoadingBookings) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brandCyan),
      );
    }

    if (dailyClasses.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
      physics: const BouncingScrollPhysics(),
      itemCount: dailyClasses.length,
      itemBuilder: (context, index) {
        final reservation = dailyClasses[index];
        final l10n = AppLocalizations.of(context)!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ReservationCard(
            startTime: reservation.start != null
                ? DateFormat('HH:mm').format(reservation.start!)
                : '--:--',
            endTime: reservation.end != null
                ? DateFormat('HH:mm').format(reservation.end!)
                : '--:--',
            status: reservation.status,
            subjectName: reservation.subjectName.isNotEmpty
                ? reservation.subjectName
                : l10n.reservation,
            personName: reservation.studentName,
            personLabel: l10n.studentLabel,
            attachmentCount: reservation.attachmentCount,
            meetingLink: reservation.meetingLink,
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useRootNavigator: true,
                backgroundColor: Colors.transparent,
                builder: (_) => TutoringDetailsSheet(
                  bookingId: reservation.id,
                  title: reservation.subjectName.isNotEmpty
                      ? reservation.subjectName
                      : l10n.reservation,
                  subtitle: reservation.studentName,
                  canUpload: false,
                  canEdit: false,
                  date: reservation.start,
                  startTime: reservation.start != null
                      ? DateFormat('HH:mm').format(reservation.start!)
                      : '',
                  endTime: reservation.end != null
                      ? DateFormat('HH:mm').format(reservation.end!)
                      : '',
                  status: reservation.status,
                  meetingLink: reservation.meetingLink,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 120),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.02)
                    : AppColors.brandCyan.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.free_breakfast_rounded,
                  size: 48,
                  color: isDark
                      ? Colors.white24
                      : AppColors.brandCyan.withOpacity(0.5)),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.freeDay,
              style: TextStyle(
                fontFamily: 'outfit',
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: isDark ? Colors.white : AppColors.brandBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.noClassesTodayMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'manrope',
                color: isDark ? Colors.white54 : Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
