import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/view/student/favorite_tutor/favorite_tutors_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_projects/view/detailPage/detail_screen.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const String _tutorTopic = 'tutor';
  static const String _tutorLegacyTopic = 'tutores';
  static const String _permissionAskedKey = 'notification_permission_asked';

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

  static Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    await _messaging.setAutoInitEnabled(true);

    String? token = await _messaging.getToken();
    print('FCM Token: $token');

    await _messaging.subscribeToTopic(_tutorTopic);
    await _messaging.subscribeToTopic(_tutorLegacyTopic);
    print('Suscripción a topics de tutor completada');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('======================');
      print('MENSAJE RECIBIDO');
      print('MessageId: ${message.messageId}');
      print('From: ${message.from}');
      print('Título: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
      print('======================');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNavigation(message, navigatorKey);
    });
  }

  static void _handleNavigation(
    RemoteMessage message,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    final data = message.data;
    final context = navigatorKey.currentContext;

    if (context == null) {
      print('No hay contexto de navegacion disponible para push');
      return;
    }

    switch (data['screen']) {
      case 'solicitud_tutor':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FavoriteTutorsScreen()),
        );
        break;

      case 'chat':
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
