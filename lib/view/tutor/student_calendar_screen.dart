import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_projects/provider/tutorias_provider.dart';

class StudentCalendarScreen extends StatefulWidget {
  const StudentCalendarScreen({Key? key}) : super(key: key);

  @override
  State<StudentCalendarScreen> createState() => _StudentCalendarScreenState();
}

class _StudentCalendarScreenState extends State<StudentCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  String _viewMode = 'month'; // 'month', 'week', 'day'
  String _selectedFilter = 'todas';
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<Map<String, dynamic>> _tutorias = [];

  // Cache para optimizar búsquedas
  Map<String, List<Map<String, dynamic>>> _tutoriasByDate = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidity = Duration(minutes: 5);

  // Colores por estado
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'completada':
        return AppColors.primaryGreen;
      case 'pending':
      case 'pendiente':
        return AppColors.orangeprimary.withOpacity(0.85);
      case 'accepted':
      case 'aceptada':
        return AppColors.lightBlueColor;
      case 'observed':
      case 'observada':
        return AppColors.darkBlue.withOpacity(0.85);
      case 'rejected':
      case 'rechazada':
        return Colors.redAccent.withOpacity(0.85);
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final tutoriasProvider =
          Provider.of<TutoriasProvider>(context, listen: false);
      tutoriasProvider.loadTutorias();
    });
  }

  // Calcular estadísticas del mes actual usando el provider
  Map<String, dynamic> _calculateMonthlyStats(
      List<Map<String, dynamic>> tutorias) {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    final validTutorias = tutorias.where((t) {
      final tutoriaDate = t['date'] as DateTime;
      final status = (t['status'] ?? '').toString().toLowerCase();
      return tutoriaDate.year == currentYear &&
          tutoriaDate.month == currentMonth &&
          status != 'rechazado';
    }).toList();
    final completed = validTutorias.length;
    int goal = 5;
    if (completed >= 5) goal = 10;
    if (completed >= 10) goal = 20;
    if (completed >= 20) goal = 50;
    if (completed >= 50) goal = 100;
    final percent = goal > 0 ? (completed / goal).clamp(0.0, 1.0) : 0.0;
    return {
      'completed': completed,
      'goal': goal,
      'percent': percent,
    };
  }

  // Generar mensaje motivacional basado en el progreso
  String _getMotivationalMessage(int completed, int goal) {
    if (completed == 0) {
      return '¡Comienza tu viaje de aprendizaje!\nTu meta: $goal tutorías este mes';
    } else if (completed < goal) {
      final remaining = goal - completed;
      return '¡Excelente progreso!\nTe faltan $remaining tutorías para alcanzar tu meta';
    } else {
      return '¡Meta superada!\nHas completado $completed tutorías este mes';
    }
  }

  void _showDayTutorias(DateTime day) {
    final tutoriasDelDia =
        _tutorias.where((t) => DateUtils.isSameDay(t['date'], day)).toList();
    if (tutoriasDelDia.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Text(
                    'Tutorías del ${day.day}/${day.month}/${day.year}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: tutoriasDelDia.length,
                      itemBuilder: (context, index) {
                        final t = tutoriasDelDia[index];
                        return Card(
                          color: _statusColor(t['status']).withOpacity(0.18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _statusColor(t['status']),
                              child: Icon(Icons.book, color: Colors.white),
                            ),
                            title: Text(
                              t['title'],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${t['hour']} - ${t['tutor_name']}',
                                  style: TextStyle(
                                      color: _statusColor(t['status']),
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Estado: ${t['status'][0].toUpperCase()}${t['status'].substring(1)}',
                                  style: TextStyle(
                                      color: _statusColor(t['status']),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> get _filteredTutorias {
    final sorted = List<Map<String, dynamic>>.from(_tutorias)
      ..sort((a, b) => b['date'].compareTo(a['date']));
    if (_selectedFilter == 'todas') return sorted;
    return sorted.where((t) => t['status'] == _selectedFilter).toList();
  }

  final List<Map<String, dynamic>> _filterCapsules = [
    {'label': 'Todas', 'value': 'todas'},
    {'label': 'Completada', 'value': 'completed'},
    {'label': 'Pendiente', 'value': 'pending'},
    {'label': 'Aceptada', 'value': 'accepted'},
    {'label': 'Observada', 'value': 'observed'},
    {'label': 'Rechazada', 'value': 'rejected'},
  ];

  @override
  Widget build(BuildContext context) {
    final tutoriasProvider = Provider.of<TutoriasProvider>(context);
    final _isLoading = tutoriasProvider.isLoading;
    final _tutorias = tutoriasProvider.tutorias;

    if (_isLoading) {
      return Container(
        color: AppColors.primaryGreen,
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.6,
            child: Image.asset(
              'assets/images/cargando.gif',
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF181F2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181F2A),
        elevation: 0,
        title: const Text('Mi Calendario',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.refresh,
                color: Colors.white),
            onPressed: _isLoading ? null : tutoriasProvider.refreshTutorias,
          ),
          ToggleButtons(
            borderRadius: BorderRadius.circular(12),
            selectedColor: Colors.white,
            fillColor: Colors.blueAccent.withOpacity(0.2),
            color: Colors.white70,
            isSelected: [
              _viewMode == 'month',
              _viewMode == 'week',
              _viewMode == 'day',
            ],
            onPressed: (index) {
              setState(() {
                _viewMode = ['month', 'week', 'day'][index];
              });
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.calendar_view_month),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.view_week),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.calendar_view_day),
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: 16.0, right: 16.0, top: 8.0, bottom: 0),
              child: _buildCalendar(context, tutoriasProvider),
            ),
            if (_viewMode != 'day') ...[
              if (_viewMode == 'week') SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(top: 0, bottom: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Builder(
                      builder: (context) {
                        final stats = _calculateMonthlyStats(_tutorias);
                        return Center(
                          child: ProgressRing(
                            percent: stats['percent'],
                            completed: stats['completed'],
                            goal: stats['goal'],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final stats = _calculateMonthlyStats(_tutorias);
                        final message = _getMotivationalMessage(
                          stats['completed'],
                          stats['goal'],
                        );
                        return Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                      color: Colors.white12, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      stats['completed'] >= stats['goal']
                                          ? '¡Meta alcanzada!'
                                          : '¡Buen trabajo!',
                                      style: TextStyle(
                                        color: AppColors.lightBlueColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      message,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 8,
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/ave_animada.gif',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(
      BuildContext context, TutoriasProvider tutoriasProvider) {
    if (_viewMode == 'month') {
      return _buildMonthView(tutoriasProvider);
    } else if (_viewMode == 'week') {
      return _buildWeekView(tutoriasProvider);
    } else {
      return _buildDayView(tutoriasProvider);
    }
  }

  Widget _buildMonthView(TutoriasProvider tutoriasProvider) {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final daysInMonth =
        DateUtils.getDaysInMonth(_focusedDay.year, _focusedDay.month);
    final firstWeekday = firstDayOfMonth.weekday;
    final weekDays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final days = <DateTime>[];
    for (int i = 0; i < firstWeekday - 1; i++) {
      days.add(firstDayOfMonth.subtract(Duration(days: firstWeekday - 1 - i)));
    }
    for (int i = 0; i < daysInMonth; i++) {
      days.add(DateTime(_focusedDay.year, _focusedDay.month, i + 1));
    }
    while (days.length % 7 != 0) {
      days.add(days.last.add(const Duration(days: 1)));
    }
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white70),
              onPressed: () {
                setState(() {
                  _focusedDay =
                      DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                });
              },
            ),
            Text(
              '${_monthName(_focusedDay.month)} ${_focusedDay.year}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white70),
              onPressed: () {
                setState(() {
                  _focusedDay =
                      DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays
              .map((d) => Expanded(
                    child: Center(
                        child: Text(d,
                            style: const TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.bold))),
                  ))
              .toList(),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 300,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 1.1,
            ),
            itemCount: days.length,
            itemBuilder: (context, i) {
              final day = days[i];
              final isToday = DateUtils.isSameDay(day, DateTime.now());
              final isCurrentMonth = day.month == _focusedDay.month;
              final tutoriasDelDia = tutoriasProvider.getTutoriasForDay(day);
              final hasTutorias = tutoriasDelDia.isNotEmpty;
              return GestureDetector(
                onTap: isCurrentMonth && hasTutorias
                    ? () => _showDayTutoriasProvider(day, tutoriasProvider)
                    : null,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isToday && hasTutorias
                        ? Colors.blueAccent.withOpacity(0.25)
                        : hasTutorias
                            ? AppColors.lightBlueColor.withOpacity(0.13)
                            : isToday
                                ? Colors.blueAccent.withOpacity(0.13)
                                : isCurrentMonth
                                    ? Colors.white.withOpacity(0.04)
                                    : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: isToday
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: hasTutorias
                        ? [
                            BoxShadow(
                              color: AppColors.lightBlueColor.withOpacity(0.18),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color:
                                isCurrentMonth ? Colors.white : Colors.white24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (hasTutorias)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Icon(Icons.book_online,
                              size: 14,
                              color:
                                  AppColors.lightBlueColor.withOpacity(0.85)),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekView(TutoriasProvider tutoriasProvider) {
    final weekDays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final today = _focusedDay;
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white70),
              onPressed: () {
                setState(() {
                  _focusedDay = _focusedDay.subtract(const Duration(days: 7));
                });
              },
            ),
            Text(
              'Semana de ${days.first.day} ${_monthName(days.first.month)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white70),
              onPressed: () {
                setState(() {
                  _focusedDay = _focusedDay.add(const Duration(days: 7));
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays
              .map((d) => Expanded(
                    child: Center(
                        child: Text(d,
                            style: const TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.bold))),
                  ))
              .toList(),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 200,
          child: Row(
            children: days.map((day) {
              final tutoriasDelDia = tutoriasProvider.getTutoriasForDay(day);
              final hasTutorias = tutoriasDelDia.isNotEmpty;
              return Expanded(
                child: GestureDetector(
                  onTap: hasTutorias
                      ? () => _showDayTutoriasProvider(day, tutoriasProvider)
                      : null,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: DateUtils.isSameDay(day, DateTime.now()) &&
                              hasTutorias
                          ? Colors.blueAccent.withOpacity(0.25)
                          : hasTutorias
                              ? AppColors.lightBlueColor.withOpacity(0.13)
                              : DateUtils.isSameDay(day, DateTime.now())
                                  ? Colors.blueAccent.withOpacity(0.13)
                                  : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: DateUtils.isSameDay(day, DateTime.now())
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      boxShadow: hasTutorias
                          ? [
                              BoxShadow(
                                color:
                                    AppColors.lightBlueColor.withOpacity(0.18),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (hasTutorias)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Icon(Icons.book,
                                size: 14,
                                color:
                                    AppColors.lightBlueColor.withOpacity(0.85)),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDayView(TutoriasProvider tutoriasProvider) {
    final tutoriasDelDia = tutoriasProvider.getTutoriasForDay(_focusedDay);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white70),
              onPressed: () {
                setState(() {
                  _focusedDay = _focusedDay.subtract(const Duration(days: 1));
                });
              },
            ),
            Text(
              '${_focusedDay.day} ${_monthName(_focusedDay.month)} ${_focusedDay.year}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white70),
              onPressed: () {
                setState(() {
                  _focusedDay = _focusedDay.add(const Duration(days: 1));
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 400,
          child: tutoriasDelDia.isEmpty
              ? Center(
                  child: Text(
                    'No hay tutorías para este día',
                    style: const TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                )
              : ListView(
                  children: tutoriasDelDia
                      .map((t) => Card(
                            color: _statusColor(t['status']).withOpacity(0.18),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _statusColor(t['status']),
                                child: Icon(Icons.book, color: Colors.white),
                              ),
                              title: Text(
                                t['title'],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${t['hour']} - Estado: ${t['status'][0].toUpperCase()}${t['status'].substring(1)}',
                                style: TextStyle(
                                    color: _statusColor(t['status']),
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }

  void _showDayTutoriasProvider(
      DateTime day, TutoriasProvider tutoriasProvider) {
    final tutoriasDelDia = tutoriasProvider.getTutoriasForDay(day);
    if (tutoriasDelDia.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Text(
                    'Tutorías del ${day.day}/${day.month}/${day.year}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: tutoriasDelDia.length,
                      itemBuilder: (context, index) {
                        final t = tutoriasDelDia[index];
                        return Card(
                          color: _statusColor(t['status']).withOpacity(0.18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _statusColor(t['status']),
                              child: Icon(Icons.book, color: Colors.white),
                            ),
                            title: Text(
                              t['title'],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${t['hour']} - ${t['tutor_name']}',
                                  style: TextStyle(
                                      color: _statusColor(t['status']),
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Estado: ${t['status'][0].toUpperCase()}${t['status'].substring(1)}',
                                  style: TextStyle(
                                      color: _statusColor(t['status']),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class ProgressRing extends StatelessWidget {
  final double percent;
  final int completed;
  final int goal;
  const ProgressRing(
      {Key? key,
      required this.percent,
      required this.completed,
      required this.goal})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 10,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(AppColors.lightBlueColor),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$completed',
                style: TextStyle(
                  color: AppColors.lightBlueColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
              Text(
                'de $goal',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
              Text(
                'completadas',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
