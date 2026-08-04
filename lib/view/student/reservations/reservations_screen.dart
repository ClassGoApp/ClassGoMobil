import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/student/widgets/student_bottom_nav.dart';
import 'package:flutter_projects/view/components/role_based_navigation.dart';
import 'package:flutter_projects/view/student/reservations/widgets/reservations_calendar.dart';
import 'package:flutter_projects/view/student/reservations/widgets/new_reservation_modal.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({Key? key}) : super(key: key);

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  DateTime _selectedDate = DateTime.now();

  void _onNewReservation() {
    final l10n = AppLocalizations.of(context)!;
    // Placeholder: abrir flujo de nueva reserva
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              '${l10n.createNewReservation} ${_selectedDate.toLocal().toString().split(' ')[0]}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header azul marino
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: statusBarHeight + 15,
                left: 20,
                right: 20,
                bottom: 25,
              ),
              decoration: BoxDecoration(
                color: AppColors.headerLight,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.headerLight.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.reservations,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'outfit',
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => RoleBasedNavigation()),
                        (route) => false,
                      );
                    },
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ReservationsContent(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: StudentBottomNav(
        currentIndex: 1,
        onTap: (index) {
          // Si ya estamos en 'AGENDA' no hacemos nada
          if (index == 1) return;
          // Para otras opciones, volver al flujo principal (RoleBasedNavigation)
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

  // La lógica de carga y marcado de eventos ahora vive en
  // `ReservationsCalendar` (lib/view/student/widgets/reservations_calendar.dart)

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
        const SizedBox(height: 12),
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
        const SizedBox(height: 8),
        _loading
            ? Center(
                child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator()))
            : Expanded(
                child: _selectedEvents.isEmpty
                    ? Center(
                        child: Text(l10n.noReservationsForDate,
                            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : AppColors.greyColor)))
                    : ListView.separated(
                        itemCount: _selectedEvents.length,
                        separatorBuilder: (_, __) => Divider(),
                        itemBuilder: (context, index) {
                          final ev = _selectedEvents[index];
                          final title = ev is Map
                              ? (ev['title'] ?? ev['subject'] ?? l10n.reservation)
                              : ev.toString();
                          final time = ev is Map
                              ? (ev['time'] ??
                                  ev['start_time'] ??
                                  ev['start_date'] ??
                                  '')
                              : '';
                          return ListTile(
                            title: Text(title.toString()),
                            subtitle: Text(time.toString()),
                          );
                        },
                      ),
              ),
      ],
    );
  }
}
