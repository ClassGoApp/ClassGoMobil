import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/view/tutor/dashboard/sheets/add_schedule_sheet.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';

import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/tutor/features/agenda/providers/tutor_agenda_provider.dart';

import 'package:flutter_projects/view/tutor/features/agenda/tutor_agenda_screen.dart'
    show AgendaMode;

class AgendaCalendarModal extends StatefulWidget {
  final AgendaMode mode;
  final DateTime initialDate;

  /**final DateTime focusedDay;
  final DateTime viewedDay;
  final bool isMultiSelectMode;
  final bool isRangeMode;
  final Set<DateTime> selectedDays;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  // Callbacks para avisarle al padre qué pasó
  final Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final Function(DateTime selectedDay, DateTime focusedDay) onDayLongPressed;
  final Function(DateTime? start, DateTime? end, DateTime focusedDay)
      onRangeSelected;
  final Function(DateTime focusedDay) onPageChanged;
**/

  const AgendaCalendarModal({
    Key? key,
    required this.mode,
    required this.initialDate,

    /**required this.focusedDay,
    required this.viewedDay,
    this.isMultiSelectMode = false,
    this.isRangeMode = false,
    required this.selectedDays,
    this.rangeStart,
    this.rangeEnd,
    required this.onDaySelected,
    required this.onDayLongPressed,
    required this.onRangeSelected,
    required this.onPageChanged,**/
  }) : super(key: key);

  @override
  State<AgendaCalendarModal> createState() => _AgendaCalendarModalState();
}

class _AgendaCalendarModalState extends State<AgendaCalendarModal> {
  late DateTime _focusedDay;
  late DateTime _viewedDay;

  late DateTime _singleSelectedDay;

  CalendarFormat _calendarFormat = CalendarFormat.month;

  bool _isMultiSelectMode = false;
  Set<DateTime> _selectedDays = {};

