import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/provider/booking_provider.dart';
import 'package:flutter_projects/provider/tutorias_provider.dart';
import 'package:flutter_projects/view/home/home_screen.dart';

class StudentCalendarScreen extends StatefulWidget {
  const StudentCalendarScreen({Key? key}) : super(key: key);

  @override
  State<StudentCalendarScreen> createState() => _StudentCalendarScreenState();
}

class _StudentCalendarScreenState extends State<StudentCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  String _viewMode = 'month'; // 'month', 'week', 'day'

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    bookingProvider.loadBookings(authProvider);
  }

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

  void _showDayTutorias(DateTime day, List<Map<String, dynamic>> tutorias,
      Set<DateTime> diasConTutoria) {
    final tutoriasDelDia =
        tutorias.where((t) => DateUtils.isSameDay(t['date'], day)).toList();
    if (tutoriasDelDia.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
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
              SizedBox(
                height: 300,
                child: ListView(
                  shrinkWrap: true,
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, _) {
        final tutorias = bookingProvider.bookings;
        final diasConTutoria = tutorias
            .map(
                (t) => DateTime(t['date'].year, t['date'].month, t['date'].day))
            .toSet();
        return Scaffold(
          backgroundColor: const Color(0xFF181F2A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF181F2A),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                  (route) => false,
                );
              },
            ),
            title: const Text('Mi Calendario',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
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
          body: bookingProvider.isLoading
              ? Center(
                  child: Image.asset(
                    'assets/images/loading_tutorias.gif',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildCalendar(tutorias, diasConTutoria),
                ),
        );
      },
    );
  }

  Widget _buildCalendar(
      List<Map<String, dynamic>> tutorias, Set<DateTime> diasConTutoria) {
    if (_viewMode == 'month') {
      return _buildMonthView(tutorias, diasConTutoria);
    } else if (_viewMode == 'week') {
      return _buildWeekView(tutorias, diasConTutoria);
    } else {
      return _buildDayView(tutorias);
    }
  }

  Widget _buildMonthView(
      List<Map<String, dynamic>> tutorias, Set<DateTime> diasConTutoria) {
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
              final isSelectable = diasConTutoria
                  .contains(DateTime(day.year, day.month, day.day));
              return GestureDetector(
                onTap: isCurrentMonth && isSelectable
                    ? () => _showDayTutorias(day, tutorias, diasConTutoria)
                    : null,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelectable
                        ? (isToday
                            ? AppColors.lightBlueColor.withOpacity(0.35)
                            : AppColors.lightBlueColor.withOpacity(0.18))
                        : (isToday
                            ? Colors.blueAccent.withOpacity(0.13)
                            : isCurrentMonth
                                ? Colors.white.withOpacity(0.04)
                                : Colors.transparent),
                    borderRadius: BorderRadius.circular(16),
                    border: isToday
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isCurrentMonth ? Colors.white : Colors.white24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekView(
      List<Map<String, dynamic>> tutorias, Set<DateTime> diasConTutoria) {
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
              final isSelectable = diasConTutoria
                  .contains(DateTime(day.year, day.month, day.day));
              return Expanded(
                child: GestureDetector(
                  onTap: isSelectable
                      ? () => _showDayTutorias(day, tutorias, diasConTutoria)
                      : null,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelectable
                          ? (DateUtils.isSameDay(day, DateTime.now())
                              ? AppColors.lightBlueColor.withOpacity(0.35)
                              : AppColors.lightBlueColor.withOpacity(0.18))
                          : (DateUtils.isSameDay(day, DateTime.now())
                              ? Colors.blueAccent.withOpacity(0.13)
                              : Colors.white.withOpacity(0.04)),
                      borderRadius: BorderRadius.circular(16),
                      border: DateUtils.isSameDay(day, DateTime.now())
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    height: double.infinity,
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildDayView(List<Map<String, dynamic>> tutorias) {
    final tutoriasDelDia = tutorias
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
}
