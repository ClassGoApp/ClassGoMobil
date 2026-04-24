import 'package:flutter/material.dart';

class SincronizacionAnimada extends StatefulWidget {
  const SincronizacionAnimada({Key? key}) : super(key: key);

  @override
  State<SincronizacionAnimada> createState() => _SincronizacionAnimadaState();
}

class _SincronizacionAnimadaState extends State<SincronizacionAnimada>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Este controlador durará 2 segundos en dar una vuelta y se repetirá infinitamente
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDF0F2), width: 1.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Envolvemos SOLO el ícono en la rotación
          RotationTransition(
            turns: _controller,
            child: const Icon(
              Icons.refresh,
              color: Color(0xFF26A2B8),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'SINCRONIZANDO...',
            style: TextStyle(
              color: Color(0xFF26A2B8),
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