  bool _isRangeMode = false;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate;
    _viewedDay = widget.initialDate;
    _singleSelectedDay = widget.initialDate;
    _selectedDays.add(widget.initialDate);

    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAgendaData());
  }

  Future<void> _fetchAgendaData({bool forceRefresh = false}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null && authProvider.userId != null) {
      await Provider.of<TutorAgendaProvider>(context, listen: false)
          .loadAvailableSlots(
              authProvider.token!, authProvider.userId!.toString(),
              year: _focusedDay.year,
              month: _focusedDay.month,
              forceRefresh: forceRefresh);
    }
  }

  void _clearSelection() {
    setState(() {
      _isMultiSelectMode = false;
      _isRangeMode = false;
      _selectedDays.clear();
      _rangeStart = null;
      _rangeEnd = null;
    });
  }

  List<DateTime> _getAllSelectedDays() {
    if (_isRangeMode) {
      if (_rangeStart == null) return [];
      if (_rangeEnd == null) return [_rangeStart!];
      DateTime start =
          _rangeStart!.isBefore(_rangeEnd!) ? _rangeStart! : _rangeEnd!;
      DateTime end =
          _rangeStart!.isBefore(_rangeEnd!) ? _rangeEnd! : _rangeStart!;
      final days = <DateTime>[];
      for (int i = 0; i <= end.difference(start).inDays; i++) {
        days.add(start.add(Duration(days: i)));
      }
      return days;
    } else if (_isMultiSelectMode) {
      return _selectedDays.toList();
    } else {
      return [_viewedDay];
    }
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<TutorAgendaProvider>(context);
    final theme = Theme.of(context);
    final bgColor = isDark ? AppColors.deepDarkBg : AppColors.softWhiteBg;

    final authProvider = Provider.of<AuthProvider>(context);
    final agendaProvider = Provider.of<TutorAgendaProvider>(context);

    final user = authProvider.userData?['user'];
    final photoUrl =
        user != null ? (user['profile_image'] ?? user['image']) : null;

    final allSelectedDays = _getAllSelectedDays();
    final isActivelySelecting = _isMultiSelectMode || _isRangeMode;
    final showBlocksList =
        !isActivelySelecting && agendaProvider.hasSchedule(_viewedDay);
    final todaySlots = agendaProvider.getSlotsForDay(_viewedDay);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A24) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCalendarHeader(isDark, isActivelySelecting),
            const SizedBox(height: 12),
            if (widget.mode == AgendaMode.availability) ...[
              _buildModeToggles(),
              const SizedBox(height: 8),
            ],
            _buildTableCalendar(isDark, agendaProvider),
            const SizedBox(height: 12),
            _buildActionButtons()
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader(bool isDark, bool isActivelySelecting) {
    final textColor = isDark ? Colors.white : AppColors.brandBlue;
    return Row(
      children: [
        _CircularIconButton(
          icon: Icons.chevron_left_rounded,
          onTap: () {
            final previusMonth =
                DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
            final firstAllowedDay = DateTime(2024, 1, 1);

            if (!previusMonth.isBefore(firstAllowedDay)) {
              setState(() {
                _focusedDay = previusMonth;
              });
              _fetchAgendaData();
            }
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                    "${toBeginningOfSentenceCase(DateFormat('MMM', 'es').format(_focusedDay))} ${DateFormat('yyyy').format(_focusedDay)}",
                    key: ValueKey(_focusedDay.month),
                    style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'outfit',
                        height: 1.1)),
              ),
              const SizedBox(height: 4),
              Text(AppLocalizations.of(context)!.calendarLabel,
                  style: TextStyle(
                      color: AppColors.brandBlue.withOpacity(0.6),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _CircularIconButton(
            icon: Icons.chevron_right_rounded,
            onTap: () {
              final nextMonth =
                  DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
              final lastAllowedDay = DateTime(2030, 12, 31);

              if (!nextMonth.isAfter(lastAllowedDay)) {
                setState(() {
                  _focusedDay = nextMonth;
                });
                _fetchAgendaData();
              }
            }),
        const SizedBox(width: 12),
        Visibility(
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          visible: isActivelySelecting,
          child: _CircularIconButton(
              icon: Icons.close_rounded,
              iconColor: AppColors.brandOrange,
              onTap: _clearSelection),
        ),
        const SizedBox(width: 8),
        _CircularIconButton(
            icon: Icons.calendar_today_outlined,
            onTap: () => setState(() {
                  _focusedDay = DateTime.now();
                  if (!isActivelySelecting) _viewedDay = DateTime.now();
                })),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancelModal,
                style: const TextStyle(fontFamily: 'outfit', color: Colors.grey)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context, _getAllSelectedDays());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandCyan,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              widget.mode == AgendaMode.classes
                  ? AppLocalizations.of(context)!.acceptButton
                  : AppLocalizations.of(context)!.configureSchedulesButton,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'outfit',
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeToggles() {
    Color activeColor = _isRangeMode
        ? AppColors.brandOrange
        : (_isMultiSelectMode ? AppColors.brandBlue : AppColors.brandCyan);
    String activeText = _isRangeMode
        ? AppLocalizations.of(context)!.rangeActive
        : (_isMultiSelectMode ? AppLocalizations.of(context)!.multipleSelection : AppLocalizations.of(context)!.dayActive);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton(
          onPressed: () {
            setState(() {
              _isRangeMode = !_isRangeMode;
              if (_isRangeMode) {
                _isMultiSelectMode = false;
                _selectedDays.clear();
              } else {
                _rangeStart = null;
                _rangeEnd = null;
              }
            });
          },
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              side: BorderSide(
                  color: _isRangeMode
                      ? AppColors.brandOrange
                      : Colors.grey.withOpacity(0.3)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20))),
          child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                  AppLocalizations.of(context)!.rangeMode,
                  key: ValueKey(_isRangeMode),
                  style: TextStyle(
                      color: _isRangeMode
                          ? AppColors.brandOrange
                          : Colors.grey[600],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5))),
        ),
        Row(
          children: [
            AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(color: activeColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(AppLocalizations.of(context)!.clearSelection,
                    key: ValueKey(activeText),
                    style: TextStyle(
                        color: activeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5))),
          ],
        )
      ],
    );
  }

