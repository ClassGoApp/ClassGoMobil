import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import '../services/reservations_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ReservationsDayModal extends StatefulWidget {
  final DateTime date;
  final List<ReservationItem> events;
  final Future<List<ReservationItem>>? futureEvents;

  const ReservationsDayModal(
      {Key? key, required this.date, required this.events, this.futureEvents})
      : super(key: key);

  @override
  State<ReservationsDayModal> createState() => _ReservationsDayModalState();
}

class _ReservationsDayModalState extends State<ReservationsDayModal> {
  late List<ReservationItem> _events;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _events = widget.events;
    if (widget.futureEvents != null) {
      _loading = true;
      widget.futureEvents!.then((res) {
        if (!mounted) return;
        setState(() {
          _events = res;
          _loading = false;
        });
      }).catchError((_) {
        if (!mounted) return;
        setState(() {
          _loading = false;
        });
      });
    }
  }

  String _timeKeyFromItem(ReservationItem item) {
    final dt = item.start;
    if (dt == null) return 'Sin hora';
    return DateFormat('HH:mm').format(dt);
  }

  void _showBookingDetails(BuildContext context, ReservationItem booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detalle de la reserva'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('ID', booking.id.toString()),
              _detailRow('Tutor', booking.tutorName),
              _detailRow('Materia', booking.subjectName),
              _detailRow(
                  'Inicio',
                  booking.start != null
                      ? DateFormat('HH:mm').format(booking.start!)
                      : '-'),
              _detailRow(
                  'Fin',
                  booking.end != null
                      ? DateFormat('HH:mm').format(booking.end!)
                      : '-'),
              _detailRow('Estado', booking.status),
              _detailRowLink(ctx, 'Meet', booking.meetingLink),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _detailRowLink(BuildContext context, String key, String link) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 3,
              child: Text('$key:',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: link.isNotEmpty
                ? GestureDetector(
                    onTap: () => _openMeetLink(context, link),
                    child: Text(link,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary)),
                  )
                : Text('-', style: TextStyle(color: AppColors.greyColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _openMeetLink(BuildContext context, String link) async {
    var url = link.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      await launchUrl(uri);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace')));
    }
  }

  Widget _detailRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 3,
              child: Text('$key:',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          Expanded(
              flex: 5,
              child: Text(value, style: TextStyle(color: AppColors.greyColor))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.date;
    final events = _events;

    if (_loading) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(DateFormat('EEEE, d MMMM yyyy', 'es').format(date),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              Text('Cargando reservas...',
                  style: TextStyle(color: AppColors.greyColor)),
            ],
          ),
        ),
      );
    }

    final grouped = <String, List<ReservationItem>>{};
    for (var e in events) {
      final key = _timeKeyFromItem(e);
      grouped.putIfAbsent(key, () => []).add(e);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == 'Sin hora') return 1;
        if (b == 'Sin hora') return -1;
        try {
          final da = DateFormat('HH:mm').parse(a);
          final db = DateFormat('HH:mm').parse(b);
          return da.compareTo(db);
        } catch (_) {
          return a.compareTo(b);
        }
      });

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('EEEE, d MMMM yyyy', 'es').format(date),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${events.length} reserva(s)',
                        style: TextStyle(color: AppColors.greyColor)),
                  ],
                ),
                IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close))
              ],
            ),
            const SizedBox(height: 8),
            if (events.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('No hay reservas para este día',
                    style: TextStyle(color: AppColors.greyColor)),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sortedKeys.length,
                  itemBuilder: (ctx, idx) {
                    final key = sortedKeys[idx];
                    final list = grouped[key]!;
                    // Si sólo hay una reserva en esa hora, mostrar detalle al tocar la hora
                    if (list.length == 1) {
                      final b = list.first;
                      return ListTile(
                        title: Row(
                          children: [
                            Expanded(
                                child: Text(key,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold))),
                            const SizedBox(width: 8),
                          ],
                        ),
                        subtitle: Text(b.subjectName),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showBookingDetails(context, b),
                      );
                    }

                    return ExpansionTile(
                      title: Row(
                        children: [
                          Text(key,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color:
                                    AppColors.orangeprimary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12)),
                            child: Text('${list.length}',
                                style:
                                    TextStyle(color: AppColors.orangeprimary)),
                          )
                        ],
                      ),
                      children: list.map<Widget>((b) {
                        return ListTile(
                          title: Text(b.subjectName.isNotEmpty
                              ? b.subjectName
                              : 'Reserva'),
                          subtitle: Text(b.tutorName),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _showBookingDetails(context, b),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
