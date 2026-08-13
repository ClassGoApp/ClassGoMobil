import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'reservations_day_modal.dart';
import '../services/reservations_service.dart';

typedef EventsCallback = void Function(List<dynamic> events);
typedef DateCallback = void Function(DateTime date);
typedef LoadingCallback = void Function(bool loading);

class ReservationsCalendar extends StatefulWidget {
  final DateTime? initialDate;
  final EventsCallback? onSelectedEventsChanged;
  final DateCallback? onDateChanged;
  final LoadingCallback? onLoadingChanged;

  const ReservationsCalendar({
    Key? key,
    this.initialDate,
    this.onSelectedEventsChanged,
    this.onDateChanged,
    this.onLoadingChanged,
  }) : super(key: key);

  @override
  State<ReservationsCalendar> createState() => _ReservationsCalendarState();
}

class _ReservationsCalendarState extends State<ReservationsCalendar> {
  late DateTime _selectedDate;
  late DateTime _focusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<dynamic>> _events = {};
  List<dynamic> _selectedEvents = [];
  bool _loading = false;

  DateTime _withoutTime(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate ?? DateTime.now();
    _selectedDate = widget.initialDate ?? DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookingsForMonth(_focusedDay);
      _updateSelectedEvents();
    });
  }

  @override
  void didUpdateWidget(covariant ReservationsCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != null &&
        (oldWidget.initialDate == null ||
            widget.initialDate!.difference(oldWidget.initialDate!) !=
                const Duration())) {
      setState(() {
        _selectedDate = widget.initialDate!;
        _focusedDay = widget.initialDate!;
      });
      // Diferir los callbacks que disparan setState del padre: ejecutarlos
      // aquí (durante el update/rebuild) provoca el crash '!_dirty'.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _updateSelectedEvents();
        _loadBookingsForMonth(_focusedDay);
      });
    }
  }

  Future<void> _loadBookingsForMonth(DateTime visibleMonth) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    if (!mounted) return;
    setState(() => _loading = true);
    if (mounted) widget.onLoadingChanged?.call(true);

    final first = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final last = DateTime(visibleMonth.year, visibleMonth.month + 1, 0);
    final startStr =
        '${first.year.toString().padLeft(4, '0')}-${first.month.toString().padLeft(2, '0')}-${first.day.toString().padLeft(2, '0')}';
    final endStr =
        '${last.year.toString().padLeft(4, '0')}-${last.month.toString().padLeft(2, '0')}-${last.day.toString().padLeft(2, '0')}';

    try {
      List<dynamic> items = [];
      final int? userId = auth.userId;
      if (userId != null) {
        final resp = await getUserBookingsById(token, userId);
        items = resp;
        items = items.where((b) {
          try {
            String? dateStr;
            if (b is Map) {
              dateStr = b['date']?.toString() ??
                  b['start_date']?.toString() ??
                  b['start_time']?.toString() ??
                  b['booking_date']?.toString();
            }
            if (dateStr == null) return false;
            final dt = DateTime.parse(dateStr);
            return !dt.isBefore(first) && !dt.isAfter(last);
          } catch (e) {
            return false;
          }
        }).toList();
      } else {
        final resp = await getBookings(token, startStr, endStr);
        if (resp is Map && resp.containsKey('data')) {
          items = resp['data'];
        } else if (resp is List) {
          items = resp as List<dynamic>;
        } else if (resp is Map) {
          if (resp.containsKey('bookings')) items = resp['bookings'];
        }
      }

      final Map<DateTime, List<dynamic>> events = {};
      for (var b in items) {
        try {
          String? dateStr;
          if (b is Map) {
            dateStr = b['date']?.toString() ??
                b['start_date']?.toString() ??
                b['start_time']?.toString() ??
                b['booking_date']?.toString();
          }
          if (dateStr == null) continue;
          DateTime dt = DateTime.parse(dateStr);
          final key = _withoutTime(dt);
          events.putIfAbsent(key, () => []).add(b);
        } catch (e) {
          // ignore
        }
      }

      if (!mounted) return;
      setState(() {
        _events = events;
        _loading = false;
        _updateSelectedEvents();
      });
      if (mounted) widget.onLoadingChanged?.call(false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (mounted) widget.onLoadingChanged?.call(false);
    }
  }

  void _updateSelectedEvents() {
    final key = _withoutTime(_selectedDate);
    if (!mounted) return;
    setState(() {
      _selectedEvents = _events[key] ?? [];
    });
    if (mounted) widget.onSelectedEventsChanged?.call(_selectedEvents);
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[_withoutTime(day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    // Obtener el locale actual de la app
    final currentLocale = Localizations.localeOf(context);
    final localeString = currentLocale.languageCode == 'en' ? 'en_US' : 'es_ES';

    final monthLabel =
        "${toBeginningOfSentenceCase(DateFormat('MMMM', localeString).format(_focusedDay))} ${DateFormat('yyyy').format(_focusedDay)}";

    return Card(
      color: Theme.of(context).cardTheme.color,
      shadowColor: Colors.black.withOpacity(0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isDark ? const BorderSide(color: Colors.white10) : BorderSide.none,
      ),
      elevation: isDark ? 0 : 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título y controles de mes
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _focusedDay =
                      DateTime(_focusedDay.year, _focusedDay.month - 1, 1)),
                  child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.08),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.chevron_left_rounded, size: 18)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(monthLabel,
                          style: TextStyle(
                              color:
                                  isDark ? Colors.white : AppColors.blackColor,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(l10n.calendar,
                          style: TextStyle(
                              color: AppColors.greyColor,
                              fontSize: 11,
                              letterSpacing: 1.2)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _focusedDay =
                      DateTime(_focusedDay.year, _focusedDay.month + 1, 1)),
                  child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.08),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.chevron_right_rounded, size: 18)),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                    onTap: () => setState(() {
                          _focusedDay = DateTime.now();
                          _selectedDate = DateTime.now();
                        }),
                    child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.08),
                            shape: BoxShape.circle),
                        child: Icon(Icons.calendar_today_outlined,
                            color:
                                isDark ? Colors.white70 : AppColors.blackColor,
                            size: 16))),
              ],
            ),
            const SizedBox(height: 8),
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              onFormatChanged: (f) => setState(() => _calendarFormat = f),
              selectedDayPredicate: (day) =>
                  _withoutTime(day) == _withoutTime(_selectedDate),
              eventLoader: _getEventsForDay,
              onDaySelected: (selectedDay, focusedDay) async {
                setState(() {
                  _selectedDate = selectedDay;
                  _focusedDay = focusedDay;
                });
                widget.onDateChanged?.call(selectedDay);
                _updateSelectedEvents();

                // Si el día tiene reservas, abrir el modal inmediatamente
                // y pasarle una Future que resolverá las reservas enriquecidas.
                final dayEventsRaw = _getEventsForDay(selectedDay);
                if (dayEventsRaw.isNotEmpty) {
                  final auth =
                      Provider.of<AuthProvider>(context, listen: false);
                  final token = auth.token;
                  final int? userId = auth.userId;

                  // Future que intenta obtener reservas ricas desde el servicio;
                  // si falla o no devuelve nada, hace fallback mapeando los datos crudos.
                  final fetchFuture = () async {
                    List<ReservationItem> dayReservations = [];
                    if (token != null && userId != null) {
                      try {
                        final all =
                            await ReservationsService.fetchUserReservations(
                                token, userId);
                        dayReservations = all.where((r) {
                          if (r.start == null) return false;
                          return _withoutTime(r.start!) ==
                              _withoutTime(selectedDay);
                        }).toList();
                      } catch (_) {
                        dayReservations = [];
                      }
                    }

                    // Fallback: mapear desde datos crudos si el servicio no devolvió nada
                    if (dayReservations.isEmpty) {
                      for (var b in dayEventsRaw) {
                        try {
                          int id = 0;
                          if (b is Map && b['id'] != null) {
                            if (b['id'] is int)
                              id = b['id'];
                            else
                              id = int.tryParse(b['id'].toString()) ?? 0;
                          }
                          DateTime? parseDate(dynamic v) {
                            if (v == null) return null;
                            try {
                              return DateTime.parse(v.toString());
                            } catch (_) {
                              return null;
                            }
                          }

                          final start = parseDate(b is Map
                              ? (b['start_time'] ??
                                  b['start_date'] ??
                                  b['start'] ??
                                  b['date'])
                              : null);
                          final end = parseDate(b is Map
                              ? (b['end_time'] ?? b['end_date'] ?? b['end'])
                              : null);
                          final tutorName = b is Map
                              ? (b['tutor_name']?.toString() ??
                                  b['tutor']?.toString() ??
                                  '')
                              : '';
                          final subjectName = b is Map
                              ? (b['subject_name']?.toString() ??
                                  b['subject']?.toString() ??
                                  '')
                              : '';
                          final status =
                              b is Map ? (b['status']?.toString() ?? '') : '';
                          final meeting = b is Map
                              ? (b['meeting_link']?.toString() ??
                                  b['meet_link']?.toString() ??
                                  '')
                              : '';
                          dayReservations.add(ReservationItem(
                              id: id,
                              tutorName: tutorName,
                              subjectName: subjectName,
                              start: start,
                              end: end,
                              status: status,
                              meetingLink: meeting));
                        } catch (_) {}
                      }
                    }

                    return dayReservations;
                  }();

                  // Abrir modal de inmediato; el modal mostrará spinner hasta que la Future complete
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (ctx) => Padding(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(ctx).viewInsets.bottom),
                      child: ReservationsDayModal(
                          date: selectedDay,
                          events: [],
                          futureEvents: fetchFuture),
                    ),
                  );
                }
              },
              onPageChanged: (focusedDay) {
                setState(() => _focusedDay = focusedDay);
                _loadBookingsForMonth(focusedDay);
              },
              startingDayOfWeek: StartingDayOfWeek.monday,
              locale: currentLocale.languageCode == 'en' ? 'en_US' : 'es_ES',
              rowHeight: 46,
              headerVisible: false,
              daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 10),
                  weekendStyle: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 10)),
              calendarBuilders: CalendarBuilders(
                selectedBuilder: (context, day, focusedDay) => _DayDotBuilder(
                    day: day,
                    color: Theme.of(context).colorScheme.primary,
                    hasSchedule: _events.containsKey(_withoutTime(day))),
                todayBuilder: (context, day, focusedDay) => _DayDotBuilder(
                    day: day,
                    color: Theme.of(context).colorScheme.secondary,
                    hasSchedule: _events.containsKey(_withoutTime(day))),
                defaultBuilder: (context, day, focusedDay) {
                  if (_events.containsKey(_withoutTime(day))) {
                    return _DayDotBuilder(
                        day: day,
                        color: AppColors.orangeprimary,
                        hasSchedule: true);
                  }
                  return null;
                },
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return const SizedBox.shrink();
                  return Positioned(
                    bottom: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.orangeprimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.selectedDate(
                  _selectedDate.toLocal().toString().split(' ')[0]),
              style: TextStyle(
                  color: isDark ? Colors.white54 : AppColors.greyColor,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayDotBuilder extends StatelessWidget {
  final DateTime day;
  final Color color;
  final bool hasSchedule;
  const _DayDotBuilder(
      {required this.day, required this.color, required this.hasSchedule});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: color.withOpacity(0.12))),
          Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('${day.day}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'outfit',
                      fontSize: 14,
                      height: 1.0))),
          if (hasSchedule)
            Positioned(
                bottom: 3,
                child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        color: AppColors.orangeprimary,
                        shape: BoxShape.circle))),
        ],
      ),
    );
  }
}
