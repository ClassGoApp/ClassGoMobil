import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/tutor/dashboard/widgets/tutor_bottom_nav.dart';
import 'package:flutter_projects/view/tutor/features/agenda/tutor_agenda_screen.dart';
import 'package:flutter_projects/view/tutor/features/home/tutor_home_screen.dart';
import 'package:flutter_projects/view/tutor/features/profile/tutor_profile_screen.dart';
import 'package:flutter_projects/view/tutor/features/subjects/tutor_subjects_screen.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';

// Provider y Modelos
import 'package:flutter_projects/provider/tutor_subjects_provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/api_structure/api_service.dart';

// Vistas
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/components/success_animation_dialog.dart';

// Helpers
import 'package:flutter_projects/helpers/pusher_service.dart';

// Widgets
import 'package:flutter_projects/view/tutor/dashboard/sheets/add_schedule_sheet.dart';
import 'package:flutter_projects/models/tutor_subject.dart';

import 'package:flutter_projects/view/tutor/dashboard/logic/calendar_selection_controller.dart';

class DashboardTutor extends StatefulWidget {
  @override
  _DashboardTutorState createState() => _DashboardTutorState();
}

class _DashboardTutorState extends State<DashboardTutor>
    with WidgetsBindingObserver {
  bool _isBottomNavVisible = true;
  bool isAvailable = false;

  int _currentIndex = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final CalendarSelectionController _calendarController =
      CalendarSelectionController();

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

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      if (notification.scrollDelta! > 2.0 && _isBottomNavVisible) {
        // Scrolleando hacia ABAJO -> Ocultar barra
        setState(() {
          _isBottomNavVisible = false;
        });
      } else if (notification.scrollDelta! < -2.0 && !_isBottomNavVisible) {
        // Scrolleando hacia ARRIBA -> Mostrar barra
        setState(() {
          _isBottomNavVisible = true;
        });
      }
    }
    return false; // Permite que el scroll continúe propagándose
  }

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(0, 216, 24, 24), // Fondo transparente
      statusBarIconBrightness:
          Brightness.light, // Iconos blancos (Hora, Batería)
      statusBarBrightness: Brightness.dark, // Para iOS
    ));
    // Agregar observer para el lifecycle de la app
    WidgetsBinding.instance.addObserver(this);

    // Cargar materias del tutor
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadInitialData();
      if (mounted) _syncProfileImageFromAuthProvider();
    });
  }

  @override
  void dispose() {
    _calendarController.dispose();
    _authProvider?.removeListener(_checkAndFetchBookings);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // CARGA DE DATOS
  Future<void> _loadInitialData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final subjectsProvider =
        Provider.of<TutorSubjectsProvider>(context, listen: false);

    await subjectsProvider.loadTutorSubjects(authProvider);
    _loadAvailableSlots();
    _fetchTutorBookings();
    _loadProfileImage();
  }

  Future<void> _loadAvailableSlots() async {
    if (!mounted) return;

    if (mounted) {
      setState(() {
        _isLoadingSlots = true;
      });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token != null && authProvider.userId != null) {
        final response = await getTutorAvailableSlots(
          authProvider.token!,
          authProvider.userId!.toString(),
        );

        if (response['status'] == 200 && response['data'] != null) {
          final List<dynamic> slotsData = response['data'] as List<dynamic>;
          if (mounted) {
            setState(() {
              _availableSlots = slotsData.cast<Map<String, dynamic>>();
              _updateFreeTimesByDay();
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _availableSlots = [];
              _updateFreeTimesByDay();
            });
          }
        }
      }
    } catch (e) {
      print('Error loading available slots: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSlots = false;
        });
      }
    }
  }

  // Método para cargar las tutorías del tutor
  Future<void> _fetchTutorBookings() async {
    if (!mounted) return;

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

    if (mounted) {
      setState(() {
        _isLoadingBookings = false;
      });
    }
  }

  // Método para limpiar URLs de imagen duplicadas
  String _cleanImageUrl(String url) {
    // Si la URL contiene duplicación de dominio, limpiarla
    if (url.contains('https://classgoapp.com/storagehttps://classgoapp.com')) {
      return url.replaceFirst(
          'https://classgoapp.com/storagehttps://classgoapp.com',
          'https://classgoapp.com');
    }

    // Si la URL contiene duplicación de storage, limpiarla
    if (url.contains('/storage/storage/')) {
      return url.replaceFirst('/storage/storage/', '/storage/');
    }

    return url;
  }

  // Método para sincronizar la imagen del AuthProvider
  void _syncProfileImageFromAuthProvider() {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authImageUrl = authProvider.userData?['user']?['profile']?['image'] ??
        authProvider.userData?['user']?['profile']?['profile_image'];

    if (authImageUrl != null &&
        authImageUrl.isNotEmpty &&
        authImageUrl != _profileImageUrl) {
      // Limpiar URL si está duplicada
      final cleanUrl = _cleanImageUrl(authImageUrl);
      if (mounted) {
        setState(() {
          _profileImageUrl = cleanUrl;
        });
      }
    }
  }

  // Método para cargar la imagen de perfil del tutor
  Future<void> _loadProfileImage() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingProfileImage = true;
        });
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.userId;

      // Primero verificar si ya tenemos una imagen en el AuthProvider
      final cachedImageUrl = authProvider.userData?['user']?['profile']
              ?['image'] ??
          authProvider.userData?['user']?['profile']?['profile_image'];
      if (cachedImageUrl != null && cachedImageUrl.isNotEmpty) {
        // Limpiar URL si está duplicada
        final cleanUrl = _cleanImageUrl(cachedImageUrl);
        if (mounted) {
          setState(() {
            _profileImageUrl = cleanUrl;
          });
        }
      }

      if (token != null && userId != null) {
        final response = await getUserProfileImage(token, userId);

        if (response['success'] == true && response['data'] != null) {
          final profileData = response['data'];
          final profileImageUrl = profileData['profile_image'];

          if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
            // Limpiar URL si está duplicada
            final cleanUrl = _cleanImageUrl(profileImageUrl);
            if (mounted) {
              setState(() {
                _profileImageUrl = cleanUrl;
              });
            }

            // Actualizar también en el AuthProvider para mantener sincronización
            authProvider.updateProfileImage(cleanUrl);
          }
        }
      }
    } catch (e) {
      // Error silencioso para no interrumpir la experiencia del usuario
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfileImage = false;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    // Listener para recargar si cambia el usuario o el token
    if (_authProvider != authProvider) {
      _authProvider = authProvider;
      _checkAndFetchBookings();
      _authProvider!.addListener(_checkAndFetchBookings);
    }

    // Sincronizar imagen del AuthProvider después de verificar cambios
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncProfileImageFromAuthProvider();
      }
    });

    // Configurar eventos de Pusher para el tutor
    final pusherService = Provider.of<PusherService>(context, listen: false);
    print('🎯 Configurando callback de Pusher en DashboardTutor');
    pusherService.init(
      onSlotBookingStatusChanged: (data) {
        print(' Evento del canal recibido en DashboardTutor: $data');

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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Recargar la imagen del perfil cuando la app se reanuda

      // Usar addPostFrameCallback para evitar problemas de setState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Sincronizar imagen del AuthProvider
          _syncProfileImageFromAuthProvider();

          // También recargar desde la API
          _loadProfileImage();
        }
      });
    }
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

      // Si es formato ISO datetime completo (con Z o +00:00 al final)
      if (timeStr.contains('T') &&
          (timeStr.contains('Z') ||
              timeStr.contains('+') ||
              timeStr.contains('-'))) {
        final dateTime = DateTime.tryParse(timeStr);
        if (dateTime != null) {
          // Convertir de UTC a zona horaria local
          final localDateTime = dateTime.toLocal();
          return '${localDateTime.hour.toString().padLeft(2, '0')}:${localDateTime.minute.toString().padLeft(2, '0')}';
        }
      }

      // Si es solo fecha con hora (sin zona horaria)
      final dateTime = DateTime.tryParse(timeStr);
      if (dateTime != null) {
        // Si no tiene zona horaria, asumir que ya está en hora local
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      }

      return timeStr;
    } catch (e) {
      print('Error formatting time: $e for string: $timeStr');
      return timeStr;
    }
  }

  /// Valida si hay conflictos de horarios para un nuevo slot
  /// Retorna true si hay conflicto, false si no hay conflicto

  /// Limpia los errores de validación

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

          print('DEBUG - Slot data: ${slot.toString()}');
          print('DEBUG - Original start_time: ${slot['start_time']}');
          print('DEBUG - Original end_time: ${slot['end_time']}');
          print('DEBUG - Formatted start: $formattedStart');
          print('DEBUG - Formatted end: $formattedEnd');

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

