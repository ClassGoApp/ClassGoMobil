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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    
  try {
    await AppConfig().getSettings();
  } catch (e) {}

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => ConnectivityProvider()),
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
