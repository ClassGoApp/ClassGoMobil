import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_projects/config/firebase_options.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/provider/connectivity_provider.dart';
import 'package:flutter_projects/provider/settings_provider.dart';
import 'package:flutter_projects/services/notification_topic_service.dart';
import 'package:flutter_projects/view/splash/splash_transicion.dart';
import 'package:flutter_projects/view/tutor/features/agenda/providers/tutor_agenda_provider.dart';
import 'package:flutter_projects/view/tutor/features/home/providers/tutor_home_provider.dart';
import 'package:provider/provider.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:flutter_projects/helpers/pusher_service.dart';
import 'package:flutter_projects/services/deep_link_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'helpers/firebase_messaging_service.dart';
import 'package:flutter_projects/provider/booking_provider.dart';
import 'package:flutter_projects/provider/tutor_subjects_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_projects/provider/theme_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. ESCUDO 1: Atrapa errores de renderizado en los Widgets (Evita la pantalla roja)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint("🔴 ERROR DE WIDGET ATRAPADO: ${details.exception}");
    return Material(
      color: Colors.redAccent.withOpacity(0.1),
      child: Center(
        child: Text(
          "Error en este bloque.\nRevisa la consola.",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      ),
    );
  };

  // 3. ESCUDO 2: Atrapa errores lógicos de Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint("🔴 FLUTTER ERROR GLOBAL: ${details.exceptionAsString()}");
    FlutterError.presentError(details);
  };

  // 4. ESCUDO 3: Atrapa errores asíncronos y de código Dart profundo
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint("🔴 ERROR NATIVO/ASÍNCRONO: $error");
    return true; // Devuelve true para decirle al sistema "Ya lo manejé, no cierres la app"
  };

  bool firebaseInitialized = false;
  try {
    // Inicializacion idempotente: evita duplicate-app en relanzamientos/hot-restart.
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } on FirebaseException catch (e) {
        // Si otra inicializacion se adelanto, lo tratamos como valido.
        if (e.code != 'duplicate-app') {
          rethrow;
        }
      }
    }

    firebaseInitialized = true;
    print('¡Firebase inicializado correctamente!');
  } catch (e) {
    print('Error al inicializar Firebase: $e');
  }

  // El resto de tu lógica de Messaging y Config...
  if (firebaseInitialized) {
    //await FirebaseMessagingService.initialize(navigatorKey: navigatorKey);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => PusherService()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => TutorSubjectsProvider()),
        ChangeNotifierProvider(create: (_) => TutorHomeProvider()),
        ChangeNotifierProvider(create: (_) => TutorAgendaProvider()),
        ChangeNotifierProvider(create: (_) => TutorSubjectsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Inicializar el servicio de deep links después de que el widget esté montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationTopicService.requestPermissionOnFirstLaunch();
      NotificationTopicService.subscribeToMassNotification();
      DeepLinkService().initialize(navigatorKey.currentContext!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return OverlaySupport.global(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'ClassGo',
        debugShowCheckedModeBanner: false,
        themeMode: themeProvider.themeMode,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es'),
          Locale('en'),
        ],
        home: SplashTransicion(),
      ),
    );
  }
}