// Método refactorizado para mostrar modal de agregar horario
  void _showAddFreeTimeModal({DateTime? initialDate}) {
    // 1. Calculamos la fecha inicial (si viene nula, usa hoy)
    DateTime selectedDay = initialDate ?? DateTime.now();

    // showModalBottomSheet(
    //   context: context,
    //   isScrollControlled: true,
    //   backgroundColor: Colors.transparent,
    //   // Usamos el widget separado que creamos
    //   builder: (context) => AddScheduleSheet(
    //     onSave: (newSlots) {
    //       // El modal nos devuelve la lista limpia y validada
    //       _createSlots(newSlots);
    //     },
    //   ),
    // );
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
        showSuccessDialog(
          context: context,
          title: '¡Horarios Agregados!',
          message: '$successCount tiempo(s) libre(s) agregado(s) exitosamente',
          buttonText: 'Continuar',
          onContinue: () {
            // El diálogo se cierra automáticamente
          },
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
    final authProvider = Provider.of<AuthProvider>(context);
    final subjectsProvider = Provider.of<TutorSubjectsProvider>(context);

    final List<Widget> _screens = [
      // 0. INICIO
      TutorHomeScreen(
          onNavigate: (index) => setState(() => _currentIndex = index)),

      // 1. AGENDA
      const TutorAgendaScreen(),

      // 2. MATERIAS
      TutorSubjectsScreen(),

      // 3. PERFIL
      const TutorProfileScreen(),
    ];

    // bool showNavbar = false;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(children: [
        IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: TutorBottomNav(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() => _currentIndex = index);
                // lógica de navegación real:
                // if (index == 1) Navigator.pushNamed...
                print("Navegar a tab: $index");
              },
            ))
      ]),
    );
  }

  // Barra deslizante con diseño consistente
  // availavilitySlider.dart

  // Sección de materias con chips
  // tutor_subject_section.dart

  // Sección unificada de disponibilidad

  // Widget para construir las tarjetas de materias

  // Sección del logo de Classgo en espacio dedicado

  // Método para mostrar información de Classgo

  // Método para mostrar modal de agregar tiempo para un día específico

  // Widget personalizado para selector de tiempo

  // Método para crear un solo slot de tiempo

  // Método para eliminar un slot de tiempo

  // Método para ejecutar la eliminación del slot

  // Método para mostrar diálogo de cerrar sesión

  // Método para realizar el logout

  // Sección de tutorías del tutor
  // tutor_booking_section.dart

  // Tarjeta individual de tutoría para el tutor

  // Botón de acción según el estado de la tutoría

  // Método para cambiar estado a "Cursando"

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

  // Método para reproducir sonido de éxito

  // Método para actualizar la disponibilidad de tutoría
  Future<void> _updateTutoringAvailability(bool newAvailability) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token == null || authProvider.userId == null) {
        print('Error: Token o userId no disponibles');
        return;
      }

      print(
          'Actualizando disponibilidad de tutoría a: ${newAvailability ? "Activada" : "Desactivada"}');

      final response = await updateTutoringAvailability(
        authProvider.token!,
        authProvider.userId!,
        newAvailability,
      );

      if (response['success'] == true) {
        print(
            'Disponibilidad actualizada exitosamente: ${response['message']}');
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newAvailability
                  ? '¡Disponibilidad activada! Los estudiantes pueden encontrarte ahora.'
                  : 'Disponibilidad desactivada. No recibirás nuevas solicitudes.',
            ),
            backgroundColor: newAvailability
                ? AppColors.primaryGreen
                : AppColors.orangeprimary,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        print('Error al actualizar disponibilidad: ${response['message']}');
        // Revertir el cambio en la UI si falla la API
        if (mounted) {
          setState(() {
            isAvailable = !newAvailability;
          });
        }
        // Mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response['message']}'),
            backgroundColor: AppColors.redColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error al actualizar disponibilidad: $e');
      // Revertir el cambio en la UI si falla
      if (mounted) {
        setState(() {
          isAvailable = !newAvailability;
        });
      }
      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión. Intenta nuevamente.'),
          backgroundColor: AppColors.redColor,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
