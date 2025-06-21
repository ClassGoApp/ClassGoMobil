import 'package:flutter/material.dart';

class SlideUpRoute extends PageRouteBuilder {
  final Widget page;
  SlideUpRoute({required this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            // Animación para cuando la ruta ENTRA (se desliza hacia arriba)
            if (animation.status == AnimationStatus.forward) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutExpo;
              final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              final offsetAnimation = animation.drive(tween);

              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            }
            // Animación para cuando la ruta SALE (se desliza hacia abajo)
            // Usamos secondaryAnimation para la transición de salida
            else {
              const begin = Offset.zero;
              const end = Offset(0.0, 1.0);
               const curve = Curves.easeInOutExpo;
              final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              final offsetAnimation = secondaryAnimation.drive(tween);

              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            }
          },
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
        );
} 