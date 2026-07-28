import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/main.dart';
import 'package:flutter_projects/view/tutor/features/Instant_tutoring/accept_tutoring_screen.dart';
import 'package:flutter_projects/view/tutor/features/Instant_tutoring/confirmation_tutoring_screen.dart';
import 'package:flutter_projects/view/tutor/features/Instant_tutoring/ready_tutoring_screen.dart';
import 'package:flutter_projects/view/tutor/features/Instant_tutoring/view_wait_tutoring_screen.dart';
import 'package:flutter_projects/view/tutor/features/home/providers/tutor_home_provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_projects/view/tutor/features/agenda/schedule_request_detail_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 [FCM Background] Notificación recibida en segundo plano: ${message.data}');

  final data = message.data;
  final screen = data['screen'];
  final type = data['type'];

  if (screen == 'solicitud_detalle' ||
      screen == 'detalle_solicitud' ||
      type == 'solicitud_tutor_personalizada' ||
      type == 'solicitud_flexible') {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      const storageKey = 'cached_pending_flexible_requests';
      final jsonStr = prefs.getString(storageKey);
      List<dynamic> list = [];
      if (jsonStr != null && jsonStr.isNotEmpty) {
        try {
          list = jsonDecode(jsonStr);
        } catch (_) {}
      }

      String? newToken;
      var decodificado = data['data_tutor'];
      if (decodificado != null) {
        if (decodificado is String) {
          try {
            var parsed = jsonDecode(decodificado);
            if (parsed is String) parsed = jsonDecode(parsed);
            decodificado = parsed;
          } catch (_) {}
        }
        if (decodificado is Map) {
          newToken = decodificado['token']?.toString() ??
              decodificado['accept_token']?.toString();
        }
      }
      newToken ??=
          data['token']?.toString() ?? data['accept_token']?.toString();

      if (newToken != null && newToken.isNotEmpty) {
        list.removeWhere((item) {
          if (item is Map) {
            var d = item['data_tutor'];
            String? t;
            if (d != null) {
              if (d is String) {
                try {
                  var p = jsonDecode(d);
                  if (p is String) p = jsonDecode(p);
                  d = p;
                } catch (_) {}
              }
              if (d is Map) {
                t = d['token']?.toString() ?? d['accept_token']?.toString();
              }
            }
            t ??= item['token']?.toString() ?? item['accept_token']?.toString();
            return t == newToken;
          }
          return false;
        });
      }

      list.insert(0, data);
      await prefs.setString(storageKey, jsonEncode(list));
      print(
          '💾 [FCM Background] Solicitud flexible guardada exitosamente en SharedPreferences!');
    } catch (e) {
      print('❌ [FCM Background] Error al guardar notificación flexible: $e');
    }
  }
}

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

      // Siempre limpiamos primero para evitar suscripciones obsoletas en paralelo
      await Future.wait([
        _messaging.unsubscribeFromTopic(_tutorTopic),
        _messaging.unsubscribeFromTopic(_tutorLegacyTopic),
        _messaging.unsubscribeFromTopic(_studentTopic),
      ]).timeout(const Duration(seconds: 3), onTimeout: () {
        print('Timeout al desuscribirse de topics antiguos.');
        return [];
      });

      if (normalizedRole == 'tutor') {
        await Future.wait([
          _messaging.subscribeToTopic(_tutorTopic),
          _messaging.subscribeToTopic(_tutorLegacyTopic),
        ]).timeout(const Duration(seconds: 3), onTimeout: () {
          print('Timeout al suscribirse a topics de tutor.');
          return [];
        });
        await _persistCurrentRole('tutor');
        print(
            'Suscrito a topics: $_tutorTopic, $_tutorLegacyTopic (rol tutor)');
      } else if (normalizedRole == 'student' ||
          normalizedRole == 'estudiante') {
        await _messaging.subscribeToTopic(_studentTopic).timeout(const Duration(seconds: 3), onTimeout: () {
          print('Timeout al suscribirse a topic de estudiante.');
        });
        await _persistCurrentRole('student');
        print('Suscrito a topic: $_studentTopic (rol student)');
      } else {
        await _persistCurrentRole('unknown');
        print(
            'Rol no reconocido para topics: $rol. Se dejaron todos los topics desuscritos.');
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('🔔 Notificación en primer plano recibida: ${message.data}');

        final data = message.data;
        if (data['screen'] == 'solicitud_tutor') {
          final context = navigatorKey.currentContext;
          if (context != null) {
            try {
              // Actualizamos el provider de la Home del tutor
              final homeProvider =
                  Provider.of<TutorHomeProvider>(context, listen: false);
              homeProvider.setPendingTutoringRequest(data);
              homeProvider.startTutoringTimer(); // Inicia el cronómetro global
            } catch (e) {
              print(
                  'Error al actualizar TutorHomeProvider desde notificación: $e');
            }
          }
        } else if (data['screen'] == 'solicitud_detalle' ||
            data['screen'] == 'detalle_solicitud' ||
            data['type'] == 'solicitud_tutor_personalizada' ||
            data['type'] == 'solicitud_flexible') {
          print('📩 [FCM] Procesando notificación de solicitud flexible...');

          // Guardamos en SharedPreferences independientemente del rol para persistencia
          SharedPreferences.getInstance().then((prefs) async {
            try {
              await prefs.reload();
              const storageKey = 'cached_pending_flexible_requests';
              final jsonStr = prefs.getString(storageKey);
              List<dynamic> list = [];
              if (jsonStr != null && jsonStr.isNotEmpty) {
                try {
                  list = jsonDecode(jsonStr);
                } catch (_) {}
              }

              // Deduplicar por token
              String? newToken;
              var decodificado = data['data_tutor'];
              if (decodificado != null) {
                if (decodificado is String) {
                  try {
                    var parsed = jsonDecode(decodificado);
                    if (parsed is String) parsed = jsonDecode(parsed);
                    decodificado = parsed;
                  } catch (_) {}
                }
                if (decodificado is Map) {
                  newToken = decodificado['token']?.toString() ??
                      decodificado['accept_token']?.toString();
                }
              }
              newToken ??= data['token']?.toString() ??
                  data['accept_token']?.toString();

              if (newToken != null && newToken.isNotEmpty) {
                list.removeWhere((item) {
                  if (item is Map) {
                    var d = item['data_tutor'];
                    String? t;
                    if (d != null) {
                      if (d is String) {
                        try {
                          var p = jsonDecode(d);
                          if (p is String) p = jsonDecode(p);
                          d = p;
                        } catch (_) {}
                      }
                      if (d is Map) {
                        t = d['token']?.toString() ??
                            d['accept_token']?.toString();
                      }
                    }
                    t ??= item['token']?.toString() ??
                        item['accept_token']?.toString();
                    return t == newToken;
                  }
                  return false;
                });
              }

              list.insert(0, data);
              await prefs.setString(storageKey, jsonEncode(list));
              print(
                  '💾 [FCM Foreground] Guardada solicitud flexible en SharedPreferences');
            } catch (e) {
              print('Error guardando push foreground en prefs: $e');
            }
          });

          final context = navigatorKey.currentContext;
          if (context != null) {
            try {
              final homeProvider =
                  Provider.of<TutorHomeProvider>(context, listen: false);
              homeProvider.setPendingFlexibleRequest(data);
            } catch (_) {}
          }
        } else if (data['screen'] == 'tutor_aceptado') {
          final context = navigatorKey.currentContext;
          if (context != null) {
            try {
              final homeProvider =
                  Provider.of<TutorHomeProvider>(context, listen: false);
              homeProvider
                  .resetTutoringTimer(); // Reinicia el cronómetro a 5 min
              homeProvider.setRequestRejected(
                  false); // Por si acaso estaba en rechazado
              homeProvider.setRequestChosen(true); // Marca como elegido

              // Navegamos directamente a la pantalla de espera reemplazando la actual
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const VistaFuisteElegido()),
              );
            } catch (e) {
              print('Error al procesar tutor_aceptado en primer plano: $e');
            }
          }
        } else if (data['screen'] == 'tutor_rechazado') {
          final context = navigatorKey.currentContext;
          if (context != null) {
            try {
              final homeProvider =
                  Provider.of<TutorHomeProvider>(context, listen: false);
              homeProvider.setRequestRejected(true);
            } catch (e) {
              print('Error al actualizar estado rechazado: $e');
            }
          }
        } else if (data['screen'] == 'tutoria_lista') {
          final context = navigatorKey.currentContext;
          if (context != null) {
            try {
              final homeProvider =
                  Provider.of<TutorHomeProvider>(context, listen: false);

              String link = '';
              var decodificado = data['data_tutor'];
              if (decodificado != null) {
                if (decodificado is String) {
                  decodificado = jsonDecode(decodificado);
                  if (decodificado is String) {
                    decodificado = jsonDecode(decodificado);
                  }
                }
                if (decodificado is Map) {
                  link = decodificado['meet_link'] ??
                      decodificado['meeting_link'] ??
                      '';
                }
              }

              homeProvider.setTutoringReady(link);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => VistaTutoriaLista(meetLink: link)),
              );
            } catch (e) {
              print('Error al procesar tutoria_lista: $e');
            }
          }
        } else if (data['type'] == 'identity_verification_approved') {
          final context = navigatorKey.currentContext;
          if (context != null) {
            try {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              authProvider.setIdentityStatus('accepted');
              authProvider.refreshProfile();
              final homeProvider =
                  Provider.of<TutorHomeProvider>(context, listen: false);
              homeProvider.showVerifiedBannerBriefly();
            } catch (e) {
              print('Error al procesar identity_verification_approved: $e');
            }
          }
        } else if (data['type'] == 'identity_verification_rejected') {
          final context = navigatorKey.currentContext;
          if (context != null) {
            try {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              authProvider.setIdentityStatus('rejected');
              authProvider.refreshProfile();
            } catch (e) {
              print('Error al procesar identity_verification_rejected: $e');
            }
          }
        }
      });

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
      // Ejecutar desuscripciones en paralelo para no bloquear el flujo
      await Future.wait([
        _messaging.unsubscribeFromTopic(_tutorTopic),
        _messaging.unsubscribeFromTopic(_tutorLegacyTopic),
        _messaging.unsubscribeFromTopic(_studentTopic),
      ]).timeout(const Duration(seconds: 2), onTimeout: () => []);

      await _persistCurrentRole('none');
      print('Desuscrito de todos los topics (paralelo)');
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

  /// Suscribirse al topic global mass_notification
  static Future<void> subscribeToMassNotification() async {
    try {
      await _messaging.subscribeToTopic('mass_notification').timeout(const Duration(seconds: 3), onTimeout: () {
        print('Timeout al suscribirse a mass_notification.');
      });
      print('Suscrito al topic global: mass_notification');
    } catch (e) {
      print('Error al suscribirse a mass_notification: $e');
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
    final data = Map<String, dynamic>.from(message.data);
    print('🔔 FCM _handleNavigation recibido. Data: $data');

    final context = navigatorKey.currentContext;
    if (context != null) {
      try {
        final homeProvider =
            Provider.of<TutorHomeProvider>(context, listen: false);
        final screen = data['screen'];
        final type = data['type'];
        if (screen == 'solicitud_detalle' ||
            screen == 'detalle_solicitud' ||
            type == 'solicitud_tutor_personalizada' ||
            type == 'solicitud_flexible') {
          homeProvider.addPendingFlexibleRequest(data);
        }
      } catch (e) {
        print('Error añadiendo desde _handleNavigation: $e');
      }
    }
    _handleNavigationFromData(data, navigatorKey);
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
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const VistaConfirmacion()));
                    },
                  )),
        );
        break;

      case 'tutor_rechazado':
        // Cambiar el estado de la vista de confirmación para mostrar que alguien ya acepto la solicitud
        print('Notificación de tutor rechazado (ya tomada)');
        break;

      case 'tutor_aceptado':
        try {
          final homeProvider =
              Provider.of<TutorHomeProvider>(context, listen: false);
          homeProvider.setRequestChosen(true);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const VistaFuisteElegido()),
          );
        } catch (e) {
          print('Error en navegación tutor_aceptado: $e');
        }
        break;

      case 'solicitud_detalle':
      case 'detalle_solicitud':
        try {
          try {
            final homeProvider =
                Provider.of<TutorHomeProvider>(context, listen: false);
            homeProvider.setPendingFlexibleRequest(data);
          } catch (_) {}

          var decodificado = data['data_tutor'];
          String? tutorToken;
          if (decodificado != null) {
            if (decodificado is String) {
              decodificado = jsonDecode(decodificado);
              if (decodificado is String) {
                decodificado = jsonDecode(decodificado);
              }
            }
            if (decodificado is Map) {
              tutorToken = decodificado['token']?.toString();
            }
          }
          if (tutorToken == null && data['token'] != null) {
            tutorToken = data['token'].toString();
          }

          if (tutorToken != null && tutorToken.isNotEmpty) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ScheduleRequestDetailScreen(token: tutorToken!),
              ),
            );
          } else {
            print('Error: Token de tutor no disponible en la notificación');
          }
        } catch (e) {
          print('Error en navegación de solicitud_detalle: $e');
        }
        break;

      case 'tutoria_lista':
        try {
          final homeProvider =
              Provider.of<TutorHomeProvider>(context, listen: false);
          String link = '';
          var decodificado = data['data_tutor'];
          if (decodificado != null) {
            if (decodificado is String) {
              decodificado = jsonDecode(decodificado);
              if (decodificado is String) {
                decodificado = jsonDecode(decodificado);
              }
            }
            if (decodificado is Map) {
              link = decodificado['meet_link'] ??
                  decodificado['meeting_link'] ??
                  '';
            }
          }
          homeProvider.setTutoringReady(link);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => VistaTutoriaLista(meetLink: link)),
          );
        } catch (e) {
          print('Error en navegación tutoria_lista (background): $e');
        }
        break;

      default:
        if (data['type'] == 'identity_verification_approved') {
          try {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            authProvider.setIdentityStatus('accepted');
            authProvider.refreshProfile();
          } catch (e) {
            print('Error al procesar identity_verification_approved: $e');
          }
        } else if (data['type'] == 'identity_verification_rejected') {
          try {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            authProvider.setIdentityStatus('rejected');
            authProvider.refreshProfile();
          } catch (e) {
            print('Error al procesar identity_verification_rejected: $e');
          }
        } else if (data['type'] == 'solicitud_tutor_personalizada' ||
            data['type'] == 'solicitud_flexible') {
          try {
            final homeProvider =
                Provider.of<TutorHomeProvider>(context, listen: false);
            homeProvider.setPendingFlexibleRequest(data);
          } catch (_) {}
        } else {
          print('Push sin pantalla manejada: ${data['screen']}');
        }
        break;
    }
  }
}
