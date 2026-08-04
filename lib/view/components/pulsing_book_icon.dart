import 'package:flutter/material.dart';

/// Widget animado con icono de libro que pulsa (latido) continuamente
/// Usado en perfil de estudiante para darle vida dinámica a la interfaz
class PulsingBookIcon extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;

  const PulsingBookIcon({
    Key? key,
    this.color = const Color(0xFFFB8500), // Naranja por defecto
    this.size = 24.0,
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<PulsingBookIcon> createState() => _PulsingBookIconState();
}

class _PulsingBookIconState extends State<PulsingBookIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(); // Loop continuo

    // Animación: 1.0 → 1.15 → 1.0
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(
        Icons.book_rounded,
        color: widget.color,
        size: widget.size,
      ),
    );
  }
}
