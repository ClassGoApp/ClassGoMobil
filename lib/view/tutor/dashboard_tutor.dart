import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_projects/view/components/tutor_card.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/tutor_subjects_provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/view/tutor/add_subject_modal.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/helpers/pusher_service.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

// --- Widget reutilizable para tarjetas de tiempo libre ---
class FreeTimeSlotCard extends StatelessWidget {
  final String startTime;
  final String endTime;
  final String? description;
  final VoidCallback? onDelete;
  final bool isPreview;

  const FreeTimeSlotCard({
    Key? key,
    required this.startTime,
    required this.endTime,
    this.description,
    this.onDelete,
    this.isPreview = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkBlue.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.lightBlueColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lightBlueColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.access_time,
              color: AppColors.lightBlueColor,
              size: 18,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$startTime - $endTime',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (description != null && description!.isNotEmpty)
                  Text(
                    description!,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (onDelete != null)
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.redColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: AppColors.redColor,
                  size: 16,
                ),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- Tarjeta de tutoría al estilo UpcomingSessionBanner ---
class _TutorUpcomingSessionCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  const _TutorUpcomingSessionCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime.tryParse(booking['start_time'] ?? '') ?? now;
    final end = DateTime.tryParse(booking['end_time'] ?? '') ?? now;
    final status = (booking['status'] ?? '').toString().trim().toLowerCase();
    final isAceptado = status == 'aceptada' || status == 'aceptado';
    final isRechazado = status == 'rechazada' || status == 'rechazado';
    final isLive = now.isAfter(start) && now.isBefore(end);
    final isSoon = !isLive && start.isAfter(now);
    final subject = booking['subject_name'] ?? 'Tutoría';
    final hourStr =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

    String mainText = '';
    String lottieAsset = '';
    Color color = Colors.blueAccent.withOpacity(0.85);
    Color textColor = Colors.white;

    if (isRechazado) {
      mainText = 'Tutoría rechazada';
      lottieAsset =
          'https://assets2.lottiefiles.com/packages/lf20_4kx2q32n.json';
      color = Colors.grey.withOpacity(0.85);
      textColor = Colors.white;
    } else if (status == 'pendiente' || status == 'solicitada') {
      mainText = 'Pendiente de aceptación';
      lottieAsset =
          'https://assets2.lottiefiles.com/packages/lf20_4kx2q32n.json';
      color = Colors.orangeAccent.withOpacity(0.95);
      textColor = Colors.black;
    } else if (isAceptado && isLive) {
      mainText = 'EN VIVO';
      lottieAsset =
          'https://assets2.lottiefiles.com/packages/lf20_30305_back_to_school.json';
      color = Colors.redAccent.withOpacity(0.85);
      textColor = Colors.white;
    } else if (isAceptado && isSoon) {
      mainText = 'Próxima tutoría';
      lottieAsset =
          'https://assets2.lottiefiles.com/packages/lf20_30305_back_to_school.json';
      color = Colors.blueAccent.withOpacity(0.85);
      textColor = Colors.white;
    } else if (isLive) {
      mainText = 'En horario, pero no aceptada';
      lottieAsset =
          'https://assets2.lottiefiles.com/packages/lf20_4kx2q32n.json';
      color = Colors.amber.withOpacity(0.95);
      textColor = Colors.black;
    } else {
      mainText = 'Tutoría programada para hoy';
      lottieAsset =
          'https://assets2.lottiefiles.com/packages/lf20_30305_back_to_school.json';
      color = Colors.blueGrey.withOpacity(0.85);
      textColor = Colors.white;
    }

    String statusText = 'Estado: ${booking['status'] ?? ''}';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [color, Colors.white.withOpacity(0.10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.18),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Lottie.network(
              lottieAsset,
              width: 36,
              height: 36,
              repeat: true,
              animate: true,
              options: LottieOptions(enableMergePaths: true),
              errorBuilder: (context, error, stackTrace) {
                final visibleColor = Colors.white;
                if (isLive && isAceptado) {
                  return Icon(Icons.play_circle_fill,
                      color: visibleColor, size: 32);
                } else if (isLive && !isAceptado) {
                  return Icon(Icons.warning_amber_rounded,
                      color: Colors.amber, size: 32);
                } else if (isSoon &&
                    (status == 'pendiente' || status == 'solicitada')) {
                  return Icon(Icons.warning_amber_rounded,
                      color: Colors.orangeAccent, size: 32);
                } else if (isSoon && isAceptado) {
                  return Icon(Icons.schedule, color: visibleColor, size: 32);
                } else if (isRechazado) {
                  return Icon(Icons.cancel, color: Colors.grey, size: 32);
                } else {
                  return Icon(Icons.school, color: visibleColor, size: 32);
                }
              },
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mainText,
                  style: TextStyle(
                    color: color.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  subject,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  hourStr,
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  statusText,
                  style: TextStyle(
                    color: textColor.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Tarjeta de próxima tutoría estilo PedidosYa ---
class TutorBookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  const TutorBookingCard({required this.booking});

  Color _statusColor(String status) {
    switch (status) {
      case 'aceptada':
      case 'aceptado':
        return AppColors.lightBlueColor;
      case 'en vivo':
        return Colors.redAccent;
      case 'completada':
        return AppColors.primaryGreen;
      case 'rechazada':
      case 'rechazado':
        return AppColors.redColor;
      case 'pendiente':
      case 'solicitada':
        return AppColors.orangeprimary;
      default:
        return AppColors.mediumGreyColor;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'aceptada':
      case 'aceptado':
        return Icons.check_circle_outline;
      case 'en vivo':
        return Icons.play_circle_fill;
      case 'completada':
        return Icons.verified;
      case 'rechazada':
      case 'rechazado':
        return Icons.cancel;
      case 'pendiente':
      case 'solicitada':
        return Icons.access_time;
      default:
        return Icons.info_outline;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'aceptada':
      case 'aceptado':
        return 'Aceptada';
      case 'en vivo':
        return 'En Vivo';
      case 'completada':
        return 'Completada';
      case 'rechazada':
      case 'rechazado':
        return 'Rechazada';
      case 'pendiente':
      case 'solicitada':
        return 'Pendiente';
      default:
        return 'Programada';
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime.tryParse(booking['start_time'] ?? '') ?? now;
    final end = DateTime.tryParse(booking['end_time'] ?? '') ?? now;
    final status = (booking['status'] ?? '').toString().trim().toLowerCase();
    final subject = booking['subject_name'] ?? 'Tutoría';
    final student = booking['student_name'] ?? 'Estudiante';
    final hourStr =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    final dateStr =
        '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year}';
    final Color barColor = _statusColor(status);
    final String statusText = _statusText(status);
    final IconData statusIcon = _statusIcon(status);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Card(
              elevation: 8,
              margin: EdgeInsets.only(bottom: 22),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26)),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.darkBlue, AppColors.backgroundColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: barColor.withOpacity(0.18),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barra de estado
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(26)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icono grande de estado
                          Container(
                            decoration: BoxDecoration(
                              color: barColor.withOpacity(0.13),
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(16),
                            child: Icon(statusIcon, color: barColor, size: 38),
                          ),
                          SizedBox(width: 18),
                          // Info principal
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(subject,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20)),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: barColor.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.circle,
                                              color: barColor, size: 10),
                                          SizedBox(width: 4),
                                          Text(statusText,
                                              style: TextStyle(
                                                  color: barColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Icon(Icons.person,
                                        color: Colors.white70, size: 18),
                                    SizedBox(width: 4),
                                    Text(student,
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        color: AppColors.lightBlueColor,
                                        size: 16),
                                    SizedBox(width: 6),
                                    Text(dateStr,
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w500)),
                                    SizedBox(width: 14),
                                    Icon(Icons.access_time,
                                        color: AppColors.lightBlueColor,
                                        size: 16),
                                    SizedBox(width: 6),
                                    Text(hourStr,
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 20, bottom: 16, top: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: barColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Text('Ver detalles',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class DashboardTutor extends StatefulWidget {
  @override
  _DashboardTutorState createState() => _DashboardTutorState();
}

class _DashboardTutorState extends State<DashboardTutor> {
  bool isAvailable = false;
  List<Map<String, String>> freeTimes = [
    {'day': 'Lunes', 'start': '14:00', 'end': '16:00'},
    {'day': 'Miércoles', 'start': '10:00', 'end': '12:00'},
  ]; // Placeholder

  // Para el calendario de tiempos libres
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, String>>> freeTimesByDay = {};
  List<Map<String, dynamic>> _availableSlots = [];
  bool _isLoadingSlots = false;

  // Para las tutorías del tutor
  List<Map<String, dynamic>> _tutorBookings = [];
  bool _isLoadingBookings = true;
  AuthProvider? _authProvider;

  // Para la imagen de perfil del tutor
  String? _profileImageUrl;
  bool _isLoadingProfileImage = false;

  // Variables para el slider de disponibilidad
  double _sliderDragOffset = 0.0;
  bool _isSliderDragging = false;

  // Método para calcular la posición del slider cuando está en modo online
  double _calculateSliderPosition() {
    // Usar un valor fijo que funcione bien en la mayoría de dispositivos
    // En lugar de calcular dinámicamente para evitar errores de layout
    // Este valor debe ser consistente para evitar conflictos de layout
    return 300.0; // Posición fija a la derecha, ajustada para posicionar correctamente
  }

  @override
  void initState() {
    super.initState();
    // Simular tiempos libres agrupados por día
    for (var ft in freeTimes) {
      final now = DateTime.now();
      final day = ft['day'] == 'Lunes'
          ? DateTime(now.year, now.month, now.day - now.weekday + 1)
          : ft['day'] == 'Miércoles'
              ? DateTime(now.year, now.month, now.day - now.weekday + 3)
              : now;
      freeTimesByDay.putIfAbsent(day, () => []).add(ft);
    }

    // Cargar materias del tutor
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final subjectsProvider =
        Provider.of<TutorSubjectsProvider>(context, listen: false);

    print('🔍 DEBUG - Cargando datos iniciales...');
    await subjectsProvider.loadTutorSubjects(authProvider);
    print('🔍 DEBUG - Materias cargadas inicialmente');

    _loadAvailableSlots();
    _fetchTutorBookings();
    _loadProfileImage();
  }

  Future<void> _loadAvailableSlots() async {
    setState(() {
      _isLoadingSlots = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token != null && authProvider.userId != null) {
        final response = await getTutorAvailableSlots(
          authProvider.token!,
          authProvider.userId!.toString(),
        );

        if (response['status'] == 200 && response['data'] != null) {
          final List<dynamic> slotsData = response['data'] as List<dynamic>;
          setState(() {
            _availableSlots = slotsData.cast<Map<String, dynamic>>();
            _updateFreeTimesByDay();
          });
        } else {
          setState(() {
            _availableSlots = [];
            _updateFreeTimesByDay();
          });
        }
      }
    } catch (e) {
      print('Error loading available slots: $e');
    } finally {
      setState(() {
        _isLoadingSlots = false;
      });
    }
  }

  // Método para cargar las tutorías del tutor
  Future<void> _fetchTutorBookings() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.userId;

      if (token != null && userId != null) {
        final bookings = await getUserBookingsById(token, userId);
        print('Tutorías obtenidas para el tutor: ${bookings.length}');

        // Imprimir detalles de cada tutoría para debug
        // print('🔍 DEBUG - Detalles de todas las tutorías:');
        // for (int i = 0; i < bookings.length; i++) {
        //   final booking = bookings[i];
        //   print('📋 Tutoría $i:');
        //   print('   ID: ${booking['id']}');
        //   print('   Estado: ${booking['status']}');
        //   print('   Meeting Link: "${booking['meeting_link']}"');
        //   print('   Subject: ${booking['subject_name']}');
        //   print('   Student: ${booking['student_name']}');
        //   print('   Start Time: ${booking['start_time']}');
        //   print('   End Time: ${booking['end_time']}');
        //   print('   ---');
        // }

        // Filtrar solo tutorías con estado "aceptado" en adelante
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        _tutorBookings = bookings.where((b) {
          final status = (b['status'] ?? '').toString().toLowerCase();
          final start = DateTime.tryParse(b['start_time'] ?? '') ?? now;

          // Solo mostrar tutorías aceptadas, en curso, completadas, etc.
          final isAcceptedOrHigher = status == 'aceptado' ||
              status == 'aceptada' ||
              status == 'cursando' ||
              status == 'completada' ||
              status == 'completado';

          // Solo mostrar tutorías de hoy o futuras
          final isTodayOrFuture = start.year == today.year &&
              start.month == today.month &&
              start.day >= today.day;

          return isAcceptedOrHigher && isTodayOrFuture;
        }).toList();

        print('Tutorías filtradas para el tutor: ${_tutorBookings.length}');

        // Imprimir detalles de las tutorías filtradas
        // print('🔍 DEBUG - Tutorías filtradas:');
        // for (int i = 0; i < _tutorBookings.length; i++) {
        //   final booking = _tutorBookings[i];
        //   print('📋 Tutoría filtrada $i:');
        //   print('   ID: ${booking['id']}');
        //   print('   Subject: ${booking['subject_name']}');
        //   print('   Student: ${booking['student_name']}');
        //   print('   Start Time: ${booking['start_time']}');
        //   print('   End Time: ${booking['end_time']}');
        //   print('   ---');
        // }
      }
    } catch (e) {
      print('Error al obtener tutorías del tutor: $e');
      _tutorBookings = [];
    }

    setState(() {
      _isLoadingBookings = false;
    });
  }

  // Método para cargar la imagen de perfil del tutor
  Future<void> _loadProfileImage() async {
    try {
      setState(() {
        _isLoadingProfileImage = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.userId;

      if (token != null && userId != null) {
        final response = await getUserProfileImage(token, userId);

        if (response['success'] == true && response['data'] != null) {
          final profileData = response['data'];
          final profileImageUrl = profileData['profile_image'];

          if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
            setState(() {
              _profileImageUrl = profileImageUrl;
            });
          }
        }
      }
    } catch (e) {
      print('Error al cargar la imagen de perfil: $e');
    } finally {
      setState(() {
        _isLoadingProfileImage = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    if (_authProvider != authProvider) {
      _authProvider = authProvider;
      _checkAndFetchBookings();
      _authProvider!.addListener(_checkAndFetchBookings);
    }

    // Configurar eventos de Pusher para el tutor
    final pusherService = Provider.of<PusherService>(context, listen: false);
    print('🎯 Configurando callback de Pusher en DashboardTutor');
    pusherService.init(
      onSlotBookingStatusChanged: (data) {
        print('📡 Evento del canal recibido en DashboardTutor: $data');

        try {
          // Parsear el JSON del evento
          Map<String, dynamic> eventData;
          if (data is String) {
            eventData = json.decode(data);
          } else if (data is Map<String, dynamic>) {
            eventData = data;
          } else {
            print('❌ Formato de data no válido');
            return;
          }

          // Obtener el tutor_id del evento
          final int? eventTutorId = eventData['tutor_id'];

          // Obtener el ID del usuario logueado
          final int? currentUserId =
              Provider.of<AuthProvider>(context, listen: false).userId;

          print(
              '🔍 Comparando: tutor_id del evento: $eventTutorId, usuario logueado: $currentUserId');

          // Verificar si el evento es para el tutor logueado
          if (eventTutorId != null &&
              currentUserId != null &&
              eventTutorId == currentUserId) {
            print(
                '✅ Evento relevante para este tutor, actualizando estado de tutoría...');

            // Extraer información del evento
            final int? slotBookingId = eventData['slotBookingId'];
            final String? newStatus = eventData['newStatus'];

            print(
                '🔄 Actualizando tutoría ID: $slotBookingId al estado: $newStatus');

            // Actualizar el estado de la tutoría en la lista local
            setState(() {
              for (int i = 0; i < _tutorBookings.length; i++) {
                if (_tutorBookings[i]['id'] == slotBookingId) {
                  _tutorBookings[i]['status'] = newStatus;
                  print('✅ Tutoría actualizada en la lista local del tutor');
                  break;
                }
              }
            });

            // Refrescar las tutorías para asegurar que se muestren las nuevas
            _fetchTutorBookings();
          } else {
            print('⏩ Evento ignorado (no es para este tutor)');
          }
        } catch (e) {
          print('❌ Error procesando evento: $e');
        }
      },
      context: context,
    );
  }

  void _checkAndFetchBookings() {
    if (_authProvider?.token != null && _authProvider?.userId != null) {
      _fetchTutorBookings();
    }
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_checkAndFetchBookings);
    super.dispose();
  }

  String _formatTimeString(String timeStr) {
    if (timeStr.isEmpty) return '';

    try {
      // Si ya está en formato HH:mm, devolverlo tal como está
      if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(timeStr)) {
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      }

      // Si es formato ISO datetime completo
      if (timeStr.contains('T') && timeStr.contains('Z')) {
        final dateTime = DateTime.tryParse(timeStr);
        if (dateTime != null) {
          return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
        }
      }

      // Si es solo fecha con hora
      final dateTime = DateTime.tryParse(timeStr);
      if (dateTime != null) {
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      }

      return timeStr;
    } catch (e) {
      print('Error formatting time: $e for string: $timeStr');
      return timeStr;
    }
  }

  void _updateFreeTimesByDay() {
    freeTimesByDay.clear();

    for (var slot in _availableSlots) {
      final dateStr = slot['date'];
      if (dateStr != null) {
        final date = DateTime.tryParse(dateStr);
        if (date != null) {
          final day = DateTime(date.year, date.month, date.day);

          final formattedStart = _formatTimeString(slot['start_time'] ?? '');
          final formattedEnd = _formatTimeString(slot['end_time'] ?? '');

          print(
              'DEBUG - Original times: ${slot['start_time']} - ${slot['end_time']}');
          print('DEBUG - Formatted times: $formattedStart - $formattedEnd');

          freeTimesByDay.putIfAbsent(day, () => []).add({
            'start': formattedStart,
            'end': formattedEnd,
            'id': slot['id']?.toString() ?? '',
            'description': slot['description'] ?? '',
          });
        }
      }
    }
  }

  void _showAvailabilityDialog(bool newValue) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkBlue.withOpacity(0.98),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: newValue
                        ? AppColors.primaryGreen.withOpacity(0.15)
                        : AppColors.redColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(18),
                  child: Icon(
                    newValue
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    color:
                        newValue ? AppColors.primaryGreen : AppColors.redColor,
                    size: 48,
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  newValue
                      ? '¿Habilitar disponibilidad?'
                      : '¿Deshabilitar disponibilidad?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  newValue
                      ? 'Al habilitar esta opción, los usuarios podrán encontrarte y asignarte nuevas tutorías en cualquier momento. ¡Asegúrate de estar listo para recibir solicitudes!'
                      : 'Al deshabilitar esta opción, dejarás de estar disponible para ser escogido por los usuarios. No recibirás nuevas solicitudes de tutoría hasta que vuelvas a habilitarte.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white70, fontSize: 16, height: 1.5),
                ),
                SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side:
                              BorderSide(color: AppColors.redColor, width: 1.2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('Cancelar',
                            style: TextStyle(
                                color: AppColors.redColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: newValue
                              ? AppColors.primaryGreen
                              : AppColors.redColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          setState(() {
                            isAvailable = newValue;
                          });
                          Navigator.of(context).pop();
                        },
                        child: Text('Confirmar',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddSubjectModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSubjectModal(),
    );
  }

  void _deleteSubject(int subjectId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBlue,
        title: Text(
          'Eliminar materia',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar esta materia?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final subjectsProvider =
                  Provider.of<TutorSubjectsProvider>(context, listen: false);

              final success = await subjectsProvider.deleteTutorSubjectFromApi(
                authProvider,
                subjectId,
              );

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Materia eliminada exitosamente'),
                    backgroundColor: AppColors.primaryGreen,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(subjectsProvider.error ??
                        'Error al eliminar la materia'),
                    backgroundColor: AppColors.redColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redColor,
            ),
            child: Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFreeTimeModal() async {
    DateTime selectedDay = DateTime.now();
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    List<Map<String, dynamic>> tempFreeTimes = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 32,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.darkBlue,
                    AppColors.darkBlue.withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header del modal
                  Center(
                    child: Container(
                      width: 50,
                      height: 6,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Título con ícono
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryGreen,
                              AppColors.orangeprimary
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.schedule,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Agregar Tiempo Libre',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              'Gestiona tu disponibilidad',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),
                  // Selector de día mejorado
                  _buildTimeSelector(
                    context: context,
                    label: 'Día',
                    icon: Icons.calendar_today,
                    time: null,
                    onTimeSelected: (time) {}, // No se usa para día
                    setModalState: setModalState,
                    isDateSelector: true,
                    selectedDate: selectedDay,
                    onDateSelected: (date) {
                      setModalState(() {
                        selectedDay = date;
                      });
                    },
                  ),
                  SizedBox(height: 20),

                  // Selector de hora inicio mejorado
                  _buildTimeSelector(
                    context: context,
                    label: 'Hora de Inicio',
                    icon: Icons.play_arrow,
                    time: startTime,
                    onTimeSelected: (time) {
                      setModalState(() {
                        startTime = time;
                      });
                    },
                    setModalState: setModalState,
                  ),
                  SizedBox(height: 20),

                  // Selector de hora fin mejorado
                  _buildTimeSelector(
                    context: context,
                    label: 'Hora de Fin',
                    icon: Icons.stop,
                    time: endTime,
                    onTimeSelected: (time) {
                      setModalState(() {
                        endTime = time;
                      });
                    },
                    setModalState: setModalState,
                    initialTime: startTime,
                  ),
                  SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryGreen,
                          AppColors.primaryGreen.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: (startTime != null && endTime != null)
                          ? () {
                              setModalState(() {
                                tempFreeTimes.add({
                                  'day': selectedDay,
                                  'start': startTime!,
                                  'end': endTime!,
                                });
                                startTime = null;
                                endTime = null;
                              });
                            }
                          : null,
                      icon: Icon(Icons.add_circle_outline,
                          color: Colors.white, size: 18),
                      label: Text(
                        'Agregar a la Lista',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  if (tempFreeTimes.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.list_alt,
                                color: AppColors.primaryGreen,
                                size: 18,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Tiempos Libres a Agregar:',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        ...tempFreeTimes.asMap().entries.map((entry) {
                          final i = entry.key;
                          final ft = entry.value;
                          final day = ft['day'] as DateTime;
                          final start = ft['start'] as TimeOfDay;
                          final end = ft['end'] as TimeOfDay;
                          return FreeTimeSlotCard(
                            startTime:
                                '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
                            endTime:
                                '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                            description:
                                '${DateFormat('EEEE, d MMM', 'es').format(day)}',
                            onDelete: () {
                              setModalState(() {
                                tempFreeTimes.removeAt(i);
                              });
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.orangeprimary,
                          AppColors.orangeprimary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orangeprimary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: tempFreeTimes.isNotEmpty
                          ? () async {
                              Navigator.of(context).pop();
                              await _createSlots(tempFreeTimes);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.save_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Guardar Horarios',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
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

  Future<void> _createSlots(List<Map<String, dynamic>> tempFreeTimes) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token == null || authProvider.userId == null) return;

      int successCount = 0;
      int errorCount = 0;

      for (var ft in tempFreeTimes) {
        final day = ft['day'] as DateTime;
        final start = ft['start'] as TimeOfDay;
        final end = ft['end'] as TimeOfDay;

        // Calcular la duración en minutos
        final startMinutes = start.hour * 60 + start.minute;
        final endMinutes = end.hour * 60 + end.minute;
        final duration = endMinutes - startMinutes;

        final slotData = {
          'user_id': authProvider.userId,
          'start_time':
              '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
          'end_time':
              '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
          'date':
              '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
          'duracion': duration,
        };

        final response =
            await createUserSubjectSlot(authProvider.token!, slotData);

        if (response['success'] == true) {
          print('Slot creado exitosamente: ${response['data']}');
          successCount++;
        } else {
          print('Error creando slot: ${response['message']}');
          errorCount++;
        }
      }

      // Recargar los slots después de crear
      await _loadAvailableSlots();

      // Mostrar mensaje apropiado
      if (successCount > 0 && errorCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '$successCount tiempo(s) libre(s) agregado(s) exitosamente'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      } else if (successCount > 0 && errorCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount creado(s), $errorCount error(es)'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear los tiempos libres'),
            backgroundColor: AppColors.redColor,
          ),
        );
      }
    } catch (e) {
      print('Error creating slots: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión al agregar tiempos libres'),
          backgroundColor: AppColors.redColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final String tutorName = authProvider.userName;
        final int completedSessions = 12; // Placeholder
        final int upcomingSessions = 2; // Placeholder
        final double rating = 4.8; // Placeholder

        return Scaffold(
          backgroundColor: AppColors.darkBlue,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado mejorado con toggle de visibilidad
                  _buildHeader(tutorName, rating, completedSessions),
                  SizedBox(height: 24),

                  // Botón deslizante de disponibilidad
                  _buildAvailabilitySlider(),
                  SizedBox(height: 24),

                  // Tarjeta de acciones rápidas
                  _buildQuickActionsCard(),
                  SizedBox(height: 24),

                  // Sección de tutorías del tutor
                  _buildTutorBookingsSection(),
                  SizedBox(height: 24),

                  // Sección de materias con chips
                  _buildSubjectsSection(),
                  SizedBox(height: 24),

                  // Sección unificada de disponibilidad
                  _buildAvailabilitySection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Widgets auxiliares ---

  // Botón deslizante de disponibilidad
  Widget _buildAvailabilitySlider() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.darkBlue.withOpacity(0.9),
            AppColors.darkBlue.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Título y estado
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isAvailable ? Icons.visibility : Icons.visibility_off,
                color: isAvailable
                    ? AppColors.primaryGreen
                    : AppColors.orangeprimary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                isAvailable ? 'Disponible para tutorías' : 'Modo offline',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Barra deslizante tipo toggle
          Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isAvailable
                  ? AppColors.primaryGreen.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isAvailable
                    ? AppColors.primaryGreen.withOpacity(0.4)
                    : Colors.grey.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                // Fondo de progreso
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: isAvailable ? double.infinity : 0,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),

                // Botón deslizante
                AnimatedPositioned(
                  duration: Duration(milliseconds: 50),
                  curve: Curves.easeOut,
                  left: _isSliderDragging
                      ? _sliderDragOffset
                      : (isAvailable ? _calculateSliderPosition() : 0),
                  right: null, // Nunca usar right para evitar conflictos
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _isSliderDragging = true;
                      });
                    },
                    onPanUpdate: (details) {
                      // Actualizar posición en tiempo real con setState optimizado
                      final RenderBox renderBox =
                          context.findRenderObject() as RenderBox;
                      final localPosition =
                          renderBox.globalToLocal(details.globalPosition);
                      final containerWidth = renderBox.size.width;

                      // Calcular posición del drag (0 a containerWidth - 50)
                      double newOffset = (localPosition.dx - 25)
                          .clamp(0.0, containerWidth - 50);

                      // Solo actualizar si la posición cambió significativamente
                      // Aumentar el umbral para reducir setState calls
                      if ((newOffset - _sliderDragOffset).abs() > 8.0) {
                        setState(() {
                          _sliderDragOffset = newOffset;
                        });
                      }
                    },
                    onPanEnd: (details) {
                      // Cambiar estado al final del deslizamiento
                      final RenderBox renderBox =
                          context.findRenderObject() as RenderBox;
                      final localPosition =
                          renderBox.globalToLocal(details.globalPosition);
                      final containerWidth = renderBox.size.width;

                      if (localPosition.dx > containerWidth * 0.5 &&
                          !isAvailable) {
                        // Vibración de feedback
                        HapticFeedback.lightImpact();
                        setState(() {
                          isAvailable = true;
                          _isSliderDragging = false;
                        });
                        _sliderDragOffset = 0.0; // Resetear offset
                      } else if (localPosition.dx < containerWidth * 0.5 &&
                          isAvailable) {
                        // Vibración de feedback
                        HapticFeedback.lightImpact();
                        setState(() {
                          isAvailable = false;
                          _isSliderDragging = false;
                        });
                        _sliderDragOffset = 0.0; // Resetear offset
                      } else {
                        // Si no se completó el deslizamiento, volver a la posición original
                        setState(() {
                          _isSliderDragging = false;
                        });
                        _sliderDragOffset = 0.0; // Resetear offset
                      }
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color:
                            isAvailable ? AppColors.primaryGreen : Colors.grey,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        isAvailable ? Icons.check : Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),

                // Texto de instrucción
                Positioned.fill(
                  child: Center(
                    child: Text(
                      isAvailable ? 'Disponible' : 'Offline',
                      style: TextStyle(
                        color:
                            isAvailable ? AppColors.primaryGreen : Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Animación de flechas
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isAvailable) ...[
                Icon(
                  Icons.arrow_forward,
                  color: AppColors.primaryGreen,
                  size: 14,
                ),
                SizedBox(width: 4),
                Text(
                  'Desliza para activar',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                Text(
                  'Desliza para desactivar',
                  style: TextStyle(
                    color: AppColors.orangeprimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_back,
                  color: AppColors.orangeprimary,
                  size: 14,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Encabezado mejorado con toggle de visibilidad
  Widget _buildHeader(String tutorName, double rating, int completedSessions) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen, Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _profileImageUrl != null && !_isLoadingProfileImage
              ? CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: _profileImageUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 56,
                        height: 56,
                        color: Colors.white.withOpacity(0.2),
                        child:
                            Icon(Icons.person, color: Colors.white, size: 32),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 56,
                        height: 56,
                        color: Colors.white.withOpacity(0.2),
                        child:
                            Icon(Icons.person, color: Colors.white, size: 32),
                      ),
                    ),
                  ),
                )
              : CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: _isLoadingProfileImage
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.person, color: Colors.white, size: 32),
                ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, $tutorName!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, color: AppColors.starYellow, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '$rating',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.check_circle, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '$completedSessions sesiones',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Botón de cerrar sesión
          // Botón de cerrar sesión
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () => _showLogoutDialog(),
              icon: Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 18,
              ),
              tooltip: 'Cerrar sesión',
              padding: EdgeInsets.all(6),
              constraints: BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta de acciones rápidas
  Widget _buildQuickActionsCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.darkBlue.withOpacity(0.9),
            AppColors.darkBlue.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.lightBlueColor.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.lightBlueColor, AppColors.primaryGreen],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.flash_on,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Acciones Rápidas',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 0,
            childAspectRatio: 1.2,
            children: [
              _buildQuickActionButton(
                'Gestionar\nMaterias',
                Icons.auto_stories,
                [AppColors.primaryGreen, Color(0xFF4CAF50)],
                () => _showAddSubjectModal(),
              ),
              _buildQuickActionButton(
                'Definir\nHorarios',
                Icons.access_time_filled,
                [AppColors.orangeprimary, Color(0xFFFF7043)],
                () => _showAddFreeTimeModal(),
              ),
              _buildQuickActionButton(
                'Mis\nTutorías',
                Icons.video_camera_front,
                [AppColors.lightBlueColor, Color(0xFF42A5F5)],
                () {
                  // TODO: Navegar a tutorías asignadas
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
      String title, IconData icon, List<Color> colors, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors[0].withOpacity(0.2),
                colors[1].withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors[0].withOpacity(0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colors[0].withOpacity(0.1),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: colors[0].withOpacity(0.3),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              SizedBox(height: 8),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Sección de materias con chips
  Widget _buildSubjectsSection() {
    return Consumer<TutorSubjectsProvider>(
      builder: (context, subjectsProvider, child) {
        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.darkBlue.withOpacity(0.8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.primaryGreen.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mis Materias (${subjectsProvider.subjects.length})',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddSubjectModal(),
                    icon: Icon(Icons.add, color: Colors.white, size: 16),
                    label: Text('Añadir',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              if (subjectsProvider.isLoading)
                Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else if (subjectsProvider.subjects.isEmpty)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No tienes materias agregadas. ¡Añade tu primera materia para empezar!',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: subjectsProvider.subjects.map((subject) {
                    return Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.school,
                            color: AppColors.primaryGreen,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            subject.subject.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _deleteSubject(subject.id),
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppColors.redColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: AppColors.redColor,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  // Sección unificada de disponibilidad
  Widget _buildAvailabilitySection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkBlue.withOpacity(0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.orangeprimary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mi Calendario de Horarios',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddFreeTimeModal(),
                icon: Icon(Icons.add, color: Colors.white, size: 16),
                label: Text('Añadir',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orangeprimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildInteractiveCalendar(),
        ],
      ),
    );
  }

  Widget _buildInteractiveCalendar() {
    final daysInMonth =
        DateUtils.getDaysInMonth(_focusedDay.year, _focusedDay.month);
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final weekDayOffset = firstDayOfMonth.weekday - 1;
    final days = List.generate(daysInMonth,
        (i) => DateTime(_focusedDay.year, _focusedDay.month, i + 1));
    final weekDays = List.generate(
        7, (i) => DateFormat.E('es').dateSymbols.STANDALONESHORTWEEKDAYS[i]);

    return Column(
      children: [
        // Navegación del calendario
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, color: Colors.white),
              onPressed: () {
                setState(() {
                  _focusedDay =
                      DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                });
              },
            ),
            Text(
              DateFormat('MMMM yyyy', 'es').format(_focusedDay).toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, color: Colors.white),
              onPressed: () {
                setState(() {
                  _focusedDay =
                      DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                });
              },
            ),
          ],
        ),
        SizedBox(height: 8),

        // Días de la semana
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekDays
              .map((d) => Text(
                    d[0],
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.bold),
                  ))
              .toList(),
        ),
        SizedBox(height: 4),

        // Grilla del calendario
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.1,
          ),
          itemCount: daysInMonth + weekDayOffset,
          itemBuilder: (context, i) {
            if (i < weekDayOffset) return SizedBox.shrink();
            final day = days[i - weekDayOffset];
            final hasFreeTime =
                freeTimesByDay.keys.any((d) => DateUtils.isSameDay(d, day));

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDay = day;
                });
                if (hasFreeTime) {
                  _showFreeTimesForDay(day);
                } else {
                  _showAddTimeForDay(day);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedDay != null &&
                          DateUtils.isSameDay(_selectedDay, day)
                      ? AppColors.orangeprimary.withOpacity(0.7)
                      : hasFreeTime
                          ? AppColors.primaryGreen.withOpacity(0.6)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        hasFreeTime ? AppColors.primaryGreen : Colors.white24,
                    width: hasFreeTime ? 3 : 1,
                  ),
                  boxShadow: hasFreeTime
                      ? [
                          BoxShadow(
                            color: AppColors.primaryGreen.withOpacity(0.4),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        color: hasFreeTime ? Colors.white : Colors.white70,
                        fontWeight:
                            hasFreeTime ? FontWeight.w800 : FontWeight.bold,
                        fontSize: hasFreeTime ? 16 : 14,
                      ),
                    ),
                    if (hasFreeTime)
                      Positioned(
                        bottom: 4,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryGreen,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        // Horarios del día seleccionado
        if (_selectedDay != null) ...[
          SizedBox(height: 16),
          _buildSelectedDaySchedule(),
        ],
      ],
    );
  }

  Widget _buildSelectedDaySchedule() {
    final times = freeTimesByDay.entries.firstWhere(
      (e) => DateUtils.isSameDay(e.key, _selectedDay!),
      orElse: () => MapEntry(_selectedDay!, []),
    );

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.orangeprimary.withOpacity(0.15),
            AppColors.primaryGreen.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.orangeprimary.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.orangeprimary.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.orangeprimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.schedule,
                  color: AppColors.orangeprimary,
                  size: 18,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Horarios para ${DateFormat('EEEE, d MMMM', 'es').format(_selectedDay!)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (times.value.isEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white60,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No hay horarios disponibles para este día',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: times.value.map((slot) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryGreen.withOpacity(0.2),
                        AppColors.orangeprimary.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.access_time,
                          color: AppColors.primaryGreen,
                          size: 16,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${slot['start']} - ${slot['end']}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _deleteTimeSlot(slot),
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.redColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.close,
                            color: AppColors.redColor,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.orangeprimary,
                  AppColors.orangeprimary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orangeprimary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => _showAddTimeForDay(_selectedDay!),
              icon:
                  Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
              label: Text(
                'Añadir Bloque Horario',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeTimeCalendar() {
    final daysInMonth =
        DateUtils.getDaysInMonth(_focusedDay.year, _focusedDay.month);
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth =
        DateTime(_focusedDay.year, _focusedDay.month, daysInMonth);
    final weekDayOffset = firstDayOfMonth.weekday - 1;
    final days = List.generate(daysInMonth,
        (i) => DateTime(_focusedDay.year, _focusedDay.month, i + 1));
    // Corregir el error de rango en los nombres de los días de la semana
    final weekDays = List.generate(
        7, (i) => DateFormat.E('es').dateSymbols.STANDALONESHORTWEEKDAYS[i]);
    return Card(
      color: AppColors.darkBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _focusedDay =
                          DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                    });
                  },
                ),
                Text(
                    DateFormat('MMMM yyyy', 'es')
                        .format(_focusedDay)
                        .toUpperCase(),
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _focusedDay =
                          DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weekDays
                  .map((d) => Text(d[0],
                      style: TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.bold)))
                  .toList(),
            ),
            SizedBox(height: 4),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1.1,
              ),
              itemCount: daysInMonth + weekDayOffset,
              itemBuilder: (context, i) {
                if (i < weekDayOffset) return SizedBox.shrink();
                final day = days[i - weekDayOffset];
                final hasFreeTime =
                    freeTimesByDay.keys.any((d) => DateUtils.isSameDay(d, day));
                return GestureDetector(
                  onTap: hasFreeTime
                      ? () {
                          setState(() {
                            _selectedDay = day;
                          });
                          _showFreeTimesForDay(day);
                        }
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _selectedDay != null &&
                              DateUtils.isSameDay(_selectedDay, day)
                          ? AppColors.primaryGreen.withOpacity(0.7)
                          : hasFreeTime
                              ? AppColors.lightBlueColor.withOpacity(0.5)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasFreeTime
                            ? AppColors.primaryGreen
                            : Colors.white24,
                        width: hasFreeTime ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text('${day.day}',
                        style: TextStyle(
                          color: hasFreeTime ? Colors.white : Colors.white38,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep(String title, bool isCompleted, IconData icon) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.primaryGreen
                : Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: Colors.white,
            size: 12,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isCompleted ? Colors.white : Colors.white.withOpacity(0.7),
              fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _showAllSubjectsModal(List<dynamic> allSubjects) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          decoration: BoxDecoration(
            color: AppColors.darkBlue,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Todas las materias (${allSubjects.length})',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: allSubjects.length,
                  itemBuilder: (context, index) {
                    final subject = allSubjects[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.darkBlue.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.lightBlueColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            // Aquí se puede agregar funcionalidad para editar la materia
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightBlueColor
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.school,
                                    color: AppColors.lightBlueColor,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    subject.subject.name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.redColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      color: AppColors.redColor,
                                      size: 16,
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _deleteSubject(subject.id);
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  void _showFreeTimesForDay(DateTime day) {
    final times = freeTimesByDay.entries.firstWhere(
        (e) => DateUtils.isSameDay(e.key, day),
        orElse: () => MapEntry(day, []));
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBlue,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                'Tiempos libres del ${day.day}/${day.month}/${day.year}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              if (times.value.isEmpty)
                Text('No hay tiempos libres para este día',
                    style: TextStyle(color: Colors.white70))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: times.value.length,
                    itemBuilder: (context, index) {
                      final slot = times.value[index];
                      return FreeTimeSlotCard(
                        startTime: slot['start'] ?? '',
                        endTime: slot['end'] ?? '',
                        description: slot['description'],
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

  // Método para mostrar modal de agregar tiempo para un día específico
  void _showAddTimeForDay(DateTime day) {
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 32,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.darkBlue,
                    AppColors.darkBlue.withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header del modal
                  Center(
                    child: Container(
                      width: 50,
                      height: 6,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Título con ícono
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryGreen,
                              AppColors.orangeprimary
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.schedule,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Agregar Horario',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              DateFormat('EEEE, d MMMM', 'es').format(day),
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),

                  // Selector de hora inicio mejorado
                  _buildTimeSelector(
                    context: context,
                    label: 'Hora de Inicio',
                    icon: Icons.play_arrow,
                    time: startTime,
                    onTimeSelected: (time) {
                      setModalState(() {
                        startTime = time;
                      });
                    },
                    setModalState: setModalState,
                  ),
                  SizedBox(height: 20),

                  // Selector de hora fin mejorado
                  _buildTimeSelector(
                    context: context,
                    label: 'Hora de Fin',
                    icon: Icons.stop,
                    time: endTime,
                    onTimeSelected: (time) {
                      setModalState(() {
                        endTime = time;
                      });
                    },
                    setModalState: setModalState,
                    initialTime: startTime,
                  ),
                  SizedBox(height: 32),

                  // Botón de guardar mejorado
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryGreen,
                          AppColors.primaryGreen.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withOpacity(0.4),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: (startTime != null && endTime != null)
                          ? () async {
                              Navigator.of(context).pop();
                              await _createSingleSlot(
                                  day, startTime!, endTime!);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.save_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Guardar Horario',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
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

  // Widget personalizado para selector de tiempo
  Widget _buildTimeSelector({
    required BuildContext context,
    required String label,
    required IconData icon,
    required TimeOfDay? time,
    required Function(TimeOfDay) onTimeSelected,
    required StateSetter setModalState,
    TimeOfDay? initialTime,
    bool isDateSelector = false,
    DateTime? selectedDate,
    Function(DateTime)? onDateSelected,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.orangeprimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.orangeprimary,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  isDateSelector
                      ? (selectedDate != null
                          ? DateFormat('EEEE, d MMMM', 'es')
                              .format(selectedDate!)
                          : '--/--/----')
                      : (time?.format(context) ?? '--:--'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.orangeprimary,
                  AppColors.orangeprimary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () async {
                if (isDateSelector) {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: AppColors.orangeprimary,
                            surface: AppColors.darkBlue,
                            onSurface: Colors.white,
                          ),
                          dialogBackgroundColor: AppColors.backgroundColor,
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null && onDateSelected != null) {
                    onDateSelected(picked);
                  }
                } else {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: initialTime ?? TimeOfDay.now(),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: AppColors.orangeprimary,
                            surface: AppColors.darkBlue,
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    onTimeSelected(picked);
                  }
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Elegir',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Método para crear un solo slot de tiempo
  Future<void> _createSingleSlot(
      DateTime day, TimeOfDay start, TimeOfDay end) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token == null || authProvider.userId == null) return;

      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;
      final duration = endMinutes - startMinutes;

      final slotData = {
        'user_id': authProvider.userId,
        'start_time':
            '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
        'end_time':
            '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
        'date':
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
        'duracion': duration,
      };

      final response =
          await createUserSubjectSlot(authProvider.token!, slotData);

      if (response['success'] == true) {
        await _loadAvailableSlots();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Horario agregado exitosamente'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar el horario'),
            backgroundColor: AppColors.redColor,
          ),
        );
      }
    } catch (e) {
      print('Error creating single slot: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión'),
          backgroundColor: AppColors.redColor,
        ),
      );
    }
  }

  // Método para eliminar un slot de tiempo
  void _deleteTimeSlot(Map<String, String> slot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBlue,
        title: Text(
          'Eliminar horario',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar este horario?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // TODO: Implementar eliminación de slot
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Horario eliminado'),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.redColor),
            child: Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Método para mostrar diálogo de cerrar sesión
  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkBlue.withOpacity(0.98),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de logout con animación
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.redColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(18),
                  child: Icon(
                    Icons.logout_rounded,
                    color: AppColors.redColor,
                    size: 48,
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  '¿Cerrar sesión?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Al cerrar sesión, tendrás que volver a iniciar sesión para acceder a tu cuenta de tutor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white70, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.redColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _performLogout(),
                        child: Text(
                          'Cerrar Sesión',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Método para realizar el logout
  void _performLogout() async {
    try {
      // Cerrar el diálogo
      Navigator.of(context).pop();

      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.darkBlue.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  'Cerrando sesión...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Obtener el AuthProvider y hacer logout
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      // Cerrar el indicador de carga
      Navigator.of(context).pop();

      // Navegar al login y limpiar el stack de navegación
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
        (Route<dynamic> route) => false,
      );

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sesión cerrada exitosamente'),
          backgroundColor: AppColors.primaryGreen,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Cerrar el indicador de carga si hay error
      Navigator.of(context).pop();

      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: $e'),
          backgroundColor: AppColors.redColor,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Sección de tutorías del tutor
  Widget _buildTutorBookingsSection() {
    if (_isLoadingBookings) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.darkBlue.withOpacity(0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.lightBlueColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightBlueColor),
          ),
        ),
      );
    }

    if (_tutorBookings.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.darkBlue.withOpacity(0.8),
              AppColors.darkBlue.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAvailable
                ? AppColors.lightBlueColor.withOpacity(0.4)
                : AppColors.orangeprimary.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícono animado cuando está online
            if (isAvailable) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.lightBlueColor, AppColors.primaryGreen],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lightBlueColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.2),
                  duration: Duration(seconds: 2),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Icon(
                        Icons.video_camera_front,
                        color: Colors.white,
                        size: 32,
                      ),
                    );
                  },
                  onEnd: () {
                    // Reiniciar la animación
                    setState(() {});
                  },
                ),
              ),
              SizedBox(height: 16),
              Text(
                '¡Listo para recibir tutorías!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Los estudiantes pueden asignarte tutorías en cualquier momento',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              // Estado offline con advertencia
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.orangeprimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.orangeprimary.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.orangeprimary,
                  size: 32,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Modo offline activado',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Activa tu disponibilidad para recibir nuevas tutorías',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.orangeprimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.orangeprimary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'No recibirás tutorías mientras estés offline',
                  style: TextStyle(
                    color: AppColors.orangeprimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightBlueColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.school,
                color: AppColors.lightBlueColor,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Mis Tutorías',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.lightBlueColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_tutorBookings.length}',
                style: TextStyle(
                  color: AppColors.lightBlueColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Lista de tutorías
        ..._tutorBookings
            .map((booking) => _buildTutorBookingCard(booking))
            .toList(),
      ],
    );
  }

  // Tarjeta individual de tutoría para el tutor
  Widget _buildTutorBookingCard(Map<String, dynamic> booking) {
    final now = DateTime.now();
    final start = DateTime.tryParse(booking['start_time'] ?? '') ?? now;
    final end = DateTime.tryParse(booking['end_time'] ?? '') ?? now;
    final status = (booking['status'] ?? '').toString().toLowerCase();
    final subject = booking['subject_name'] ?? 'Tutoría';
    final studentName = booking['student_name'] ?? 'Estudiante';

    // Determinar si está en vivo
    final isLive = now.isAfter(start) && now.isBefore(end);

    // Lógica de colores y estados
    String mainText = '';
    Color color = AppColors.lightBlueColor;
    IconData icon = Icons.school;

    if (status == 'cursando' ||
        (status == 'aceptado' && isLive) ||
        (status == 'aceptada' && isLive)) {
      mainText = 'EN VIVO';
      color = Colors.redAccent;
      icon = Icons.play_circle_fill;
    } else if (status == 'aceptado' || status == 'aceptada') {
      mainText = 'Próxima tutoría';
      color = AppColors.lightBlueColor;
      icon = Icons.schedule;
    } else if (status == 'completada' || status == 'completado') {
      mainText = 'Completada';
      color = AppColors.primaryGreen;
      icon = Icons.check_circle;
    } else {
      mainText = 'Programada';
      color = AppColors.lightBlueColor;
      icon = Icons.school;
    }

    final hourStr =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    final dateStr = DateFormat('dd/MM/yyyy').format(start);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Icono de estado
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            SizedBox(width: 16),

            // Información de la tutoría
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mainText,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subject,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Colors.white70,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        studentName,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.lightBlueColor,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        color: AppColors.lightBlueColor,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        hourStr,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Botón de acción según el estado
            _buildActionButton(booking, status, color),
          ],
        ),
      ),
    );
  }

  // Botón de acción según el estado de la tutoría
  Widget _buildActionButton(
      Map<String, dynamic> booking, String status, Color color) {
    final bookingId = booking['id'];
    final meetLink = booking['meeting_link'] ?? '';

    // IMPRIMIR TODOS LOS VALORES DE LA TUTORÍA PARA DEBUG
    // print('🔍 DEBUG - Valores completos de la tutoría:');
    // print('📋 ID: $bookingId');
    // print('📋 Estado: $status');
    // print('📋 Meeting Link: "$meetLink"');
    // print('📋 Meeting Link length: ${meetLink.length}');
    // print('📋 Meeting Link isEmpty: ${meetLink.isEmpty}');
    // print('📋 Meeting Link isNotEmpty: ${meetLink.isNotEmpty}');

    // Imprimir todos los campos disponibles en la tutoría
    // print('📋 Todos los campos de la tutoría:');
    // booking.forEach((key, value) {
    //   print('   $key: $value');
    // });

    if (status == 'aceptado' || status == 'aceptada') {
      // Botón para cambiar estado a "Cursando"
      return GestureDetector(
        onTap: () => _changeToCursando(bookingId),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.green.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_circle_outline,
                color: Colors.green,
                size: 16,
              ),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Iniciar\nTutoría',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (status == 'cursando') {
      // Botón para entrar a la reunión
      // print('🎯 ESTADO CURSANDO - Verificando enlace de Meet');
      // print('🎯 Meeting Link encontrado: "$meetLink"');
      // print('🎯 ¿Tiene enlace?: ${meetLink.isNotEmpty}');

      if (meetLink.isNotEmpty) {
        return GestureDetector(
          onTap: () => _openMeetLink(meetLink),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.red.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.video_call,
                  color: Colors.red,
                  size: 16,
                ),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Entrar a\nMeet',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // print('❌ NO HAY ENLACE - Mostrando "Sin enlace"');
        // print('❌ Meeting Link vacío o nulo: "$meetLink"');

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            'Sin enlace',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        );
      }
    } else {
      // Botón por defecto
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Text(
          'Ver',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      );
    }
  }

  // Método para cambiar estado a "Cursando"
  Future<void> _changeToCursando(int bookingId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: No hay token de autenticación'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Mostrar diálogo de confirmación
      bool confirmed = await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.darkBlue.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.green,
                        size: 48,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '¿Iniciar Tutoría?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Al iniciar la tutoría:\n• El estudiante podrá ver que ya estás en la reunión\n• Se activará el enlace de Google Meet\n• La sesión comenzará oficialmente',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey, width: 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Iniciar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ) ??
          false;

      if (!confirmed) return;

      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.darkBlue.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  'Iniciando tutoría...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final result = await changeBookingToCursando(token, bookingId);

      // Cerrar indicador de carga
      Navigator.of(context).pop();

      if (result['success'] == true) {
        // print('✅ CAMBIO EXITOSO - Estado cambiado a cursando');
        // print('✅ Respuesta del servidor: $result');

        // Mostrar mensaje de éxito con información adicional
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Tutoría iniciada exitosamente!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'El estudiante ya puede ver que estás en la reunión',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Refrescar las tutorías para mostrar el nuevo estado
        _fetchTutorBookings();
      } else {
        // Mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al cambiar el estado'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Cerrar indicador de carga si hay error
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Método para abrir enlace de Meet
  void _openMeetLink(String meetLink) {
    try {
      // Usar url_launcher para abrir el enlace
      launchUrl(Uri.parse(meetLink), mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir el enlace: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
