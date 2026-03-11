import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/view/tutor/instant_tutoring_screen.dart';
import 'package:flutter_projects/view/student/reservations/services/reservations_service.dart';

class BookingModal extends StatefulWidget {
  final String tutorName;
  final String tutorImage;
  final List<String> subjects;
  final int tutorId;
  final int subjectId;
  final String? tagline;

  const BookingModal({
    required this.tutorName,
    required this.tutorImage,
    required this.subjects,
    required this.tutorId,
    required this.subjectId,
    this.tagline = '',
  });

  @override
  State<BookingModal> createState() => BookingModalState();
}

class BookingModalState extends State<BookingModal> {
  String? selectedSubject;
  DateTime? selectedDay;
  String? selectedHour;

  Map<int, List<String>> availableDays = {};
  bool isLoading = true;
  String? errorMessage;

  DateTime currentMonth = DateTime.now();
  DateTime _focusedDayBooking = DateTime.now();
  ScrollController? _sheetScrollController;

  final GlobalKey _materiaKey = GlobalKey();
  final GlobalKey _calendarKey = GlobalKey();
  final GlobalKey _hourKey = GlobalKey();
  bool _highlightMateria = false;
  bool _highlightCalendar = false;
  bool _highlightHour = false;

  OverlayEntry? _floatingMessage;
  Timer? _floatingMessageTimer;

  @override
  void initState() {
    super.initState();
    if (widget.subjects.isNotEmpty) {
      selectedSubject = widget.subjects.first;
    }
    _loadTutorAvailableSlots();
  }

  String _displaySubjectName(dynamic subject) {
    try {
      String name;
      if (subject is String) {
        name = subject;
      } else if (subject is Map && subject.containsKey('name')) {
        name = subject['name']?.toString() ?? '';
      } else {
        name = subject.toString();
      }
      final idx = name.indexOf('-');
      if (idx >= 0 && idx < name.length - 1) {
        return name.substring(idx + 1).trim();
      }
      return name;
    } catch (_) {
      return subject.toString();
    }
  }

  int? _extractSubjectId(dynamic subject) {
    try {
      if (subject == null) return null;
      if (subject is Map) {
        // buscar claves comunes de id
        final keys = [
          'id',
          'subject_id',
          'id_subget',
          'id_subjet',
          'subget_id'
        ];
        for (final k in keys) {
          if (subject.containsKey(k) && subject[k] != null) {
            final val = subject[k].toString();
            final n = int.tryParse(val);
            if (n != null) return n;
          }
        }
        // Try name field if present
        if (subject.containsKey('name') && subject['name'] != null) {
          final maybe = subject['name'].toString();
          final lead = RegExp(r'^\s*(\d+)').firstMatch(maybe);
          if (lead != null) return int.tryParse(lead.group(1)!);
          final any = RegExp(r'(\d+)').firstMatch(maybe);
          if (any != null) return int.tryParse(any.group(1)!);
        }
      }
      final s = subject.toString();
      final leading = RegExp(r'^\s*(\d+)\s*[-–—:]?').firstMatch(s);
      if (leading != null) return int.tryParse(leading.group(1)!);
      final cleaned = s.replaceAll(RegExp(r'(?i)subget'), '');
      final match = RegExp(r'(\d+)').firstMatch(cleaned);
      if (match != null) return int.tryParse(match.group(0)!);
      return null;
    } catch (_) {
      return null;
    }
  }

  bool _hasSchedule(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return availableDays.containsKey(normalized.millisecondsSinceEpoch) &&
        (availableDays[normalized.millisecondsSinceEpoch]?.isNotEmpty ?? false);
  }

  @override
  void dispose() {
    try {
      _floatingMessageTimer?.cancel();
    } catch (_) {}
    try {
      _floatingMessage?.remove();
    } catch (_) {}
    _floatingMessage = null;
    _sheetScrollController = null;
    super.dispose();
  }

