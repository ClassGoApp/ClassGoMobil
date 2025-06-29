import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class StudentHistoryScreen extends StatefulWidget {
  const StudentHistoryScreen({Key? key}) : super(key: key);

  @override
  State<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen> {
  String _selectedFilter = 'todas';
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

  List<Map<String, dynamic>> get _filteredTutorias {
    final sorted = List<Map<String, dynamic>>.from(_tutorias)
      ..sort((a, b) => b['date'].compareTo(a['date']));
    if (_selectedFilter == 'todas') return sorted;
    return sorted.where((t) => t['status'] == _selectedFilter).toList();
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
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filterCapsules.map((capsule) {
                    final isSelected = _selectedFilter == capsule['value'];
                    Color color = isSelected
                        ? AppColors.lightBlueColor
                        : Colors.white.withOpacity(0.08);
                    Color textColor =
                        isSelected ? Colors.white : Colors.white70;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilter = capsule['value'] as String;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(18),
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.lightBlueColor, width: 2)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.lightBlueColor
                                        .withOpacity(0.18),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          capsule['label'] as String,
                          style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredTutorias.isEmpty
                  ? Center(
                      child: Text(
                        'No hay tutorías para mostrar',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _filteredTutorias.length + 10,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      itemBuilder: (context, i) {
                        final t =
                            _filteredTutorias[i % _filteredTutorias.length];
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
