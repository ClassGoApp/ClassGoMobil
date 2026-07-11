import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class TutorHomeProvider extends ChangeNotifier {
  bool isAvailable = true;
  bool isLoading = false;
  List<Map<String, dynamic>>? nextBooking = [];
  
  String? profileImageUrl;
  bool isLoadingProfileImage = false;

  bool showVerifiedBanner = false;
  Timer? _verifiedBannerTimer;

  Future<void> showVerifiedBannerBriefly() async {
    final prefs = await SharedPreferences.getInstance();
    const shownKey = 'verified_banner_shown';
    if (prefs.getBool(shownKey) == true) return;
    await prefs.setBool(shownKey, true);
    showVerifiedBanner = true;
    notifyListeners();
    _verifiedBannerTimer?.cancel();
    _verifiedBannerTimer = Timer(const Duration(seconds: 7), () {
      showVerifiedBanner = false;
      notifyListeners();
    });
  }

  void dismissVerifiedBanner() {
    _verifiedBannerTimer?.cancel();
    showVerifiedBanner = false;
    notifyListeners();
  }

  // NUEVO: Estado para solicitudes de tutoría pendientes (desde notificaciones)
  Map<String, dynamic>? pendingTutoringRequest;
  DateTime? requestTime;
  DateTime? confirmationStartTime;
  DateTime? tutoringTimerStartTime; // Global timer start time
  bool isRequestRejected = false; // Nueva flag para tutor_rechazado
  bool isRequestChosen = false; // Nueva flag para tutor_aceptado
  bool isTutoringReady = false; // Nueva flag para tutoria_lista
  String? activeMeetLink; // Enlace para unirse a la clase
  Timer? _expirationTimer;

  bool get isRequestExpired {
    if (requestTime == null) return false;
    final difference = DateTime.now().difference(requestTime!);
    return difference.inMinutes >= 5;
  }

  void setConfirmationStartTime(DateTime? time) {
    confirmationStartTime = time;
    notifyListeners();
  }

  void startTutoringTimer() {
    tutoringTimerStartTime = DateTime.now();
    notifyListeners();
  }

  void resetTutoringTimer() {
    tutoringTimerStartTime = DateTime.now();
    notifyListeners();
  }

  void setPendingTutoringRequest(Map<String, dynamic>? data) {
    _expirationTimer?.cancel();
    pendingTutoringRequest = data;
    requestTime = DateTime.now();
    
    // Iniciamos un temporizador que refresca cada minuto para actualizar el estado "Expirado"
    // y finalmente limpia la solicitud a los 7 minutos
    _expirationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (pendingTutoringRequest == null) {
        timer.cancel();
        return;
      }
      
      final difference = DateTime.now().difference(requestTime!);
      if (difference.inMinutes >= 7) {
        clearPendingRequest();
        timer.cancel();
      } else {
        notifyListeners(); // Actualiza la UI para mostrar "Expirado" si ya pasaron 5 min
      }
    });

    notifyListeners();
  }

  void clearPendingRequest() {
    _expirationTimer?.cancel();
    _verifiedBannerTimer?.cancel();
    pendingTutoringRequest = null;
    requestTime = null;
    confirmationStartTime = null;
    isRequestRejected = false;
    isRequestChosen = false;
    isTutoringReady = false;
    activeMeetLink = null;
    showVerifiedBanner = false;
    notifyListeners();
  }

  void setRequestRejected(bool rejected) {
    isRequestRejected = rejected;
    notifyListeners();
  }

  void setRequestChosen(bool chosen) {
    isRequestChosen = chosen;
    notifyListeners();
  }

  void setTutoringReady(String? link) {
    activeMeetLink = link;
    isTutoringReady = true;
    isRequestChosen = false; // Ya no es solo "elegido", ahora está lista
    notifyListeners();
  }

  // 1. CARGA INICIAL (Ahora carga la foto también)
  Future<void> loadHomeData(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    // Sincroniza la foto local rápido antes de pedir a internet
    syncProfileImageFromAuthProvider(context);

    // Ejecuta las consultas de la API al mismo tiempo
    await Future.wait([
      loadTutoringAvailability(context),
      fetchNextBooking(context),
      loadProfileImage(context), 
    ]);

    isLoading = false;
    notifyListeners();
  }

  String cleanImageUrl(String url) {
    if (url.contains('https://classgoapp.com/storagehttps://classgoapp.com')) {
      return url.replaceFirst(
          'https://classgoapp.com/storagehttps://classgoapp.com',
          'https://classgoapp.com');
    }
    if (url.contains('/storage/storage/')) {
      return url.replaceFirst('/storage/storage/', '/storage/');
    }
    return url;
  }

  void syncProfileImageFromAuthProvider(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authImageUrl = authProvider.userData?['user']?['profile']?['image'] ??
        authProvider.userData?['user']?['profile']?['profile_image'];

    if (authImageUrl != null && authImageUrl.isNotEmpty && authImageUrl != profileImageUrl) {
      profileImageUrl = cleanImageUrl(authImageUrl);
      notifyListeners();
    }
  }

  Future<void> loadProfileImage(BuildContext context) async {
    isLoadingProfileImage = true;
    notifyListeners();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.userId;

      // Primero verificar si ya tenemos una imagen en el AuthProvider
      final cachedImageUrl = authProvider.userData?['user']?['profile']?['image'] ??
          authProvider.userData?['user']?['profile']?['profile_image'];
          
      if (cachedImageUrl != null && cachedImageUrl.isNotEmpty) {
        profileImageUrl = cleanImageUrl(cachedImageUrl);
        notifyListeners();
      }

      if (token != null && userId != null) {
        final response = await getUserProfileImage(token, userId);

        if (response['success'] == true && response['data'] != null) {
          final profileData = response['data'];
          final apiProfileImageUrl = profileData['profile_image'];

          if (apiProfileImageUrl != null && apiProfileImageUrl.isNotEmpty) {
            final cleanUrl = cleanImageUrl(apiProfileImageUrl);
            profileImageUrl = cleanUrl;
            
            // Actualizar también en el AuthProvider
            authProvider.updateProfileImage(cleanUrl);
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('Error cargando imagen: $e');
    } finally {
      isLoadingProfileImage = false;
      notifyListeners();
    }
  }

  // LÓGICA DE CITAS Y DISPONIBILIDAD

  Future<void> loadTutoringAvailability(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token == null || authProvider.userId == null) return;

      final response = await getTutorTutoringAvailability(authProvider.token, authProvider.userId!);

      if (response['success'] == true) {
        isAvailable = response['available_for_tutoring'] ?? false;
        notifyListeners();
      }
    } catch (e) {
      print('Error cargando disponibilidad: $e');
    }
  }

  Future<void> fetchNextBooking(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.userId;

      if (token != null && userId != null) {
        final bookings = await getUserBookingsById(token, userId);
        final now = DateTime.now();
        
        final validBookings = bookings.where((b) {
          final status = (b['status'] ?? '').toString().toLowerCase();
          final start = DateTime.tryParse(b['start_time'] ?? '') ?? now;
          final isValidStatus = ['aceptado', 'aceptada', 'cursando', 'pendiente'].contains(status);
          final isFuture = start.isAfter(now.subtract(const Duration(minutes: 30)));
          return isValidStatus && isFuture;
        }).toList();

        validBookings.sort((a, b) {
           final dateA = DateTime.tryParse(a['start_time'] ?? '') ?? now;
           final dateB = DateTime.tryParse(b['start_time'] ?? '') ?? now;
           return dateA.compareTo(dateB);
        });

        nextBooking = validBookings; 
        notifyListeners();
      }
    } catch (e) {
      print('Error obteniendo citas: $e');
    }
  }
  Future<void> refreshOnlySubjects(BuildContext context) async {
    try {
      print('🔄 Refrescando tutorías y perfil...');
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshProfileFromServer();

      await loadProfileImage(context);
      await fetchNextBooking(context);
      
      print('✅ Tutorías y perfil actualizados correctamente');
    } catch (e) {
      print('❌ Error en el refresco silencioso: $e');
    }
  }
  Future<void> handleAvailabilityToggle(BuildContext context, bool newState) async {
    isAvailable = newState;
    notifyListeners();
    
    if (newState) {
       try {
         final player = AudioPlayer();
         await player.play(AssetSource('sounds/success.mp3'));
       } catch (_) {}
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await updateTutoringAvailability(authProvider.token!, authProvider.userId!, newState);
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newState ? '¡Estás visible!' : 'Modo invisible activado'),
        backgroundColor: newState ? AppColors.stateSuccess : AppColors.stateMuted,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      isAvailable = !newState;
      notifyListeners();
    }
  }

  // Lógica pura de API para cambiar estado
  Future<bool> changeBookingStatusToCursando(BuildContext context, int bookingId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token == null) throw Exception("No hay token");

      final result = await changeBookingToCursando(authProvider.token!, bookingId);
      
      if (result['success'] == true) {
        // Recargar la lista de citas para actualizar la UI automáticamente
        await fetchNextBooking(context);
        return true;
      } else {
        throw Exception(result['message'] ?? 'Error al cambiar el estado');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: Colors.red,
      ));
      return false;
    }
  }

  // Lógica para abrir Meet
  void openMeetLink(BuildContext context, String meetLink) async {
    try {
      if (meetLink.isEmpty) throw Exception("El enlace está vacío");
      final url = Uri.parse(meetLink);
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al abrir Meet: $e'), backgroundColor: Colors.red,
      ));
    }
  }
}