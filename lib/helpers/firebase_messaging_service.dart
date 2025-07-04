import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:flutter/material.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Solicita permisos para notificaciones (importante en Android 13+ y iOS)
    await _messaging.requestPermission();

    // Obtén el token del dispositivo
    String? token = await _messaging.getToken();
    print('FCM Token: $token');

    // Maneja mensajes en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Mensaje recibido en foreground: \\${message.notification?.title}');
      if (message.notification != null) {
        showSimpleNotification(
          Text(message.notification!.title ?? 'Notificación'),
          subtitle: Text(message.notification!.body ?? ''),
          background: Colors.blueAccent,
          duration: Duration(seconds: 4),
        );
      }
    });

    // Maneja mensajes cuando la app está en background o terminada y el usuario la abre desde la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(
          'Mensaje abierto desde background: \\${message.notification?.title}');
    });
  }
}
