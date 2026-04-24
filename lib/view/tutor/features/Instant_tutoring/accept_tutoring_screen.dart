import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/tutor/features/Instant_tutoring/model/tutor.dart';
import 'package:flutter_projects/view/tutor/features/home/providers/tutor_home_provider.dart';
import 'package:provider/provider.dart';

class AcceptTutoringScreen extends StatefulWidget {
  final data_tutor;
  final VoidCallback onEnterWaitingRoom;

  const AcceptTutoringScreen({
    Key? key,
    required this.data_tutor,
    required this.onEnterWaitingRoom,
  }) : super(key: key);

  @override
  State<AcceptTutoringScreen> createState() => _AcceptTutoringScreenState();
}

class _AcceptTutoringScreenState extends State<AcceptTutoringScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // NUEVO: Variable para controlar el estado de carga del botón
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // NUEVO: Método extraído para obtener la data parseada en cualquier lugar
  Map<String, dynamic> _obtenerDataParseada() {
    Map<String, dynamic> data = {};
    try {
      if (widget.data_tutor is Map) {
        data = Map<String, dynamic>.from(widget.data_tutor);
      } else if (widget.data_tutor is String) {
        var decodificado = jsonDecode(widget.data_tutor);
        if (decodificado is String) {
          decodificado = jsonDecode(decodificado);
        }
        data = Map<String, dynamic>.from(decodificado);
      }
    } catch (e) {
      print("Error al decodificar la data del tutor: $e");
      data = {
        'nombre': 'Estudiante',
        'materia': 'Cargando...',
      };
    }
    return data;
  }

  // NUEVO: Función que se ejecuta al presionar el botón
  Future<void> _aceptarTutoria() async {
    setState(() {
      _isLoading = true; // Iniciamos la carga
    });

    try {
      // 1. Obtener el token de autenticación del usuario (Ajusta esto según tu Provider)
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final tokenAuth = authProvider.token ?? '';
      //String tokenAuth =
      //"TU_TOKEN_DE_AUTH_AQUI"; // REEMPLAZAR por la línea de arriba

      // 2. Extraer el token_accept de la data
      print("Data recibida en _aceptarTutoria: ${widget.data_tutor}");
      final data = _obtenerDataParseada();
      final tokenAccept = data['accept_token'];

      if (tokenAccept == null) {
        throw Exception("No se encontró el token de aceptación de la sala.");
      }

      // 3. Llamar a tu función HTTP
      await tutorAceptWaitlist(tokenAuth, tokenAccept.toString());

      // 4. Registrar la hora de inicio de la confirmación para evitar reinicios del contador
      final homeProvider =
          Provider.of<TutorHomeProvider>(context, listen: false);
      homeProvider.setConfirmationStartTime(DateTime.now());

      // 5. Si todo sale bien, ejecutamos la redirección
      widget.onEnterWaitingRoom();
    } catch (e) {
      // Si hay un error (ej. el backend devuelve 400 o 500), mostramos un mensaje
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Asegurarnos de apagar el estado de carga suceda lo que suceda
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // MODIFICADO: Usamos el nuevo método para limpiar el código del build
    Map<String, dynamic> data = _obtenerDataParseada();
    Tutor tutor = Tutor.fromJson(data);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _construirEncabezado(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 30.0),
                      child: Column(
                        children: [
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Column(
                                children: [
                                  _construirIconoNotificacion(),
                                  const SizedBox(height: 24),
                                  Text(
                                    '¡Hola, ${tutor.nombre}!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF003049),
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Fuiste solicitado para dar\nuna tutoría al instante de:",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF7A8B99),
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.brandCyan.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.brandCyan
                                              .withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      tutor.materia,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.brandCyan,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    // MODIFICADO: Llamamos a nuestra nueva función o deshabilitamos si está cargando
                                    onPressed:
                                        _isLoading ? null : _aceptarTutoria,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.brandOrange,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      // Deshabilitar color cuando isLoading es true
                                      disabledBackgroundColor: AppColors
                                          .brandOrange
                                          .withOpacity(0.6),
                                    ),
                                    // MODIFICADO: Mostramos el texto o el indicador de carga
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            "Entrar a sala de espera",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  // Bloquear el botón volver si está cargando
                                  onPressed: _isLoading
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  child: Text(
                                    "Volver",
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : const Color(0xFF7A8B99),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- MÉTODOS PRIVADOS ---
  // (Mantén aquí _construirEncabezado() y _construirIconoNotificacion() igual que antes)

  Widget _construirEncabezado() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF00445E),
            Color(0xFF26A2B8),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: const [
          Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
          SizedBox(width: 10),
          Text(
            'TUTORÍA AL INSTANTE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirIconoNotificacion() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.brandOrange.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: AppColors.brandOrange.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.notifications_active_rounded,
          size: 50,
          color: AppColors.brandOrange,
        ),
      ),
    );
  }
}
