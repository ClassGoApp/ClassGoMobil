import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/tutorias_provider.dart';

class StudentHistoryScreen extends StatefulWidget {
  const StudentHistoryScreen({Key? key}) : super(key: key);

  @override
  State<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen> {
  String _selectedFilter = 'todas';
  String _selectedDateRange = 'todas';
  final ScrollController _scrollController = ScrollController();
  double _logoOpacity = 1.0;
  double _lastOffset = 0.0;

  final List<Map<String, dynamic>> _tutorias = [
    {
      'title': 'Física',
      'date': DateTime(2025, 6, 29, 15, 0),
      'hour': '15:00',
      'status': 'aceptada',
    },
    {
      'title': 'Inglés',
      'date': DateTime(2025, 6, 29, 12, 0),
      'hour': '12:00',
      'status': 'completada',
    },
    {
      'title': 'Matemáticas',
      'date': DateTime(2025, 6, 28, 10, 0),
      'hour': '10:00',
      'status': 'pendiente',
    },
    {
      'title': 'Química',
      'date': DateTime(2025, 6, 27, 17, 0),
      'hour': '17:00',
      'status': 'rechazada',
    },
    {
      'title': 'Historia',
      'date': DateTime(2025, 6, 26, 18, 0),
      'hour': '18:00',
      'status': 'observada',
    },
  ];

  final List<Map<String, dynamic>> _filterCapsules = [
    {'label': 'Todas', 'value': 'todas'},
    {'label': 'Completada', 'value': 'completada'},
    {'label': 'Pendiente', 'value': 'pendiente'},
    {'label': 'Aceptada', 'value': 'aceptada'},
    {'label': 'Observada', 'value': 'observada'},
    {'label': 'Rechazada', 'value': 'rechazada'},
  ];

  final List<Map<String, dynamic>> _dateRangeCapsules = [
    {'label': 'Todas', 'value': 'todas'},
    {'label': 'Hoy', 'value': 'hoy'},
    {'label': 'Ayer', 'value': 'ayer'},
    {'label': 'Semana pasada', 'value': 'semana_pasada'},
    {'label': 'Mes actual', 'value': 'mes_actual'},
    {'label': 'Mes pasado', 'value': 'mes_pasado'},
  ];

  List<Map<String, dynamic>> _applyFilters(
      List<Map<String, dynamic>> tutorias) {
    // Filtrar por estado (todas las variantes: masc/fem/español/inglés)
    List<Map<String, dynamic>> filtered = _selectedFilter == 'todas'
        ? tutorias
        : tutorias.where((t) {
            final status = (t['status'] ?? '').toString().toLowerCase();
            final filter = _selectedFilter.toLowerCase();
            if (filter == 'completada' ||
                filter == 'completado' ||
                filter == 'completed') {
              return status == 'completada' ||
                  status == 'completado' ||
                  status == 'completed';
            } else if (filter == 'pendiente' || filter == 'pending') {
              return status == 'pendiente' || status == 'pending';
            } else if (filter == 'aceptada' ||
                filter == 'aceptado' ||
                filter == 'accepted') {
              return status == 'aceptada' ||
                  status == 'aceptado' ||
                  status == 'accepted';
            } else if (filter == 'observada' ||
                filter == 'observado' ||
                filter == 'observed') {
              return status == 'observada' ||
                  status == 'observado' ||
                  status == 'observed';
            } else if (filter == 'rechazada' ||
                filter == 'rechazado' ||
                filter == 'rejected') {
              return status == 'rechazada' ||
                  status == 'rechazado' ||
                  status == 'rejected';
            } else {
              return status == filter;
            }
          }).toList();
    // Filtrar por rango de fechas
    final now = DateTime.now();
    if (_selectedDateRange == 'hoy') {
      filtered =
          filtered.where((t) => DateUtils.isSameDay(t['date'], now)).toList();
    } else if (_selectedDateRange == 'ayer') {
      final ayer = now.subtract(Duration(days: 1));
      filtered =
          filtered.where((t) => DateUtils.isSameDay(t['date'], ayer)).toList();
    } else if (_selectedDateRange == 'semana_pasada') {
      final start =
          now.subtract(Duration(days: now.weekday + 6)); // lunes semana pasada
      final end = start.add(Duration(days: 6)); // domingo semana pasada
      filtered = filtered.where((t) {
        final d = t['date'] as DateTime;
        return d.isAfter(start.subtract(const Duration(days: 1))) &&
            d.isBefore(end.add(const Duration(days: 1)));
      }).toList();
    } else if (_selectedDateRange == 'mes_actual') {
      filtered = filtered.where((t) {
        final d = t['date'] as DateTime;
        return d.year == now.year && d.month == now.month;
      }).toList();
    } else if (_selectedDateRange == 'mes_pasado') {
      final prevMonth = DateTime(now.year, now.month - 1, 1);
      filtered = filtered.where((t) {
        final d = t['date'] as DateTime;
        return d.year == prevMonth.year && d.month == prevMonth.month;
      }).toList();
    }
    // Ordenar SIEMPRE de más reciente a más antigua
    filtered.sort((a, b) => b['date'].compareTo(a['date']));
    return filtered;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completada':
        return AppColors.darkGreen;
      case 'pendiente':
        return AppColors.orangeprimary;
      case 'aceptada':
        return AppColors.lightBlueColor;
      case 'observada':
        return AppColors.yellowColor;
      case 'rechazada':
        return AppColors.redColor;
      default:
        return Colors.white24;
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      final tutoriasProvider =
          Provider.of<TutoriasProvider>(context, listen: false);
      tutoriasProvider.loadTutorias();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final direction = _scrollController.position.userScrollDirection;
    double newOpacity = _logoOpacity;
    if (offset <= 0) {
      newOpacity = 1.0;
    } else if (direction == ScrollDirection.reverse) {
      newOpacity = 0.0;
    } else if (direction == ScrollDirection.forward) {
      newOpacity = 1.0;
    }
    if ((newOpacity - _logoOpacity).abs() > 0.01) {
      setState(() {
        _logoOpacity = newOpacity;
      });
    }
    _lastOffset = offset;
  }

  @override
  Widget build(BuildContext context) {
    final tutoriasProvider = Provider.of<TutoriasProvider>(context);
    final _isLoading = tutoriasProvider.isLoading;

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

    final _tutorias = tutoriasProvider.tutorias;
    final filteredTutorias = _applyFilters(_tutorias);
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              height: _logoOpacity > 0.01 ? 28 : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                opacity: _logoOpacity,
                child: const Center(
                  child: Text(
                    'Historial de Tutorías',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.darkBlue.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila de filtros de fecha
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _dateRangeCapsules.map((capsule) {
                          final isSelected =
                              _selectedDateRange == capsule['value'];
                          Color color = isSelected
                              ? AppColors.lightBlueColor
                              : Colors.white.withOpacity(0.04);
                          Color borderColor = isSelected
                              ? AppColors.lightBlueColor
                              : Colors.white24;
                          Color textColor =
                              isSelected ? Colors.white : Colors.white70;
                          IconData? icon;
                          switch (capsule['value']) {
                            case 'hoy':
                              icon = Icons.today;
                              break;
                            case 'ayer':
                              icon = Icons.calendar_view_day;
                              break;
                            case 'semana_pasada':
                              icon = Icons.date_range;
                              break;
                            case 'mes_actual':
                              icon = Icons.calendar_month;
                              break;
                            case 'mes_pasado':
                              icon = Icons.history;
                              break;
                            default:
                              icon = Icons.all_inclusive;
                              break;
                          }
                          return AnimatedScale(
                            scale: isSelected ? 1.06 : 1.0,
                            duration: Duration(milliseconds: 150),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDateRange =
                                      capsule['value'] as String;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(colors: [
                                          AppColors.lightBlueColor,
                                          AppColors.primaryGreen
                                              .withOpacity(0.85)
                                        ])
                                      : null,
                                  color: !isSelected ? color : null,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: borderColor, width: 1.3),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.lightBlueColor
                                                .withOpacity(0.13),
                                            blurRadius: 5,
                                            spreadRadius: 0.5,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(icon, color: textColor, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      capsule['label'] as String,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 7),
                    // Fila de filtros de estado
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filterCapsules.map((capsule) {
                          final isSelected =
                              _selectedFilter == capsule['value'];
                          Color color = isSelected
                              ? AppColors.primaryGreen
                              : Colors.white.withOpacity(0.04);
                          Color borderColor = isSelected
                              ? AppColors.primaryGreen
                              : Colors.white24;
                          Color textColor =
                              isSelected ? Colors.white : Colors.white70;
                          return AnimatedScale(
                            scale: isSelected ? 1.06 : 1.0,
                            duration: Duration(milliseconds: 150),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedFilter = capsule['value'] as String;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(colors: [
                                          AppColors.primaryGreen,
                                          AppColors.lightBlueColor
                                              .withOpacity(0.85)
                                        ])
                                      : null,
                                  color: !isSelected ? color : null,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: borderColor, width: 1.3),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primaryGreen
                                                .withOpacity(0.13),
                                            blurRadius: 5,
                                            spreadRadius: 0.5,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Text(
                                  capsule['label'] as String,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filteredTutorias.isEmpty
                  ? Center(
                      child: Text(
                        'No hay tutorías para mostrar',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredTutorias.length,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      itemBuilder: (context, i) {
                        final t = filteredTutorias[i];
                        final Color accent = _statusColor(t['status']);
                        return Card(
                          color: AppColors.darkBlue.withOpacity(0.92),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.lightBlueColor,
                              child: Icon(Icons.book, color: Colors.white),
                            ),
                            title: Text(
                              t['title'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(
                                  '${_formatDate(t['date'])} - ${t['hour']}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Text(
                                      'Estado: ',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '${t['status'][0].toUpperCase()}${t['status'].substring(1)}',
                                      style: TextStyle(
                                        color: accent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
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
      ),
    );
  }
}