  Future<void> _loadTutorAvailableSlots() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) {
        if (mounted) {
          setState(() {
            errorMessage = 'No se pudo autenticar';
            isLoading = false;
          });
        }
        return;
      }

      final parsed = await ReservationsService.loadTutorAvailableSlots(
          token, widget.tutorId.toString());

      if (mounted) {
        setState(() {
          availableDays = parsed;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error al cargar los horarios disponibles: $e';
          isLoading = false;
        });
      }
    }
  }

  void _showFloatingMessage(String text, GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    _floatingMessage?.remove();
    _floatingMessage = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx + 10,
        top: offset.dy - 36,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Text(text,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_floatingMessage!);
    Future.delayed(Duration(milliseconds: 1200), () {
      _floatingMessage?.remove();
      _floatingMessage = null;
    });
  }

  void _scrollAndHighlight(
      GlobalKey key, String section, String message) async {
    final ctx = key.currentContext;
    if (ctx != null && _sheetScrollController != null) {
      final box = ctx.findRenderObject() as RenderBox;
      final offset =
          box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
      final scrollOffset = _sheetScrollController!.offset + offset.dy - 120;
      _sheetScrollController!.animateTo(scrollOffset,
          duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
      setState(() {
        if (section == 'materia') _highlightMateria = true;
        if (section == 'calendar') _highlightCalendar = true;
        if (section == 'hour') _highlightHour = true;
      });
      _showFloatingMessage(message, key);
      await Future.delayed(Duration(milliseconds: 900));
      setState(() {
        _highlightMateria = false;
        _highlightCalendar = false;
        _highlightHour = false;
      });
    }
  }

  List<String> _generateTimeSlots(String range,
      {DateTime? nowBolivia, bool isToday = false}) {
    print(
        'DEBUG _generateTimeSlots called with range: "$range", isToday: $isToday');
    final parts = range.split('-');
    if (parts.length != 2) {
      print('DEBUG _generateTimeSlots: parts.length != 2 (${parts.length})');
      return [];
    }
    final start = _parseTime(parts[0]);
    final end = _parseTime(parts[1]);
    if (start == null || end == null) {
      print('DEBUG _generateTimeSlots: start or end is null');
      return [];
    }
    List<String> slots = [];
    DateTime slot = start;
    int iterations = 0;
    while (slot.isBefore(end.subtract(Duration(minutes: 20))) ||
        slot.isAtSameMomentAs(end.subtract(Duration(minutes: 20)))) {
      slots.add(_formatTime(slot));
      slot = slot.add(Duration(minutes: 20));
      iterations++;
      if (iterations > 100) {
        print('DEBUG _generateTimeSlots: too many iterations, breaking');
        break;
      }
    }
    if (isToday && nowBolivia != null) {
      final ref = DateTime(1, 1, 1, nowBolivia.hour, nowBolivia.minute);
      slots = slots.where((h) {
        final parsed = _parseTime(h);
        if (parsed == null) return false;
        return parsed.isAtSameMomentAs(ref) || parsed.isAfter(ref);
      }).toList();
    }
    return slots;
  }

  DateTime? _parseTime(String hhmm) {
    final cleaned = hhmm.trim();
    final parts = cleaned.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0].trim());
    final min = int.tryParse(parts[1].trim());
    if (hour == null || min == null) return null;
    return DateTime(1, 1, 1, hour, min);
  }

  String _formatTime(DateTime t) {
    return t.hour.toString().padLeft(2, '0') +
        ':' +
        t.minute.toString().padLeft(2, '0');
  }

  bool _isTimeInRange(String range, String time) {
    final parts = range.split('-');
    if (parts.length != 2) return false;
    final start = _parseTime(parts[0]);
    final end = _parseTime(parts[1]);
    final t = _parseTime(time);
    if (start == null || end == null || t == null) return false;
    return (t.isAtSameMomentAs(start) || t.isAfter(start)) &&
        t.isBefore(end.subtract(Duration(minutes: 20)));
  }

  Future<void> _pickTime(String range) async {
    final now = TimeOfDay.now();
    final parts = range.split('-');
    final start = _parseTime(parts[0]);
    final initial =
        start != null ? TimeOfDay(hour: start.hour, minute: start.minute) : now;
    final picked = await showTimePicker(
        context: context,
        initialTime: initial,
        builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
                dialogBackgroundColor: AppColors.darkBlue,
                colorScheme: ColorScheme.dark(
                    primary: AppColors.lightBlueColor,
                    onPrimary: Colors.white,
                    surface: AppColors.darkBlue,
                    onSurface: Colors.white)),
            child: child!));
    if (picked != null) {
      final pickedStr = picked.hour.toString().padLeft(2, '0') +
          ':' +
          picked.minute.toString().padLeft(2, '0');
      if (_isTimeInRange(range, pickedStr)) {
        final pickedDateTime = DateTime(1, 1, 1, picked.hour, picked.minute);
        final endDateTime = pickedDateTime.add(Duration(minutes: 20));
        final endTimeStr =
            '${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';
        final fullRange = '$pickedStr-$endTimeStr';
        setState(() => selectedHour = fullRange);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hora fuera del rango permitido.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateUtils.getDaysInMonth(currentMonth.year, currentMonth.month);
    final firstWeekday =
        DateTime(currentMonth.year, currentMonth.month, 1).weekday;
    final weekDays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        _sheetScrollController = scrollController;
        return Container(
          decoration: BoxDecoration(
              color: AppColors.darkBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Stack(children: [
            CustomScrollView(controller: scrollController, slivers: [
              SliverPersistentHeader(
                  pinned: true,
                  delegate: _BookingHeaderDelegate(child: _buildHeader())),
              SliverToBoxAdapter(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: _buildBody(daysInMonth, firstWeekday, weekDays)))
            ]),
            _buildBottomBar(),
          ]),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(left: 18, right: 8, top: 18, bottom: 12),
      decoration: BoxDecoration(
          color: AppColors.darkBlue,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Row(children: [
        CircleAvatar(
            backgroundImage: NetworkImage(widget.tutorImage), radius: 26),
        SizedBox(width: 14),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              Text(widget.tutorName,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17)),
              if (widget.tagline != null && widget.tagline!.isNotEmpty) ...[
                SizedBox(height: 4),
                Text(widget.tagline!,
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ]
            ])),
        IconButton(
            icon: Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.pop(context)),
      ]),
    );
  }

  Widget _buildBody(int daysInMonth, int firstWeekday, List<String> weekDays) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 6),
        Text('Materia',
            style:
                TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        SizedBox(height: 6),
        AnimatedContainer(
          key: _materiaKey,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            border: _highlightMateria
                ? Border.all(color: AppColors.lightBlueColor, width: 3)
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _highlightMateria
                ? [
                    BoxShadow(
                        color: AppColors.lightBlueColor.withOpacity(0.5),
                        blurRadius: 18,
                        spreadRadius: 2)
                  ]
                : [],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedSubject,
              dropdownColor: AppColors.darkBlue,
              borderRadius: BorderRadius.circular(12),
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              items: widget.subjects
                  .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(_displaySubjectName(s),
                          style: TextStyle(color: Colors.white))))
                  .toList(),
              onChanged: (v) {
                setState(() => selectedSubject = v);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_sheetScrollController != null &&
                      _sheetScrollController!.hasClients) {
                    _sheetScrollController!.animateTo(
                        _sheetScrollController!.position.maxScrollExtent,
                        duration: Duration(milliseconds: 400),
                        curve: Curves.easeOut);
                  }
                });
              },
            ),
          ),
        ),
        SizedBox(height: 18),
        Text('Selecciona un día',
            style:
                TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        SizedBox(height: 6),
        AnimatedContainer(
          key: _calendarKey,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            border: _highlightCalendar
                ? Border.all(color: AppColors.lightBlueColor, width: 3)
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _highlightCalendar
                ? [
                    BoxShadow(
                        color: AppColors.lightBlueColor.withOpacity(0.5),
                        blurRadius: 18,
                        spreadRadius: 2)
                  ]
                : [],
          ),
          child: Container(
            decoration: BoxDecoration(
                color: AppColors.lightBlueColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: Colors.white70),
                      onPressed: () {
                        setState(() {
                          currentMonth = DateTime(
                              currentMonth.year, currentMonth.month - 1);
                          selectedDay = null;
                          selectedHour = null;
                        });
                        _loadTutorAvailableSlots();
                      },
                    ),
                    Text(
                        '${_monthName(currentMonth.month)} ${currentMonth.year}',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.chevron_right, color: Colors.white70),
                      onPressed: () {
                        setState(() {
                          currentMonth = DateTime(
                              currentMonth.year, currentMonth.month + 1);
                          selectedDay = null;
                          selectedHour = null;
                        });
                        _loadTutorAvailableSlots();
                      },
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: weekDays
                        .map((d) => Expanded(
                            child: Center(
                                child: Text(d,
                                    style: TextStyle(
                                        color: Colors.white54,
                                        fontWeight: FontWeight.bold)))))
                        .toList()),
                SizedBox(height: 2),
                if (isLoading)
                  Container(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.lightBlueColor)),
                          SizedBox(height: 16),
                          Text('Cargando horarios disponibles...',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),
                  )
                else if (errorMessage != null)
                  Container(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red[300], size: 48),
                          SizedBox(height: 16),
                          Text(errorMessage!,
                              style: TextStyle(
                                  color: Colors.red[300], fontSize: 14),
                              textAlign: TextAlign.center),
                          SizedBox(height: 16),
                          ElevatedButton(
                              onPressed: _loadTutorAvailableSlots,
                              child: Text('Reintentar'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.lightBlueColor)),
                        ],
                      ),
                    ),
                  )
                else if (availableDays.isEmpty)
                  Container(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule, color: Colors.white54, size: 48),
                          SizedBox(height: 16),
                          Text('No hay horarios disponibles\npara este mes',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 14),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  )
                else
                  TableCalendar(
                    firstDay: DateTime.utc(currentMonth.year - 2, 1, 1),
                    lastDay: DateTime.utc(currentMonth.year + 2, 12, 31),
                    focusedDay: _focusedDayBooking,
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    headerVisible: false,
                    daysOfWeekHeight: 28,
                    rowHeight: 48,
                    availableGestures: AvailableGestures.horizontalSwipe,
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focused) {
                        final isAvailable = _hasSchedule(day);
                        final isSelected =
                            selectedDay != null && isSameDay(selectedDay, day);
                        if (isAvailable) {
                          return SizedBox(
                            width: 46,
                            height: 46,
                            child: Container(
                              margin: EdgeInsets.all(2),
                              padding: EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.lightBlueColor
                                    : AppColors.lightBlueColor
                                        .withOpacity(0.22),
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 2)
                                    : Border.all(
                                        color: AppColors.lightBlueColor
                                            .withOpacity(0.35),
                                        width: 1),
                              ),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('${day.day}',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 4),
                                    Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle)),
                                  ]),
                            ),
                          );
                        }
                        return null;
                      },
                      todayBuilder: (context, day, focused) {
                        return SizedBox(
                          width: 46,
                          height: 46,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppColors.lightBlueColor,
                                        width: 1)),
                                alignment: Alignment.center,
                                child: Text('${day.day}',
                                    style: TextStyle(
                                        color: AppColors.lightBlueColor,
                                        fontWeight: FontWeight.bold)),
                              ),
                              if (_hasSchedule(day))
                                Positioned(
                                    bottom: 6,
                                    child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                            color: AppColors.lightBlueColor,
                                            shape: BoxShape.circle))),
                            ],
                          ),
                        );
                      },
                    ),
                    selectedDayPredicate: (day) =>
                        selectedDay != null && isSameDay(selectedDay, day),
                    onDaySelected: (day, focused) {
                      if (!_hasSchedule(day)) return;
                      setState(() {
                        _focusedDayBooking = focused;
                        selectedDay = DateTime(day.year, day.month, day.day);
                        selectedHour = null;
                      });
                      // Mostrar en consola las ranges para la fecha seleccionada
                      try {
                        final key = DateTime(selectedDay!.year,
                                selectedDay!.month, selectedDay!.day)
                            .millisecondsSinceEpoch;
                        final rangesForDay = availableDays[key] ?? [];
                        print(
                            'DEBUG onDaySelected ranges for ${DateTime.fromMillisecondsSinceEpoch(key).toIso8601String()}: $rangesForDay');
                      } catch (_) {}

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_sheetScrollController != null &&
                            _sheetScrollController!.hasClients) {
                          _sheetScrollController!.animateTo(
                              _sheetScrollController!.position.maxScrollExtent,
                              duration: Duration(milliseconds: 400),
                              curve: Curves.easeOut);
                        }
                      });
                    },
                    onPageChanged: (focused) {
                      _focusedDayBooking = focused;
                    },
                  ),
                // Mostrar horas disponibles cuando se selecciona un día
                if (selectedDay != null) ...[
                  SizedBox(height: 12),
                  Padding(
                    key: _hourKey,
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Selecciona una hora',
                            style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Builder(builder: (ctx) {
                          final dateKey = DateTime(selectedDay!.year,
                              selectedDay!.month, selectedDay!.day);
                          final ranges =
                              availableDays[dateKey.millisecondsSinceEpoch] ??
                                  [];
                          if (ranges.isEmpty) {
                            return Container(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Text(
                                  'No hay horas disponibles para este día',
                                  style: TextStyle(color: Colors.white54)),
                            );
                          }

                          // Construir lista de horas (slots) a partir de los rangos
                          final nowBolivia = DateTime.now()
                              .toUtc()
                              .subtract(Duration(hours: 4));
                          final todayBolivia = DateTime(nowBolivia.year,
                              nowBolivia.month, nowBolivia.day);
                          final isToday = isSameDay(selectedDay, todayBolivia);

                          final List<Widget> slotButtons = [];
                          final bool isDarkTheme =
                              Theme.of(ctx).brightness == Brightness.dark;
                          final Color unselectedTextColor =
                              isDarkTheme ? Colors.white70 : Colors.black87;
                          final Color unselectedBgColor = isDarkTheme
                              ? Colors.white12
                              : AppColors.cardLight;
                          for (final range in ranges) {
                            // Debug: mostrar cada rango recibido para la fecha
                            try {
                              print(
                                  'DEBUG build slots for date ${dateKey.toIso8601String()} range="${range}"');
                            } catch (_) {}
                            final slots = _generateTimeSlots(range,
                                nowBolivia: nowBolivia, isToday: isToday);
                            for (final start in slots) {
                              final parsed = _parseTime(start);
                              if (parsed == null) continue;
                              final end = parsed.add(Duration(minutes: 20));
                              final endStr = _formatTime(end);
                              final fullRange = '$start-$endStr';
                              final isSelected = selectedHour == fullRange;
                              slotButtons.add(Padding(
                                padding: const EdgeInsets.only(
                                    right: 8.0, bottom: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedHour = fullRange;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.lightBlueColor
                                          : unselectedBgColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.dividerLight),
                                    ),
                                    child: Text(start,
                                        style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : unselectedTextColor,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ));
                            }
                          }

                          if (slotButtons.isEmpty) {
                            // Si no se generaron botones, mostrar información de depuración
                            return Container(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('No se generaron slots para este día',
                                      style: TextStyle(color: Colors.white54)),
                                  SizedBox(height: 8),
                                  Text('Ranges recibidos:',
                                      style: TextStyle(color: Colors.white70)),
                                  ...ranges
                                      .map((r) => Text('- $r',
                                          style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12)))
                                      .toList(),
                                ],
                              ),
                            );
                          }

                          print(
                              'DEBUG: About to render ${slotButtons.length} slot buttons');
                          return Container(
                            constraints: BoxConstraints(minHeight: 50),
                            padding: EdgeInsets.only(top: 10, bottom: 100),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: slotButtons,
                            ),
                          );
                        })
                      ],
                    ),
                  )
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: AppColors.darkBlue,
        padding: EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedDay != null && selectedHour != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event,
                        color: AppColors.lightBlueColor, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Reserva: ${selectedDay!.day.toString().padLeft(2, '0')}/${selectedDay!.month.toString().padLeft(2, '0')}/${selectedDay!.year} a las $selectedHour',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (selectedSubject != null &&
                        selectedDay != null &&
                        selectedHour != null)
                    ? () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => Container(
                            margin: EdgeInsets.only(top: 60),
                            decoration: BoxDecoration(
                                color: AppColors.darkBlue,
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24))),
                            child: InstantTutoringScreen(
                              tutorName: widget.tutorName,
                              tutorImage: widget.tutorImage,
                              subjects: widget.subjects,
                              selectedSubject: selectedSubject,
                              tutorId: widget.tutorId,
                              subjectId: _extractSubjectId(selectedSubject) ??
                                  widget.subjectId,
                              scheduledDate: selectedDay,
                              scheduledTime: selectedHour,
                              isScheduledBooking: true,
                            ),
                          ),
                        );
                      }
                    : () {
                        if (selectedSubject == null) {
                          _scrollAndHighlight(_materiaKey, 'materia',
                              'Debes seleccionar la materia');
                        } else if (selectedDay == null) {
                          _scrollAndHighlight(_calendarKey, 'calendar',
                              'Debes seleccionar el día');
                        } else if (selectedHour == null) {
                          _scrollAndHighlight(
                              _hourKey, 'hour', 'Debes seleccionar la hora');
                        }
                      },
                icon: Icon(
                  Icons.check_circle,
                  color: (selectedSubject != null &&
                          selectedDay != null &&
                          selectedHour != null)
                      ? Colors.white
                      : Colors.white54,
                ),
                label: Text(
                  'Confirmar Reserva',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: (selectedSubject != null &&
                            selectedDay != null &&
                            selectedHour != null)
                        ? Colors.white
                        : Colors.white54,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (selectedSubject != null &&
                          selectedDay != null &&
                          selectedHour != null)
                      ? AppColors.lightBlueColor
                      : AppColors.lightBlueColor.withOpacity(0.25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                        color: (selectedSubject != null &&
                                selectedDay != null &&
                                selectedHour != null)
                            ? Colors.transparent
                            : Colors.white24,
                        width: 1.2),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return months[m - 1];
  }
}

class _BookingHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _BookingHeaderDelegate({required this.child});

  @override
  double get minExtent => 80;
  @override
  double get maxExtent => 80;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
