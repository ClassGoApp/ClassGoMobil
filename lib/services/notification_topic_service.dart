import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/main.dart';
import 'package:flutter_projects/view/tutor/features/Instant_tutoring/accept_tutoring_screen.dart';
import 'package:flutter_projects/view/tutor/features/Instant_tutoring/confirmation_tutoring_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationTopicService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const String _tutorTopic = 'tutor';
  static const String _tutorLegacyTopic = 'tutores';
  static const String _studentTopic = 'estudiantes';
  static const String _fcmRoleKey = 'fcm_user_role';
  static const MethodChannel _notificationClickChannel =
      MethodChannel('classgo/notification_click');
  static bool _nativeClickBridgeInitialized = false;
  static const String _permissionAskedKey = 'notification_permission_asked';

  static Future<void> _persistCurrentRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmRoleKey, role);
  }

  /// Suscribe al usuario según su rol
  static Future<void> configureTopics(String rol) async {
    try {
      await _setupNativeNotificationClickBridge();

      final normalizedRole = rol.trim().toLowerCase();

      // Siempre limpiamos primero para evitar suscripciones obsoletas.
      await _messaging.unsubscribeFromTopic(_tutorTopic);
      await _messaging.unsubscribeFromTopic(_tutorLegacyTopic);
      await _messaging.unsubscribeFromTopic(_studentTopic);

      if (normalizedRole == 'tutor') {
        await _messaging.subscribeToTopic(_tutorTopic);
        await _messaging.subscribeToTopic(_tutorLegacyTopic);
        await _persistCurrentRole('tutor');
        print(
            'Suscrito a topics: $_tutorTopic, $_tutorLegacyTopic (rol tutor)');
      } else if (normalizedRole == 'student' ||
          normalizedRole == 'estudiante') {
        await _messaging.subscribeToTopic(_studentTopic);
        await _persistCurrentRole('student');
        print('Suscrito a topic: $_studentTopic (rol student)');
      } else {
        await _persistCurrentRole('unknown');
        print(
            'Rol no reconocido para topics: $rol. Se dejaron todos los topics desuscritos.');
      }

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNavigation(message, navigatorKey);
      });

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNavigation(initialMessage, navigatorKey);
      }
    } catch (e) {
      print('Error al configurar topics: $e');
    }
  }

  /// Desuscribir de todos (por ejemplo al hacer logout)
  static Future<void> unsubscribeAll() async {
    try {
      await _messaging.unsubscribeFromTopic(_tutorTopic);
      await _messaging.unsubscribeFromTopic(_tutorLegacyTopic);
      await _messaging.unsubscribeFromTopic(_studentTopic);
      await _persistCurrentRole('none');
      print('Desuscrito de todos los topics');
    } catch (e) {
      print('Error al desuscribirse: $e');
    }
  }

  /// Suscribirse manualmente a un topic (por si luego agregas más)
  static Future<void> subscribe(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Suscrito a: $topic');
    } catch (e) {
      print('Error al suscribirse: $e');
    }
  }

  /// Desuscribirse manualmente
  static Future<void> unsubscribe(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Desuscrito de: $topic');
    } catch (e) {
      print('Error al desuscribirse: $e');
    }
  }

  // Pedir Permisos para android
  static Future<void> requestPermissionOnFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyAsked = prefs.getBool(_permissionAskedKey) ?? false;

    if (alreadyAsked) {
      print('Permiso de notificaciones ya fue solicitado anteriormente');
      return;
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('Permiso de notificaciones FCM: ${settings.authorizationStatus}');
    await prefs.setBool(_permissionAskedKey, true);
  }

  static void _handleNavigation(
    RemoteMessage message,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    _handleNavigationFromData(message.data, navigatorKey);
  }

  static Future<void> _setupNativeNotificationClickBridge() async {
    if (_nativeClickBridgeInitialized) {
      return;
    }

    _nativeClickBridgeInitialized = true;

    _notificationClickChannel.setMethodCallHandler((MethodCall call) async {
      if (call.method != 'onNotificationClick') {
        return;
      }

      final payload = Map<String, dynamic>.from(call.arguments as Map);
      _handleNavigationFromData(payload, navigatorKey);
    });

    try {
      final initialPayload = await _notificationClickChannel
          .invokeMapMethod<String, dynamic>('getInitialNotificationData');
      if (initialPayload != null && initialPayload.isNotEmpty) {
        _handleNavigationFromData(initialPayload, navigatorKey);
      }
    } catch (e) {
      print('No se pudo leer payload inicial de notificacion nativa: $e');
    }
  }

  static void _handleNavigationFromData(
    Map<String, dynamic> data,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    final context = navigatorKey.currentContext;

    if (context == null) {
      print('No hay contexto de navegacion disponible para push');
      return;
    }

    switch (data['screen']) {
      case 'solicitud_tutor':
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => AcceptTutoringScreen(
                    data_tutor: data['data_tutor'],
                    onEnterWaitingRoom: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const VistaConfirmacion()));
                    },
                  )),
        );
        break;

      case 'tutor_rechazado':
        // Cambiar el estado de la vista de confirmación para mostrar que alguien ya acepto la solicitud
        print('Push chat recibida, pero no existe vista de chat configurada');
        break;

      case 'detalle_solicitud':
        print(
            'Push detalle recibida, pero no existe vista de chat configurada');
        break;

      default:
        print('Push sin pantalla manejada: ${data['screen']}');
        break;
    }
  }
}
