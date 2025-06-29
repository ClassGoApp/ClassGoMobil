import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class StudentCalendarScreen extends StatefulWidget {
  const StudentCalendarScreen({Key? key}) : super(key: key);

  @override
  State<StudentCalendarScreen> createState() => _StudentCalendarScreenState();
}

class _StudentCalendarScreenState extends State<StudentCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  String _viewMode = 'month'; // 'month', 'week', 'day'
  String _selectedFilter = 'todas';

  // Simulación de tutorías
  final List<Map<String, dynamic>> _tutorias = [
    {
      'title': 'Matemáticas',
      'date': DateTime.now(),
      'hour': '10:00',
      'status': 'completada',
    },
    {
      'title': 'Inglés',
      'date': DateTime.now(),
      'hour': '12:00',
      'status': 'pendiente',
    },
    {
      'title': 'Física',
      'date': DateTime.now(),
      'hour': '15:00',
      'status': 'aceptada',
    },
    {
      'title': 'Química',
      'date': DateTime.now().subtract(Duration(days: 2)),
      'hour': '09:00',
      'status': 'rechazada',
    },
    {
      'title': 'Historia',
      'date': DateTime.now().add(Duration(days: 3)),
      'hour': '17:00',
      'status': 'observada',
    },
    // Puedes agregar más para probar
  ];

  // Colores por estado
  Color _statusColor(String status) {
    switch (status) {
      case 'completada':
        return AppColors.primaryGreen;
      case 'pendiente':
        return AppColors.orangeprimary.withOpacity(0.85);
      case 'aceptada':
        return AppColors.lightBlueColor;
      case 'observada':
        return AppColors.darkBlue.withOpacity(0.85);
      case 'rechazada':
        return Colors.redAccent.withOpacity(0.85);
      default:
        return Colors.grey;
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
      builder: (context) {
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
              ...tutoriasDelDia.map((t) => Card(
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
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${t['hour']} - Estado: ${t['status'][0].toUpperCase()}${t['status'].substring(1)}',
                        style: TextStyle(
                            color: _statusColor(t['status']),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  )),
            ],
          ),
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
    {'label': 'Completada', 'value': 'completada'},
    {'label': 'Pendiente', 'value': 'pendiente'},
    {'label': 'Aceptada', 'value': 'aceptada'},
    {'label': 'Observada', 'value': 'observada'},
    {'label': 'Rechazada', 'value': 'rechazada'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181F2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181F2A),
        elevation: 0,
        title: const Text('Mi Calendario',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildCalendar(),
      ),
    );
  }

  Widget _buildCalendar() {
    if (_viewMode == 'month') {
      return _buildMonthView();
    } else if (_viewMode == 'week') {
      return _buildWeekView();
    } else {
      return _buildDayView();
    }
  }

  Widget _buildMonthView() {
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
        Expanded(
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
              final tutoriasDelDia = _tutorias
                  .where((t) => DateUtils.isSameDay(t['date'], day))
                  .toList();
              final hasTutorias = tutoriasDelDia.isNotEmpty;
              return GestureDetector(
                onTap: isCurrentMonth && hasTutorias
                    ? () => _showDayTutorias(day)
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
                          child: Icon(Icons.book,
                              size: 14,
                              color:
                                  AppColors.lightBlueColor.withOpacity(0.85)),
                        ),
                      if (hasTutorias)
                        Positioned(
                          bottom: 6,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: tutoriasDelDia
                                .map((t) => Container(
                                      width: 10,
                                      height: 10,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 2),
                                      decoration: BoxDecoration(
                                        color: _statusColor(t['status']),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 1),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // --- Gráfico de progreso SIEMPRE visible ---
        Padding(
          padding: const EdgeInsets.only(top: 0, bottom: 130),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProgressRing(percent: 0.6, completed: 3, goal: 5),
              const SizedBox(width: 18),
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerRight,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white12, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¡Buen trabajo!',
                          style: TextStyle(
                            color: AppColors.lightBlueColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Llevas 3 tutorías completadas\neste mes. ¡Sigue así!',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: -32,
                    bottom: -10,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/ave_animada.gif',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekView() {
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
        Expanded(
          child: Row(
            children: days.map((day) {
              final tutoriasDelDia = _tutorias
                  .where((t) => DateUtils.isSameDay(t['date'], day))
                  .toList();
              final hasTutorias = tutoriasDelDia.isNotEmpty;
              return Expanded(
                child: GestureDetector(
                  onTap: hasTutorias ? () => _showDayTutorias(day) : null,
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
                    height: double.infinity,
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
                            if (hasTutorias)
                              Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: tutoriasDelDia
                                      .map((t) => Container(
                                            width: 10,
                                            height: 10,
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 2),
                                            decoration: BoxDecoration(
                                              color: _statusColor(t['status']),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: Colors.white,
                                                  width: 1),
                                            ),
                                          ))
                                      .toList(),
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

  Widget _buildDayView() {
    final tutoriasDelDia = _tutorias
        .where((t) => DateUtils.isSameDay(t['date'], _focusedDay))
        .toList();
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
        Expanded(
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