bool _isPastDay(DateTime day) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    return day.isBefore(normalizedToday);
  }

  bool _hasDot(DateTime day, TutorAgendaProvider provider) {
    if (widget.mode == AgendaMode.classes) {
      return provider.hasClasses(day);
    } else {
      return provider.hasSchedule(day);
    }
  }

  Widget _buildTableCalendar(bool isDark, TutorAgendaProvider provider) {
    return TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        startingDayOfWeek: StartingDayOfWeek.monday,
        locale: 'es_ES',
        sixWeekMonthsEnforced: true,
        headerVisible: false,
        rowHeight: 46,
        shouldFillViewport: false,
        availableGestures: AvailableGestures.horizontalSwipe,
        rangeSelectionMode: _isRangeMode
            ? RangeSelectionMode.toggledOn
            : RangeSelectionMode.toggledOff,
        rangeStartDay: _rangeStart,
        rangeEndDay: _rangeEnd,
        daysOfWeekHeight: 30,
        daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(
                color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10),
            weekendStyle: TextStyle(
                color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10)),
        calendarStyle: CalendarStyle(
            defaultTextStyle: TextStyle(
                color: isDark ? Colors.white : AppColors.brandBlue,
                fontWeight: FontWeight.w900,
                fontFamily: 'outfit'),
            weekendTextStyle: TextStyle(
                color: isDark
                    ? Colors.white70
                    : AppColors.brandBlue.withOpacity(0.8),
                fontWeight: FontWeight.w900,
                fontFamily: 'outfit'),
            outsideTextStyle: TextStyle(
                color: Colors.grey.withOpacity(0.3),
                fontWeight: FontWeight.bold,
                fontFamily: 'outfit'),
            rangeHighlightColor: Colors.transparent),
        calendarBuilders: CalendarBuilders(
          selectedBuilder: (c, d, f) => _DayDotBuilder(
              day: d,
              color: _isMultiSelectMode
                  ? AppColors.brandBlue
                  : AppColors.brandCyan,
              hasSchedule: _hasDot(d, provider)),
          rangeStartBuilder: (c, d, f) => _DayDotBuilder(
              day: d,
              color: AppColors.brandOrange,
              hasSchedule: _hasDot(d, provider)),
          rangeEndBuilder: (c, d, f) => _DayDotBuilder(
              day: d,
              color: AppColors.brandOrange,
              hasSchedule: _hasDot(d, provider)),
          withinRangeBuilder: (c, d, f) => _DayDotBuilder(
              day: d,
              color: AppColors.brandOrange,
              hasSchedule: _hasDot(d, provider)),
          todayBuilder: (context, day, focusedDay) {
            bool isRangeStart = _isRangeMode &&
                _rangeStart != null &&
                isSameDay(day, _rangeStart);
            bool isRangeEnd =
                _isRangeMode && _rangeEnd != null && isSameDay(day, _rangeEnd);
            bool isWithinRange = false;

            if (_isRangeMode && _rangeStart != null && _rangeEnd != null) {
              DateTime s =
                  _rangeStart!.isBefore(_rangeEnd!) ? _rangeStart! : _rangeEnd!;
              DateTime e =
                  _rangeStart!.isBefore(_rangeEnd!) ? _rangeEnd! : _rangeStart!;
              if (day.isAfter(s) && day.isBefore(e)) isWithinRange = true;
            }

            bool isSelected = (!_isRangeMode &&
                    _isMultiSelectMode &&
                    _selectedDays.any((d) => isSameDay(d, day))) ||
                (!_isRangeMode &&
                    !_isMultiSelectMode &&
                    isSameDay(_viewedDay, day));

            if (isRangeStart || isRangeEnd || isWithinRange) {
              return _DayDotBuilder(
                  day: day,
                  color: AppColors.brandOrange,
                  hasSchedule: _hasDot(day, provider));
            }
            if (isSelected) {
              return _DayDotBuilder(
                  day: day,
                  color: _isMultiSelectMode
                      ? AppColors.brandBlue
                      : AppColors.brandCyan,
                  hasSchedule: _hasDot(day, provider));
            }

            Color borderC =
                _isRangeMode ? AppColors.brandOrange : AppColors.brandCyan;
            return SizedBox(
              width: 46,
              height: 46,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: borderC, width: 1.5)),
                      alignment: Alignment.center,
                      child: Text('${day.day}',
                          style: TextStyle(
                              color:
                                  isDark ? Colors.white : AppColors.brandBlue,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'outfit',
                              fontSize: 14))),
                  if (_hasDot(day, provider))
                    Positioned(
                        bottom: 3,
                        child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                                color: borderC, shape: BoxShape.circle))),
                ],
              ),
            );
          },
          defaultBuilder: (context, day, focusedDay) {
            final isPastDay = widget.mode == AgendaMode.availability && _isPastDay(day);
            
            if (isPastDay && !_hasDot(day, provider)) {
              return Opacity(
                opacity: 0.35,
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.brandBlue,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'outfit',
                    ),
                  ),
                ),
              );
            }

            if (_hasDot(day, provider)) {
              Color borderC =
                  _isRangeMode ? AppColors.brandOrange : AppColors.brandCyan;
              return SizedBox(
                width: 46,
                height: 46,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isPastDay
                                  ? borderC.withOpacity(0.15)
                                  : borderC.withOpacity(0.4),
                                  width: 1.5
                                )),
                        alignment: Alignment.center,
                        child: Text('${day.day}',
                            style: TextStyle(
                                color: isPastDay 
                                    ? (isDark ? Colors.white.withOpacity(0.3) : AppColors.brandBlue.withOpacity(0.3))
                                    : (isDark ? Colors.white : AppColors.brandBlue),
                                fontWeight: FontWeight.w900,
                                fontFamily: 'outfit',
                                fontSize: 14))),
                    Positioned(
                        bottom: 3,
                        child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                                color: isPastDay 
                                  ? borderC.withOpacity(0.3)
                                  : borderC,
                                shape: BoxShape.circle))),
                  ],
                ),
              );
            }
            return null;
          },
        ),
        selectedDayPredicate: (day) {
          if (widget.mode == AgendaMode.classes) return isSameDay(_singleSelectedDay, day);
          if (_isRangeMode) return false;
          if (_isMultiSelectMode) return _selectedDays.any((d) => isSameDay(d, day));
          return isSameDay(_viewedDay, day);
        },
        onDaySelected: (sDay, fDay) {
          if (_isRangeMode) return;
          if (widget.mode == AgendaMode.availability) {
            final today = DateTime.now();
            final normalizedToday = DateTime(today.year, today.month, today.day);
            if (sDay.isBefore(normalizedToday)) {
              return;
            }
          }
          setState(() {
            _focusedDay = fDay;
            if (_isMultiSelectMode) {
              if (_selectedDays.any((d) => isSameDay(d, sDay))) {
                _selectedDays.removeWhere((d) => isSameDay(d, sDay));
                if (_selectedDays.isEmpty) {
                  _isMultiSelectMode = false;
                  _viewedDay = sDay;
                  _singleSelectedDay = sDay;
                }
              } else {
                _selectedDays.add(sDay);
              }
            } else {
              _viewedDay = sDay;
              _singleSelectedDay = sDay;
            }
          });
        },
        onDayLongPressed: (sDay, fDay) {
          if (_isRangeMode) return;
          if (widget.mode == AgendaMode.availability) {
            final today = DateTime.now();
            final normalizedToday = DateTime(today.year, today.month, today.day);
            if (sDay.isBefore(normalizedToday)) return; // 🌟 Protege pulsación larga en el pasado
          }
          HapticFeedback.heavyImpact();
          setState(() {
            _isMultiSelectMode = true;
            _focusedDay = fDay;
            _selectedDays.add(_viewedDay);
            if (!_selectedDays.any((d) => isSameDay(d, sDay))) {
              _selectedDays.add(sDay);
            }
          });
        },
        onRangeSelected: widget.mode == AgendaMode.availability
          ? (s, e, f) {
            final today = DateTime.now();
            final normalizedToday = DateTime(today.year, today.month, today.day);
            
            if (s != null && s.isBefore(normalizedToday)) return;
            if (e != null && e.isBefore(normalizedToday)) return;
            
            setState(() {
              _rangeStart = s;
              _rangeEnd = e;
              _focusedDay = f;
            });
          } 
          : null,
        onPageChanged: (f) {
          setState(() {
            _focusedDay = f;
          });
          _fetchAgendaData();
        });
  }

  Widget _buildConfigureButton(bool isDark, bool isActivelySelecting,
      List<DateTime> days, AuthProvider auth, TutorAgendaProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add, color: Colors.white, size: 18),
        label: Text("CONFIGURAR HORARIOS (${days.length})",
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5)),
        onPressed:
            (isActivelySelecting && days.isNotEmpty && !provider.isMutating)
                ? () {
                    showDialog(
                      context: context,
                      barrierColor: Colors.black.withOpacity(0.6),
                      builder: (dialogContext) => AddScheduleSheet(
                        selectedDays: days,
                        onSave: (sTime, eTime) async {
                          final success = await provider.saveSlotsForDays(
                              token: auth.token ?? '',
                              userId: auth.userId?.toString() ?? '',
                              days: days,
                              newSlots: [
                                {'start': sTime, 'end': eTime}
                              ]);
                          if (success && mounted) {
                            _clearSelection();
                            CustomToast.show(
                                context, "Horario guardado correctamente",
                                isSuccess: true);
                          }
                        },
                      ),
                    );
                  }
                : null,
        style: ElevatedButton.styleFrom(
            backgroundColor:
                isActivelySelecting ? AppColors.brandBlue : Colors.grey[300],
            disabledBackgroundColor: isDark ? Colors.white10 : Colors.grey[300],
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20))),
      ),
    );
  }

  Widget _buildSectionTitleRow(
      bool isDark, bool isActivelySelecting, int count) {
    String title = _isRangeMode && _rangeStart == null
        ? AppLocalizations.of(context)!.selectRange
        : (isActivelySelecting
            ? "${AppLocalizations.of(context)!.selectedDaysLabel} ($count)"
            : "${AppLocalizations.of(context)!.dayBlocksLabel} ${_viewedDay.day}");
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(title,
                  key: ValueKey(title),
                  style: TextStyle(
                      color: isDark ? Colors.white : AppColors.brandBlue,
                      fontSize: 14,
                      fontFamily: 'outfit',
                      fontWeight: FontWeight.w900))),
          IgnorePointer(
              ignoring: !isActivelySelecting,
              child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isActivelySelecting ? 1.0 : 0.0,
                  child: TextButton(
                      onPressed: _clearSelection,
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0)),
                      child: Text(AppLocalizations.of(context)!.clearSelection,
                          style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold))))),
        ],
      ),
    );
  }

  Widget _buildBottomState(
      TutorAgendaProvider p,
      bool showList,
      List<Map<String, dynamic>> slots,
      bool isDark,
      bool isSelecting,
      AuthProvider auth) {
    if (p.isLoadingSlots) {
      return Container(
          padding: const EdgeInsets.all(40),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(color: AppColors.brandCyan));
    }
    if (p.errorMessage != null) {
      return Container(
          padding: const EdgeInsets.all(20),
          alignment: Alignment.center,
          child: Column(children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 40),
            const SizedBox(height: 10),
            Text(p.errorMessage!,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
            TextButton(
                onPressed: _fetchAgendaData, child: const Text("Reintentar"))
          ]));
    }
    if (!showList || slots.isEmpty) {
      return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(
                isSelecting
                    ? Icons.library_add_check_rounded
                    : Icons.calendar_today_rounded,
                size: 50,
                color:
                    isDark ? Colors.white24 : Colors.blueGrey.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
                isSelecting
                    ? AppLocalizations.of(context)!.readyToConfigureSchedules
                    : AppLocalizations.of(context)!.noBlocksRegistered,
                style: TextStyle(
                    color: isDark
                        ? Colors.white54
                        : Colors.blueGrey.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2))
          ]));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: slots
            .map((slot) => _TimeCard(
                timeRange: "${slot['start']} - ${slot['end']}",
                isDark: isDark,
                onDelete: () async {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor:
                          isDark ? const Color(0xFF151A24) : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: Text(AppLocalizations.of(context)!.deleteScheduleTitle,
                          style: TextStyle(
                              color:
                                  isDark ? Colors.white : AppColors.brandBlue,
                              fontWeight: FontWeight.bold)),
                      content: Text(
                          AppLocalizations.of(context)!.deleteScheduleConfirm,
                          style: TextStyle(color: Colors.grey[500])),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(AppLocalizations.of(context)!.cancelDialogButton,
                              style: const TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();

                            final ok = await p.deleteSlot(
                                auth.token ?? '',
                                slot['id'].toString(),
                                auth.userId?.toString() ?? '',
                                _viewedDay);

                            if (ok && mounted) {
                              CustomToast.show(
                                context,
                                AppLocalizations.of(context)!.scheduleDeletedSuccessfully2,
                                isSuccess: true,
                              );
                            } else {
                              CustomToast.show(
                                context,
                                AppLocalizations.of(context)!.errorDeletingScheduleMsg,
                                isSuccess: false,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          child: Text(AppLocalizations.of(context)!.deleteButton2,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                }))
            .toList(),
      ),
    );
  }
}

// Widget privado para los puntos de colores (Tu código exacto)
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
                  shape: BoxShape.circle, color: color.withOpacity(0.2))),
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
                      fontSize: 14))),
          if (hasSchedule)
            Positioned(
                bottom: 3,
                child: Container(
                    width: 5,
                    height: 5,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle))),
        ],
      ),
    );
  }
}

class _CircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  const _CircularIconButton(
      {required this.icon, required this.onTap, this.iconColor});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon,
                size: 18,
                color: iconColor ??
                    (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.brandBlue))));
  }
}

class _TimeCard extends StatelessWidget {
  final String timeRange;
  final bool isDark;
  final VoidCallback onDelete;
  const _TimeCard(
      {required this.timeRange, required this.isDark, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151A24) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Row(
        children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.brandCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.access_time_rounded,
                  color: AppColors.brandCyan, size: 20)),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(timeRange,
                    style: TextStyle(
                        color: isDark ? Colors.white : AppColors.brandBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'outfit')),
                const SizedBox(height: 2),
                Text(AppLocalizations.of(context)!.sessionDuration,
                    style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5))
              ])),
          GestureDetector(
              onTap: onDelete,
              child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent, size: 20))),
        ],
      ),
    );
  }
}
