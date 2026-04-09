import 'package:flutter/material.dart';

class LupaAnimada extends StatefulWidget {
  const LupaAnimada({Key? key}) : super(key: key);

  @override
  State<LupaAnimada> createState() => _LupaAnimadaState();
}

class _LupaAnimadaState extends State<LupaAnimada>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animacionOpacidad;

  @override
  void initState() {
    super.initState();
    // Configura la duración del latido (1 segundo) y le dice que se repita de ida y vuelta
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Crea la transición de opacidad del 40% al 100%
    _animacionOpacidad = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // ¡Muy importante para liberar memoria!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animacionOpacidad,
      child: Container(
        padding: const EdgeInsets.all(35),
        decoration: const BoxDecoration(
          color: Color(0xFFDDF0F2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.search,
          size: 60,
          color: Color(0xFF26A2B8),
        ),
      ),
    );
  }
}
