import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/config/app_config.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/provider/connectivity_provider.dart';
import 'package:flutter_projects/provider/settings_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/components/internet_alert.dart';
import 'package:flutter_projects/view/tutor/search_tutors_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/view/home/home_screen.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:flutter_projects/helpers/pusher_service.dart';
import 'package:flutter_projects/services/deep_link_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'helpers/firebase_messaging_service.dart';
import 'package:flutter_projects/view/tutor/dashboard_tutor.dart';
import 'package:flutter_projects/view/components/role_based_navigation.dart';
import 'package:flutter_projects/provider/booking_provider.dart';
import 'package:flutter_projects/provider/tutor_subjects_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:io';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase de forma opcional
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDs5zKv82dGel5tUUIWE7MsLLyEBCKNW1g',
        appId: '1:934911540456:android:306f0e768c07edede45d5d',
        messagingSenderId: '934911540456',
        projectId: 'classgo-fec0d',
        storageBucket: 'classgo-fec0d.firebasestorage.app',
      ),
    );
    firebaseInitialized = true;
    print('¡Firebase inicializado correctamente!');
  } catch (e) {
    print('Error al inicializar Firebase: $e');
    print('La aplicación continuará sin Firebase');
  }

  // Inicializar Firebase Messaging solo si Firebase se inicializó correctamente
  if (firebaseInitialized) {
    try {
      // Verificar si estamos en Android antes de inicializar Firebase Messaging
      bool isAndroid = Platform.isAndroid;
      print('Plataforma Android: $isAndroid');

      if (isAndroid) {
        await FirebaseMessagingService.initialize();
      } else {
        print('No es Android. Firebase Messaging omitido.');
      }
    } catch (e) {
      print('Error al inicializar Firebase Messaging: $e');
      print('La aplicación continuará sin notificaciones push');
    }
  } else {
    print('Firebase Messaging omitido - Firebase no está disponible');
  }

  try {
    await AppConfig().getSettings();
  } catch (e) {
    print('Error al obtener configuraciones: $e');
  }

  runApp(const MyApp());
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
      DeepLinkService().initialize(navigatorKey.currentContext!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (context) => PusherService()),
        ChangeNotifierProvider(create: (context) => BookingProvider()),
        ChangeNotifierProvider(create: (context) => TutorSubjectsProvider()),
      ],
      child: OverlaySupport.global(
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: 'ClassGo',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es'),
            Locale('en'),
          ],
          home: RoleBasedNavigation(),
        ),
      ),
    );
  }
}
