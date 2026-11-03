import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/student/widgets/student_bottom_nav.dart';
import 'package:flutter_projects/view/components/reservation_card.dart';
import 'package:flutter_projects/view/components/role_based_navigation.dart';
import 'package:flutter_projects/view/student/reservations/widgets/reservations_calendar.dart';
import 'package:flutter_projects/view/student/reservations/widgets/new_reservation_modal.dart';
import 'package:flutter_projects/view/student/reservations/materials/tutoring_details_sheet.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({Key? key}) : super(key: key);

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reservations, style: TextStyle(fontFamily: 'outfit', fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ReservationsContent(),
        ),
      ),
      bottomNavigationBar: StudentBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 1) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => RoleBasedNavigation()),
            (route) => false,
          );
        },
        homeLabel: AppLocalizations.of(context)!.homeNavigation,
        scheduleLabel: AppLocalizations.of(context)!.scheduleNavigation,
        favoritesLabel: AppLocalizations.of(context)!.favorites_nav,
        profileLabel: AppLocalizations.of(context)!.profile_nav,
      ),
    );
  }
}

/// Widget reutilizable con el contenido de la pantalla de Reservas
class ReservationsContent extends StatefulWidget {
  final DateTime? initialDate;

  const ReservationsContent({Key? key, this.initialDate}) : super(key: key);

  @override
  State<ReservationsContent> createState() => _ReservationsContentState();
}

class _ReservationsContentState extends State<ReservationsContent> {
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _selectedEvents = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    // Booking loading moved into ReservationsCalendar widget
  }

  @override
  void didUpdateWidget(covariant ReservationsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != null &&
        (oldWidget.initialDate == null ||
            widget.initialDate!.difference(oldWidget.initialDate!) != Duration.zero)) {
      setState(() {
        _selectedDate = widget.initialDate!;
      });
    }
  }

  void _onNewReservation() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const NewReservationModal(),
      ),
    ).then((res) {
      if (res != null && mounted) {
        final inst = res['institution'];
        final subj = res['subject'];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${l10n.selected}: $inst - ${subj?['name'] ?? subj?['title'] ?? ''}')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _onNewReservation,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(Icons.add_circle_outline, color: Colors.white),
          label: Text(
            l10n.newReservation,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 16),

ReservationsCalendar(
  initialDate: _selectedDate,
  onDateChanged: (d) {
    setState(() => _selectedDate = d);
  },
  onSelectedEventsChanged: (events) {
    setState(() => _selectedEvents = events);
  },
  onLoadingChanged: (loading) {
    setState(() => _loading = loading);
  },
),

const SizedBox(height: 16),

_loading
    ? const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      )
    : Expanded(
        child: _selectedEvents.isEmpty
            ? Center(
                child: Text(
                  l10n.noReservationsForDate,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white54
                        : AppColors.greyColor,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: _selectedEvents.length + 1,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  // Texto al final de las reservas
                  if (index == _selectedEvents.length) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        top: 4,
                        bottom: 16,
                      ),
                      child: Text(
                        l10n.tapCardToSeeDetails,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 12,
                          color: AppColors.greyColor,
                        ),
                      ),
                    );
                  }

                  final ev = _selectedEvents[index];
                  return _buildCard(ev, l10n);
                },
              ),
              ),
      ],
    );
  }

  Widget _buildCard(dynamic ev, AppLocalizations l10n) {
    final map =
        ev is Map ? Map<String, dynamic>.from(ev) : const <String, dynamic>{};

    final timeRaw = map['start_time']?.toString() ??
        map['start_date']?.toString() ??
        map['date']?.toString() ??
        '';
    final endRaw =
        map['end_time']?.toString() ?? map['end_date']?.toString() ?? '';
    final subjectName = (map['subject_name']?.toString() ??
            map['subject']?.toString() ??
            l10n.reservation)
        .toString();
    final tutorName =
        (map['tutor_name']?.toString() ?? map['tutor']?.toString() ?? 'Tutor')
            .toString();
    final status = (map['status']?.toString() ?? '').toString();
    final attachmentCount = map['attachments_count'] is num
        ? (map['attachments_count'] as num).toInt()
        : int.tryParse(map['attachments_count']?.toString() ?? '') ?? 0;
    final meetingLink =
        (map['meeting_link']?.toString() ?? map['meet_link']?.toString() ?? '')
            .toString();

    String startTime = '';
    String endTime = '';
    try {
      final start = DateTime.parse(timeRaw);
      startTime = DateFormat('HH:mm').format(start);
    } catch (_) {
      startTime = timeRaw;
    }
    try {
      final end = DateTime.parse(endRaw);
      endTime = DateFormat('HH:mm').format(end);
    } catch (_) {
      endTime = endRaw;
    }

    return ReservationCard(
      startTime: startTime,
      endTime: endTime,
      status: status,
      subjectName: subjectName,
      personName: tutorName,
      personLabel: l10n.tutorLabel,
      attachmentCount: attachmentCount,
      meetingLink: meetingLink,
      onTap: () => _openTutoringDetails(ev),
    );
  }

  void _openTutoringDetails(dynamic ev) {
    final l10n = AppLocalizations.of(context)!;
    final map =
        ev is Map ? Map<String, dynamic>.from(ev) : const <String, dynamic>{};
    int bookingId = 0;
    if (map['id'] is int) {
      bookingId = map['id'] as int;
    } else {
      bookingId = int.tryParse(map['id']?.toString() ?? '') ?? 0;
    }
    if (bookingId == 0) return;

    final title = (map['subject_name']?.toString() ??
            map['subject']?.toString() ??
            l10n.reservation)
        .toString();
    final subtitle = (map['tutor_name']?.toString() ??
            map['tutor']?.toString() ??
            l10n.reservation)
        .toString();

    DateTime? bookingDate;
    final timeRaw = map['start_time']?.toString() ??
        map['start_date']?.toString() ??
        map['date']?.toString() ??
        '';
    try {
      bookingDate = DateTime.parse(timeRaw);
    } catch (_) {
      bookingDate = null;
    }

    String startTime = '';
    String endTime = '';
    try {
      startTime = DateFormat('HH:mm').format(DateTime.parse(timeRaw));
    } catch (_) {
      startTime = timeRaw;
    }
    try {
      endTime = DateFormat('HH:mm').format(DateTime.parse(
          map['end_time']?.toString() ?? map['end_date']?.toString() ?? ''));
    } catch (_) {
      endTime = map['end_time']?.toString() ?? '';
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TutoringDetailsSheet(
        bookingId: bookingId,
        title: title,
        subtitle: subtitle,
        canUpload: true,
        canEdit: true,
        date: bookingDate,
        startTime: startTime,
        endTime: endTime,
        status: map['status']?.toString(),
        meetingLink: map['meeting_link']?.toString() ??
            map['meet_link']?.toString() ??
            '',
      ),
    );
  }
}
