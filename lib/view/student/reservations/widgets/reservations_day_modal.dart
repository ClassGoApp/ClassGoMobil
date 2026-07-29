import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
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

  String _timeKeyFromItem(ReservationItem item, AppLocalizations l10n) {
    final dt = item.start;
    if (dt == null) return l10n.withoutTime;
    return DateFormat('HH:mm').format(dt);
  }

  void _showBookingDetails(BuildContext context, ReservationItem booking) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.reservationDetails),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(l10n.id, booking.id.toString()),
              _detailRow(l10n.tutor, booking.tutorName),
              _detailRow(l10n.subject, booking.subjectName),
              _detailRow(
                  l10n.start,
                  booking.start != null
                      ? DateFormat('HH:mm').format(booking.start!)
                      : '-'),
              _detailRow(
                  l10n.end,
                  booking.end != null
                      ? DateFormat('HH:mm').format(booking.end!)
                      : '-'),
              _detailRow(l10n.status, booking.status),
              _detailRowLink(ctx, l10n.meet, booking.meetingLink),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.close),
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
    final l10n = AppLocalizations.of(context)!;
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
          SnackBar(content: Text(l10n.couldNotOpenLink)));
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
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context);
    final localeString = currentLocale.languageCode == 'en' ? 'en_US' : 'es_ES';
    
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
              Text(DateFormat('EEEE, d MMMM yyyy', localeString).format(date),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              Text(l10n.loadingReservations,
                  style: TextStyle(color: AppColors.greyColor)),
            ],
          ),
        ),
      );
    }

    final grouped = <String, List<ReservationItem>>{};
    for (var e in events) {
      final key = _timeKeyFromItem(e, l10n);
      grouped.putIfAbsent(key, () => []).add(e);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == l10n.withoutTime) return 1;
        if (b == l10n.withoutTime) return -1;
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
                    Text(DateFormat('EEEE, d MMMM yyyy', localeString).format(date),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(l10n.reservationCount(events.length),
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
                child: Text(l10n.noReservationsForThisDay,
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
                              : l10n.reservation),
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
