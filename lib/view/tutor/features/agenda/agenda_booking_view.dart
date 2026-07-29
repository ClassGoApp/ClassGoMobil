import 'package:flutter/material.dart';
import 'package:flutter_projects/models/booking_status.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/view/tutor/features/agenda/providers/tutor_agenda_provider.dart';
import 'package:flutter_projects/view/tutor/features/home/widgets/reservation_details_dialog.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/student/reservations/services/reservations_service.dart';

class AgendaBookingView extends StatefulWidget {
  final DateTime selectedDate;

  const AgendaBookingView({Key? key, required this.selectedDate}) : super(key: key);

  @override
  State<AgendaBookingView> createState() => _AgendaBookingViewState();
}

class _AgendaBookingViewState extends State<AgendaBookingView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final agendaProvider = Provider.of<TutorAgendaProvider>(context, listen: false);

      final token = authProvider.token ?? '';
      final user = authProvider.userData?['user'];
      final String userIdStr = user != null ? (user['id']?.toString() ?? '') : '';
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
    final dailyClasses = agendaProvider.getReservationsForDay(widget.selectedDate);

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
        return _BookingSummaryCard(
          reservation: reservation,
          isDark: isDark,
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => ReservationDetailsDialog(data: reservation),
            );
          },
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
                color: isDark ? Colors.white.withOpacity(0.02) : AppColors.brandCyan.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.free_breakfast_rounded, 
                  size: 48, color: isDark ? Colors.white24 : AppColors.brandCyan.withOpacity(0.5)),
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

class _BookingSummaryCard extends StatelessWidget {
  final ReservationItem reservation;
  final bool isDark;
  final VoidCallback onTap;

  const _BookingSummaryCard({
    required this.reservation,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final startTime = reservation.start != null ? DateFormat('HH:mm').format(reservation.start!) : '--:--';
    final endTime = reservation.end != null ? DateFormat('HH:mm').format(reservation.end!) : '--:--';
    
    final isPending = BookingStatus.fromString(reservation.status).isPending;
    final accentColor = isPending ? AppColors.brandOrange : AppColors.brandCyan;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151A24) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentColor.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      startTime,
                      style: TextStyle(fontFamily: 'outfit', fontWeight: FontWeight.w900, color: accentColor, fontSize: 15),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      width: 2,
                      height: 10,
                      color: accentColor.withOpacity(0.3),
                    ),
                    Text(
                      endTime,
                      style: TextStyle(fontFamily: 'outfit', fontWeight: FontWeight.bold, color: accentColor.withOpacity(0.7), fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.subjectName,
                      style: TextStyle(
                        fontFamily: 'outfit',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: isDark ? Colors.white : AppColors.brandBlue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.person_rounded, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            reservation.studentName,
                            style: TextStyle(fontFamily: 'manrope', color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white54 : Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}