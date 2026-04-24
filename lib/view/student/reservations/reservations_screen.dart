import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/student/widgets/student_bottom_nav.dart';
import 'package:flutter_projects/view/components/role_based_navigation.dart';
import 'package:flutter_projects/view/student/reservations/widgets/reservations_calendar.dart';
import 'package:flutter_projects/view/student/reservations/widgets/new_reservation_modal.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({Key? key}) : super(key: key);

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  DateTime _selectedDate = DateTime.now();

  void _onNewReservation() {
    // Placeholder: abrir flujo de nueva reserva
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Crear nueva reserva para ${_selectedDate.toLocal().toString().split(' ')[0]}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Reservaciones', style: TextStyle(fontFamily: 'outfit', fontWeight: FontWeight.bold)),
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
          // Si ya estamos en 'AGENDA' no hacemos nada
          if (index == 1) return;
          // Para otras opciones, volver al flujo principal (RoleBasedNavigation)
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => RoleBasedNavigation()),
            (route) => false,
          );
        },
      ),
    );
  }
}

/// Widget reutilizable con el contenido de la pantalla de Reservas
class ReservationsContent extends StatefulWidget {
  const ReservationsContent({Key? key}) : super(key: key);

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
    _selectedDate = DateTime.now();
    // Booking loading moved into ReservationsCalendar widget
  }

  void _onNewReservation() {
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
                'Seleccionado: $inst - ${subj?['name'] ?? subj?['title'] ?? ''}')));
      }
    });
  }

  // La lógica de carga y marcado de eventos ahora vive en
  // `ReservationsCalendar` (lib/view/student/widgets/reservations_calendar.dart)

  @override
  Widget build(BuildContext context) {
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
            'Nueva reserva',
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
                        child: Text('No hay reservas para esta fecha',
                            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : AppColors.greyColor)))
                    : ListView.separated(
                        itemCount: _selectedEvents.length,
                        separatorBuilder: (_, __) => Divider(),
                        itemBuilder: (context, index) {
                          final ev = _selectedEvents[index];
                          final title = ev is Map
                              ? (ev['title'] ?? ev['subject'] ?? 'Reserva')
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
