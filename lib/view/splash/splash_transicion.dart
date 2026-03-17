import 'package:flutter/material.dart';
import 'package:flutter_projects/view/components/role_based_navigation.dart';

class SplashTransicion extends StatefulWidget {
  @override
  _SplashTransicionState createState() => _SplashTransicionState();
}

class _SplashTransicionState extends State<SplashTransicion> {
  @override
  void initState() {
    super.initState();
    _iniciarMagia();
  }

  _iniciarMagia() async {
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              RoleBasedNavigation(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration:
              const Duration(milliseconds: 800), 
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF113644), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              tween: Tween(begin: 140.0, end: 180.0),
              duration: Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Image.asset(
                  'assets/images/logo.png',
                  width: value,
                );
              },
            ),
            const SizedBox(height: 25),

            Image.asset(
              'assets/images/logo_classgo.png',
              width: 180, 
            ),
          ],
        ),
      ),
    );
  }
}
