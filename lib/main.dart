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
import 'package:firebase_core/firebase_core.dart';
import 'helpers/firebase_messaging_service.dart';
import 'package:flutter_projects/provider/tutorias_provider.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_projects/view/bookings/bookings.dart';
import 'package:audioplayers/audioplayers.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyDs5zKv82dGel5tUUIWE7MsLLyEBCKNW1g',
      appId: '1:934911540456:android:306f0e768c07edede45d5d',
      messagingSenderId: '934911540456',
      projectId: 'classgo-fec0d',
      storageBucket: 'classgo-fec0d.firebasestorage.app',
    ),
  );
  await FirebaseMessagingService.initialize();
  print('¡Firebase inicializado correctamente!');

  try {
    await AppConfig().getSettings();
  } catch (e) {}

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _sub;
  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _handleInitialDeepLink(); // <-- Llamada para manejar el deep link inicial
  }

  Future<void> _initDeepLinks() async {
    _sub = _appLinks.uriLinkStream.listen((Uri? uri) async {
      print('Deep link recibido: $uri');
      if (uri != null && uri.scheme == 'classgo' && uri.host == 'verify') {
        final id = uri.queryParameters['id'];
        final hash = uri.queryParameters['hash'];
        print('ID recibido: $id');
        print('Hash de query recibido: $hash');
        if (id != null && hash != null) {
          final context = navigatorKey.currentContext;
          if (context != null) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => Center(child: CircularProgressIndicator()),
            );
          }
          try {
            final url =
                'https://classgoapp.com/api/verify-email?id=$id&hash=$hash';
            print('URL construida para verificación: $url');
            final response = await http.get(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
            );
            print('Respuesta cruda del backend: ${response.body}');
            if (context != null)
              Navigator.of(context, rootNavigator: true).pop();
            if (response.statusCode == 200) {
              final data = json.decode(response.body);
              print('Respuesta decodificada del backend: $data');
              if (data['status'] == true || data['success'] == true) {
                final token = data['token'];
                final user = data['user'];
                print('Token recibido del backend: $token');
                print('User recibido del backend: $user');
                if (token != null && user != null) {
                  final authProvider = Provider.of<AuthProvider>(
                      navigatorKey.currentContext!,
                      listen: false);
                  await authProvider.setToken(token);
                  await authProvider.setUserData(user);
                  print('Token y usuario guardados en AuthProvider');
                  // Obtener datos completos del usuario
                  try {
                    final userId = user['id'];
                    final profileUrl =
                        'https://classgoapp.com/api/user/$userId/profile-image';
                    print('Consultando perfil completo en: $profileUrl');
                    final profileResponse = await http.get(
                      Uri.parse(profileUrl),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer $token',
                      },
                    );
                    print(
                        'Respuesta cruda del perfil: \n${profileResponse.body}');
                    if (profileResponse.statusCode == 200) {
                      final profileData = json.decode(profileResponse.body);
                      print('Perfil decodificado: $profileData');
                      // Adaptar estructura para la UI y para el ProfileScreen
                      final adaptedProfileData = {
                        'user': {
                          'id': profileData['id'],
                          'email': profileData['email'],
                        },
                        'profile': {
                          'first_name':
                              profileData['name']?.split(' ')?.first ?? '',
                          'last_name': profileData['name']
                                  ?.split(' ')
                                  ?.skip(1)
                                  .join(' ') ??
                              '',
                          'full_name': profileData['name'] ?? '',
                          'image': profileData['profile_image'],
                        },
                      };
                      print('Perfil adaptado para la UI: $adaptedProfileData');
                      await authProvider.setUserData(adaptedProfileData);
                      print('Perfil completo guardado en AuthProvider');
                    } else {
                      print(
                          'No se pudo obtener el perfil completo. Código: ${profileResponse.statusCode}');
                    }
                  } catch (e) {
                    print('Error al obtener el perfil completo: $e');
                  }
                } else {
                  print('Token o usuario nulos, no se guardó sesión');
                }
                if (context != null) {
                  // Reproducir sonido de éxito
                  final player = AudioPlayer();
                  player.play(AssetSource('sounds/success.mp3'));
                  // Mostrar mensaje flotante
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(data['message'] ??
                          '¡Correo verificado correctamente!'),
                      duration: Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(
                        showVerificationSuccess: true,
                        verificationMessage: data['message'] ??
                            '¡Correo verificado correctamente!',
                      ),
                    ),
                    (route) => false,
                  );
                }
              } else {
                print('Verificación fallida o sin éxito: ${data['message']}');
                if (context != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(data['message'] ??
                            'No se pudo verificar el correo.')),
                  );
                }
              }
            } else {
              print(
                  'Error HTTP al verificar el correo: ${response.statusCode}');
              if (context != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al verificar el correo.')),
                );
              }
            }
          } catch (e) {
            print('Excepción al verificar el correo: $e');
            final context = navigatorKey.currentContext;
            if (context != null) {
              Navigator.of(context, rootNavigator: true).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error de red al verificar el correo.')),
              );
            }
          }
        }
      }
    }, onError: (err) {
      print('Error en el stream de deep links: $err');
    });
  }

  Future<void> _handleInitialDeepLink() async {
    try {
      final initialUri = await _appLinks.getInitialAppLink();
      print('Initial deep link recibido: $initialUri');
      if (initialUri != null &&
          initialUri.scheme == 'classgo' &&
          initialUri.host == 'verify') {
        final id = initialUri.queryParameters['id'];
        final hash = initialUri.queryParameters['hash'];
        print('ID recibido (initial): $id');
        print('Hash de query recibido (initial): $hash');
        if (id != null && hash != null) {
          final context = navigatorKey.currentContext;
          if (context != null) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => Center(child: CircularProgressIndicator()),
            );
          }
          try {
            final url =
                'https://classgoapp.com/api/verify-email?id=$id&hash=$hash';
            print('URL construida para verificación (initial): $url');
            final response = await http.get(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
            );
            print('Respuesta cruda del backend (initial): ${response.body}');
            if (context != null)
              Navigator.of(context, rootNavigator: true).pop();
            if (response.statusCode == 200) {
              final data = json.decode(response.body);
              print('Respuesta decodificada del backend (initial): $data');
              if (data['status'] == true || data['success'] == true) {
                final token = data['token'];
                final user = data['user'];
                print('Token recibido del backend (initial): $token');
                print('User recibido del backend (initial): $user');
                if (token != null && user != null) {
                  final authProvider = Provider.of<AuthProvider>(
                      navigatorKey.currentContext!,
                      listen: false);
                  await authProvider.setToken(token);
                  await authProvider.setUserData(user);
                  print('Token y usuario guardados en AuthProvider (initial)');
                  // Obtener datos completos del usuario
                  try {
                    final userId = user['id'];
                    final profileUrl =
                        'https://classgoapp.com/api/user/$userId/profile-image';
                    print('Consultando perfil completo en: $profileUrl');
                    final profileResponse = await http.get(
                      Uri.parse(profileUrl),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer $token',
                      },
                    );
                    print(
                        'Respuesta cruda del perfil (initial): \n${profileResponse.body}');
                    if (profileResponse.statusCode == 200) {
                      final profileData = json.decode(profileResponse.body);
                      print('Perfil decodificado (initial): $profileData');
                      // Adaptar estructura para la UI y para el ProfileScreen
                      final adaptedProfileData = {
                        'user': {
                          'id': profileData['id'],
                          'email': profileData['email'],
                        },
                        'profile': {
                          'first_name':
                              profileData['name']?.split(' ')?.first ?? '',
                          'last_name': profileData['name']
                                  ?.split(' ')
                                  ?.skip(1)
                                  .join(' ') ??
                              '',
                          'full_name': profileData['name'] ?? '',
                          'image': profileData['profile_image'],
                        },
                      };
                      print(
                          'Perfil adaptado para la UI (initial): $adaptedProfileData');
                      await authProvider.setUserData(adaptedProfileData);
                      print(
                          'Perfil completo guardado en AuthProvider (initial)');
                    } else {
                      print(
                          'No se pudo obtener el perfil completo (initial). Código: ${profileResponse.statusCode}');
                    }
                  } catch (e) {
                    print('Error al obtener el perfil completo (initial): $e');
                  }
                } else {
                  print('Token o usuario nulos, no se guardó sesión (initial)');
                }
                if (context != null) {
                  // Reproducir sonido de éxito
                  final player = AudioPlayer();
                  player.play(AssetSource('sounds/success.mp3'));
                  // Mostrar mensaje flotante
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(data['message'] ??
                          '¡Correo verificado correctamente!'),
                      duration: Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(
                        showVerificationSuccess: true,
                        verificationMessage: data['message'] ??
                            '¡Correo verificado correctamente!',
                      ),
                    ),
                    (route) => false,
                  );
                }
              } else {
                print(
                    'Verificación fallida o sin éxito (initial): ${data['message']}');
                if (context != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(data['message'] ??
                            'No se pudo verificar el correo.')),
                  );
                }
              }
            } else {
              print(
                  'Error HTTP al verificar el correo (initial): ${response.statusCode}');
              if (context != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al verificar el correo.')),
                );
              }
            }
          } catch (e) {
            print('Excepción al verificar el correo (initial): $e');
            final context = navigatorKey.currentContext;
            if (context != null) {
              Navigator.of(context, rootNavigator: true).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error de red al verificar el correo.')),
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error obteniendo el deep link inicial: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (context) => PusherService()),
        ChangeNotifierProxyProvider<AuthProvider, TutoriasProvider>(
          create: (context) => TutoriasProvider(
              authProvider: Provider.of<AuthProvider>(context, listen: false)),
          update: (context, authProvider, previous) =>
              TutoriasProvider(authProvider: authProvider),
        ),
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
          home: HomeScreen(),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Lernen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: Center(
        child: SvgPicture.asset(
          AppImages.splash,
          width: MediaQuery.of(context).size.width * 0.4,
          height: MediaQuery.of(context).size.height * 0.4,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class Lernen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, _) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        if (!connectivityProvider.isConnected) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: AppColors.backgroundColor,
              body: Center(
                child: InternetAlertDialog(
                  onRetry: () async {
                    await connectivityProvider.checkInitialConnection();
                    (context as Element).reassemble();
                  },
                ),
              ),
            ),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: authProvider.isLoggedIn ? SearchTutorsScreen() : LoginScreen(),
        );
      },
    );
  }
}
