import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/view/tutor/features/agenda/providers/tutor_agenda_provider.dart';
import 'package:flutter_projects/view/tutor/dashboard/sheets/add_schedule_sheet.dart';
import 'package:flutter_projects/view/tutor/dashboard/widgets/section_header.dart';

class TutorAgendaScreen extends StatefulWidget {
  const TutorAgendaScreen({Key? key}) : super(key: key);

  @override
  State<TutorAgendaScreen> createState() => _TutorAgendaScreenState();
}

class _TutorAgendaScreenState extends State<TutorAgendaScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _viewedDay = DateTime.now();

  bool _isMultiSelectMode = false;
  Set<DateTime> _selectedDays = {};

  bool _isRangeMode = false;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAgendaData());
  }

  // FUTURE PARA EL REFRESH INDICATOR
  Future<void> _fetchAgendaData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null && authProvider.userId != null) {
      await Provider.of<TutorAgendaProvider>(context, listen: false)
          .loadAvailableSlots(
              authProvider.token!, authProvider.userId!.toString());
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            SectionHeader(
              title: "Agenda",
              profileImageUrl: photoUrl,
              actionIcon: Icons.calendar_today_rounded,
              onActionTap: () {
                setState(() => _focusedDay = DateTime.now());
                _clearSelection();
              },
            ),
            Expanded(
              //  EL REFRESH INDICATOR PARA RECARGAR DESLIZANDO HACIA ABAJO
              child: RefreshIndicator(
                color: AppColors.brandCyan,
                backgroundColor: isDark ? const Color(0xFF151A24) : Colors.white,
                onRefresh: _fetchAgendaData,
                child: SingleChildScrollView(
                  // ESTO PERMITE QUE EL SCROLL FUNCIONE EN TODA LA PANTALLA
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.only(bottom: 120, top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. TARJETA BLANCA (CALENDARIO)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF151A24) : Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 8))
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildCalendarHeader(isDark, isActivelySelecting),
                            const SizedBox(height: 12),
                            _buildModeToggles(),
                            const SizedBox(height: 8),
                            _buildTableCalendar(isDark, agendaProvider),
                            const SizedBox(height: 12),
                            _buildConfigureButton(isDark, isActivelySelecting,
                                allSelectedDays, authProvider, agendaProvider),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 2. SECCIÓN DE RESULTADOS
                      _buildSectionTitleRow(
                          isDark, isActivelySelecting, allSelectedDays.length),
                      const SizedBox(height: 16),
                      _buildBottomState(agendaProvider, showBlocksList,
                          todaySlots, isDark, isActivelySelecting, authProvider),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGETS MODULARIZADOS DE LA PANTALLA
  Widget _buildCalendarHeader(bool isDark, bool isActivelySelecting) {
    final textColor = isDark ? Colors.white : AppColors.brandBlue;
    return Row(
      children: [
        _CircularIconButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => setState(() => _focusedDay =
                DateTime(_focusedDay.year, _focusedDay.month - 1, 1))),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                    "${toBeginningOfSentenceCase(DateFormat('MMMM', 'es').format(_focusedDay))} ${DateFormat('yyyy').format(_focusedDay)}",
                    key: ValueKey(_focusedDay.month),
                    style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'outfit',
                        height: 1.1)),
              ),
              const SizedBox(height: 4),
              Text("CALENDARIO",
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
            onTap: () => setState(() => _focusedDay =
                DateTime(_focusedDay.year, _focusedDay.month + 1, 1))),
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

  Widget _buildModeToggles() {
    Color activeColor = _isRangeMode
        ? AppColors.brandOrange
        : (_isMultiSelectMode ? AppColors.brandBlue : AppColors.brandCyan);
    String activeText = _isRangeMode
        ? "RANGO ACTIVO"
        : (_isMultiSelectMode ? "SELECCIÓN MÚLTIPLE" : "DÍA ACTIVO");

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
              child: Text("MODO RANGO",
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
                child: Text(activeText,
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
      // ESTO BLOQUEA LOS DESLIZAMIENTOS VERTICALES DEL CALENDARIO Y ARREGLA EL SCROLL
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
            color:
                _isMultiSelectMode ? AppColors.brandBlue : AppColors.brandCyan,
            hasSchedule: provider.hasSchedule(d)),
        rangeStartBuilder: (c, d, f) => _DayDotBuilder(
            day: d,
            color: AppColors.brandOrange,
            hasSchedule: provider.hasSchedule(d)),
        rangeEndBuilder: (c, d, f) => _DayDotBuilder(
            day: d,
            color: AppColors.brandOrange,
            hasSchedule: provider.hasSchedule(d)),
        withinRangeBuilder: (c, d, f) => _DayDotBuilder(
            day: d,
            color: AppColors.brandOrange,
            hasSchedule: provider.hasSchedule(d)),
        
        todayBuilder: (context, day, focusedDay) {
          // Si el día de "Hoy" está seleccionado en un rango, dejamos que se pinte naranja
          bool isRangeStart = _isRangeMode && _rangeStart != null && isSameDay(day, _rangeStart);
          bool isRangeEnd = _isRangeMode && _rangeEnd != null && isSameDay(day, _rangeEnd);
          bool isWithinRange = false;
          
          if (_isRangeMode && _rangeStart != null && _rangeEnd != null) {
            DateTime s = _rangeStart!.isBefore(_rangeEnd!) ? _rangeStart! : _rangeEnd!;
            DateTime e = _rangeStart!.isBefore(_rangeEnd!) ? _rangeEnd! : _rangeStart!;
            if (day.isAfter(s) && day.isBefore(e)) isWithinRange = true;
          }
          
          bool isSelected = (!_isRangeMode && _isMultiSelectMode && _selectedDays.any((d) => isSameDay(d, day))) || 
                            (!_isRangeMode && !_isMultiSelectMode && isSameDay(_viewedDay, day));

          // Si cayó en un rango naranja, lo forzamos a ser naranja
          if (isRangeStart || isRangeEnd || isWithinRange) {
             return _DayDotBuilder(day: day, color: AppColors.brandOrange, hasSchedule: provider.hasSchedule(day));
          }
          // Si está seleccionado manualmente (Punto Azul/Cyan)
          if (isSelected) {
             return _DayDotBuilder(day: day, color: _isMultiSelectMode ? AppColors.brandBlue : AppColors.brandCyan, hasSchedule: provider.hasSchedule(day));
          }

          // Si el día de Hoy NO está seleccionado, le ponemos su borde propio
          Color borderC = _isRangeMode ? AppColors.brandOrange : AppColors.brandCyan;
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
                            color: isDark ? Colors.white : AppColors.brandBlue,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'outfit',
                            fontSize: 14))),
                if (provider.hasSchedule(day))
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
          if (provider.hasSchedule(day)) {
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
                              color: borderC.withOpacity(0.3), width: 1.5)),
                      alignment: Alignment.center,
                      child: Text('${day.day}',
                          style: TextStyle(
                              color:
                                  isDark ? Colors.white : AppColors.brandBlue,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'outfit',
                              fontSize: 14))),
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
          }
          return null;
        },
      ),
      selectedDayPredicate: (day) {
        if (_isRangeMode) return false;
        if (_isMultiSelectMode) return _selectedDays.any((d) => isSameDay(d, day));
        return isSameDay(_viewedDay, day);
      },
      onDaySelected: (sDay, fDay) {
        if (_isRangeMode) return;
        setState(() {
          _focusedDay = fDay;
          if (_isMultiSelectMode) {
            if (_selectedDays.any((d) => isSameDay(d, sDay))) {
              _selectedDays.removeWhere((d) => isSameDay(d, sDay));
              if (_selectedDays.isEmpty) {
                _isMultiSelectMode = false;
                _viewedDay = sDay;
              }
            } else {
              _selectedDays.add(sDay);
            }
          } else {
            _viewedDay = sDay;
          }
        });
      },
      onDayLongPressed: (sDay, fDay) {
        if (_isRangeMode) return;
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
      onRangeSelected: (s, e, f) => setState(() {
        _rangeStart = s;
        _rangeEnd = e;
        _focusedDay = f;
      }),
      onPageChanged: (f) => _focusedDay = f,
    );
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
        onPressed: (isActivelySelecting &&
                days.isNotEmpty &&
                !provider.isMutating)
            ? () {
                final scaffoldMsg = ScaffoldMessenger.of(context);
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
                        scaffoldMsg.showSnackBar(const SnackBar(
                            content: Text("Horarios asignados"),
                            backgroundColor: AppColors.primaryGreen));
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
        ? "SELECCIONA UN RANGO"
        : (isActivelySelecting
            ? "DÍAS SELECCIONADOS ($count)"
            : "BLOQUES DEL DÍA ${_viewedDay.day}");
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
                      child: const Text("LIMPIAR",
                          style: TextStyle(
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
                    ? "LISTO PARA CONFIGURAR HORARIOS"
                    : "SIN BLOQUES REGISTRADOS",
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
                  showDialog(context: context, builder: (dialogContext) => AlertDialog(
                    backgroundColor: isDark ? const Color(0xFF151A24) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text('Eliminar horario', style: TextStyle(color: isDark ? Colors.white : AppColors.brandBlue, fontWeight: FontWeight.bold)),
                content: Text('¿Estás seguro de que quieres eliminar este horario?', style: TextStyle(color: Colors.grey[500])),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop(); 
                      
                      final scaffoldMsg = ScaffoldMessenger.of(context);
                      final ok = await p.deleteSlot(
                        auth.token ?? '', 
                        slot['id'].toString(), 
                        auth.userId?.toString() ?? '', 
                        _viewedDay
                      );
                      
                      if (ok && mounted) {
                        scaffoldMsg.showSnackBar(const SnackBar(content: Text("Horario eliminado exitosamente"), backgroundColor: AppColors.primaryGreen));
                      } else {
                        scaffoldMsg.showSnackBar(const SnackBar(content: Text("Error al eliminar el horario"), backgroundColor: Colors.redAccent));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          })).toList(),
      ),
    );
  }
}

// WIDGETS PRIVADOS EXCLUIDOS 
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
                      fontSize: 14,
                      height: 1.0))),
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
                Text("SESIÓN DE 20 MIN",
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