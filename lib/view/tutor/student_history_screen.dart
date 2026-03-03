import 'package:flutter/material.dart';
import 'package:flutter_projects/view/layout/main_shell.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/booking_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/home/home_screen.dart';

class StudentHistoryScreen extends StatefulWidget {
  const StudentHistoryScreen({Key? key}) : super(key: key);
  @override
  State<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen> {
  String _selectedStatus = 'todas';
  DateTimeRange? _selectedRange;
  bool _orderDescending =
      true; // true: recientes primero, false: antiguas primero

  final List<Map<String, String>> _statusOptions = [
    {'label': 'Todas', 'value': 'todas'},
    {'label': 'Completada', 'value': 'completado'},
    {'label': 'Pendiente', 'value': 'pendiente'},
    {'label': 'Aceptada', 'value': 'aceptado'},
    {'label': 'Observada', 'value': 'observada'},
    {'label': 'Rechazada', 'value': 'rechazado'},
  ];

  Color _statusColor(String status) {
    switch (status) {
      case 'completado':
        return AppColors.primaryGreen;
      case 'pendiente':
        return AppColors.orangeprimary;
      case 'aceptado':
        return AppColors.lightBlueColor;
      case 'observada':
        return AppColors.yellowColor;
      case 'rechazado':
        return AppColors.redColor;
      default:
        return Colors.white24;
    }
  }

  List<Map<String, dynamic>> _applyFilters(
      List<Map<String, dynamic>> tutorias) {
    List<Map<String, dynamic>> filtered = List.from(tutorias);
    if (_selectedStatus != 'todas') {
      filtered = filtered
          .where((t) =>
              (t['status'] ?? '').toString().toLowerCase() == _selectedStatus)
          .toList();
    }
    if (_selectedRange != null) {
      filtered = filtered.where((t) {
        final d = t['date'] as DateTime;
        return d.isAfter(
                _selectedRange!.start.subtract(const Duration(days: 1))) &&
            d.isBefore(_selectedRange!.end.add(const Duration(days: 1)));
      }).toList();
    }
    filtered.sort((a, b) => _orderDescending
        ? (b['date'] as DateTime).compareTo(a['date'] as DateTime)
        : (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    return filtered;
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _selectedRange,
      locale: const Locale('es'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            dialogBackgroundColor: AppColors.backgroundColor,
            colorScheme: ColorScheme.dark(
              primary: AppColors.primaryGreen,
              surface: AppColors.darkBlue,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, _) {
        final tutorias = bookingProvider.bookings;
        final filteredTutorias = _applyFilters(tutorias);
        return Scaffold(
          backgroundColor: AppColors.darkBlue,
          appBar: AppBar(
            backgroundColor: AppColors.darkBlue,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => MainShell()),
                  (route) => false,
                );
              },
            ),
            title: const Text('Historial de Tutorías',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: Icon(
                  _orderDescending
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: Colors.white,
                ),
                tooltip: _orderDescending
                    ? 'Ordenar: Más recientes primero'
                    : 'Ordenar: Más antiguas primero',
                onPressed: () {
                  setState(() {
                    _orderDescending = !_orderDescending;
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  final authProvider =
                      Provider.of<BookingProvider>(context, listen: false);
                  bookingProvider.clear();
                  bookingProvider
                      .loadBookings(Provider.of(context, listen: false));
                },
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filtros
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _statusOptions.map((opt) {
                            final selected = _selectedStatus == opt['value'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(opt['label']!,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                selected: selected,
                                selectedColor: AppColors.lightBlueColor,
                                backgroundColor: AppColors.mediumGreyColor,
                                labelStyle: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : AppColors.lightBlueColor,
                                ),
                                onSelected: (_) {
                                  setState(() {
                                    _selectedStatus = opt['value']!;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon:
                          Icon(Icons.date_range, color: AppColors.primaryGreen),
                      tooltip: 'Filtrar por fecha',
                      onPressed: () => _pickDateRange(context),
                    ),
                    if (_selectedRange != null)
                      IconButton(
                        icon: Icon(Icons.clear, color: AppColors.redColor),
                        tooltip: 'Limpiar filtro de fecha',
                        onPressed: () {
                          setState(() {
                            _selectedRange = null;
                          });
                        },
                      ),
                  ],
                ),
              ),
              if (_selectedRange != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Del ${_selectedRange!.start.day.toString().padLeft(2, '0')}/${_selectedRange!.start.month.toString().padLeft(2, '0')}/${_selectedRange!.start.year} al ${_selectedRange!.end.day.toString().padLeft(2, '0')}/${_selectedRange!.end.month.toString().padLeft(2, '0')}/${_selectedRange!.end.year}',
                    style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              Expanded(
                child: bookingProvider.isLoading
                    ? Center(
                        child: Image.asset(
                          'assets/images/loading_tutorias.gif',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      )
                    : filteredTutorias.isEmpty
                        ? Center(
                            child: Text('No hay tutorías para mostrar',
                                style:
                                    TextStyle(color: AppColors.lightGreyColor)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            itemCount: filteredTutorias.length,
                            itemBuilder: (context, index) {
                              final t = filteredTutorias[index];
                              final statusColor = _statusColor(t['status']);
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.18),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.10),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                margin: const EdgeInsets.only(bottom: 14),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: statusColor,
                                        radius: 26,
                                        child: Icon(Icons.book,
                                            color: Colors.white, size: 26),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    t['title'] ?? 'Tutoría',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 17,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: statusColor
                                                        .withOpacity(0.18),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.circle,
                                                          color: statusColor,
                                                          size: 10),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${t['status'][0].toUpperCase()}${t['status'].substring(1)}',
                                                        style: TextStyle(
                                                          color: statusColor,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(Icons.calendar_today,
                                                    color: AppColors
                                                        .lightBlueColor,
                                                    size: 16),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '${t['date'].day.toString().padLeft(2, '0')}/${t['date'].month.toString().padLeft(2, '0')}/${t['date'].year}',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                Icon(Icons.access_time,
                                                    color: AppColors
                                                        .lightBlueColor,
                                                    size: 16),
                                                const SizedBox(width: 6),
                                                Text(
                                                  t['hour'],
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (t['description'] != null &&
                                                t['description']
                                                    .toString()
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                t['description'],
                                                style: TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 13,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
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
  }
}
