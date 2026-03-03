import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/config/app_config.dart';
import 'package:flutter_projects/config/firebase_options.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/provider/connectivity_provider.dart';
import 'package:flutter_projects/provider/settings_provider.dart';
import 'package:flutter_projects/view/tutor/features/agenda/providers/tutor_agenda_provider.dart';
import 'package:flutter_projects/view/tutor/features/home/providers/tutor_home_provider.dart';
import 'package:provider/provider.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:flutter_projects/helpers/pusher_service.dart';
import 'package:flutter_projects/services/deep_link_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'helpers/firebase_messaging_service.dart';
import 'package:flutter_projects/view/components/role_based_navigation.dart';
import 'package:flutter_projects/provider/booking_provider.dart';
import 'package:flutter_projects/provider/tutor_subjects_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:io';
import 'package:flutter_projects/provider/theme_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseInitialized = false;
  try {
    // CAMBIO AQUÍ: Solo inicializa si no hay apps activas
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.android,
      );
    }
    firebaseInitialized = true;
    print('¡Firebase inicializado correctamente!');
  } catch (e) {
    print('Error al inicializar Firebase: $e');
  }

  // El resto de tu lógica de Messaging y Config...
  if (firebaseInitialized) {
    // ... tu código de Messaging
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
          home: RoleBasedNavigation(),
        ),
    );
  }
}
