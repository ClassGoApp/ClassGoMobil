import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/view/student/instant_tutoring/widgets/tutor_card.dart';
import 'package:flutter_projects/view/student/reservations/paymentQR/payment_qr_screen.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'dart:ui';
import 'package:flutter_projects/styles/app_styles.dart';

import 'package:flutter_projects/view/student/instant_tutoring/widgets/booking_success_screen.dart';
import 'package:flutter_projects/view/student/instant_tutoring/widgets/student_payment_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'radar_painter.dart';
import 'tutor_model.dart';

// 🎯 FUENTES CENTRALIZADAS
const String _kFontFamily = 'manrope';
const String _kTitleFont = 'outfit';

class RadarSearchScreen extends StatefulWidget {
  final String subjectName;
  final int timerSeconds;
  final String subjectId;

  const RadarSearchScreen({
    super.key,
    required this.subjectName,
    required this.subjectId,
    this.timerSeconds = 500,
  });

  @override
  State<RadarSearchScreen> createState() => _RadarSearchScreenState();
}

class _RadarSearchScreenState extends State<RadarSearchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  late Timer _countdownTimer;
  int _currentSeconds = 0;

  bool _isSearching = true;
  List<TutorResponse> _acceptedTutors = [];

  String? _batchId;

  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _currentSeconds = widget.timerSeconds;
    _radarController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
    _startTimer();

    // Simula la respuesta del backend
    _iniciarBusquedaEnLaravel();
  }

  // CONEXIÓN AL BACKEND: CREAR EL BATCH
  Future<void> _iniciarBusquedaEnLaravel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        print("❌ Error: No hay token guardado. El usuario no está logueado.");
        // Redirigir a LoginScreen
        return;
      }

      final data = await startRadarSearch(widget.subjectId, token);

      _batchId = data['batch_id']?.toString() ?? data['id']?.toString();
      print("✅ BATCH ID GUARDADO: $_batchId");

      final String? expiresAtStr = data['expires_at'];

      if (expiresAtStr != null) {
        final DateTime expiresAt = DateTime.parse(expiresAtStr);
        final int secondsLeft = expiresAt.difference(DateTime.now()).inSeconds;

        if (mounted) {
          setState(() {
            _currentSeconds = secondsLeft > 0 ? secondsLeft : 0;
          });
        }
      }

      print(
          "✅ BATCH ID GUARDADO: $_batchId - Segundos restantes: $_currentSeconds");

      // 4. Iniciamos el 'polling' para preguntar quién aceptó
      _escucharRespuestasDeTutores();
    } on TokenExpiredException catch (_) {
      print("❌ El token expiró. Redirigiendo a Login...");
    } catch (e) {
      print("🔥 Error en la búsqueda: $e");
    }
  }

  void _escucharRespuestasDeTutores() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_batchId == null) return;

      try {
        final prefs = await SharedPreferences.getInstance();
        final miToken = prefs.getString('token') ?? '';

        final jsonResponse = await pollAcceptedTutors(_batchId!, miToken);
        final List<dynamic> candidatosNuevos = jsonResponse['data'] ?? [];

        if (candidatosNuevos.isNotEmpty) {
          if (mounted) {
            setState(() {
              _isSearching = false;

              _acceptedTutors = candidatosNuevos.map<TutorResponse>((json) {
              String imagenDelTutor = json['image'] ?? 'assets/images/default_avatar.png';

              if (!imagenDelTutor.startsWith('http') && !imagenDelTutor.startsWith('assets')) {
                if (!imagenDelTutor.startsWith('/')) {
                  imagenDelTutor = '/$imagenDelTutor';
                }
                imagenDelTutor = '$storageBaseUrl$imagenDelTutor';
              }
                return TutorResponse(
                  id: json['id'] ?? 0,
                  name:
                      "${json['first_name'] ?? 'Tutor'} ${json['last_name'] ?? ''}"
                          .trim(),
                  avatarUrl:
                      imagenDelTutor, 
                  isVerified:
                      json['is_verified'] == 1 || json['is_verified'] == true,
                  pricePerHour: "${json['price'] ?? '0.00'} Bs",
                  rating:
                      double.tryParse(json['rating']?.toString() ?? '5.0') ??
                          5.0,
                );
              }).toList();
            });
          }
        }
      } catch (e) {
        print("Error en polling: $e");
      }
    });
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_currentSeconds > 0) {
          _currentSeconds--;
        } else {
          timer.cancel();
          _radarController.stop();
        }
      });
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _radarController.dispose();
    _countdownTimer.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _isSearching ? _buildRadarView() : _buildFoundTutorsView(),
        ),
      ),
    );
  }

  Widget _buildRadarView() {
    return Column(
      key: const ValueKey('radar'),
      children: [
        const SizedBox(height: 30),

        Text(
          _formatTime(_currentSeconds),
          style: const TextStyle(
            fontFamily: _kTitleFont,
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: AppColors.brandBlue,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        const Text("Buscando tutores...",
            style: TextStyle(
                fontFamily: _kFontFamily,
                color: AppColors.greyColor,
                fontSize: 16,
                fontWeight: FontWeight.w500)),

        const SizedBox(height: 16),

        // PASTILLA DE MATERIA EXTERNA
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.brandBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.brandBlue.withOpacity(0.1)),
          ),
          child: Text(
            widget.subjectName,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: _kTitleFont,
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w800,
                fontSize: 16),
          ),
        ),

        // RADAR CENTRADO PERFECTAMENTE
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: AnimatedBuilder(
                        animation: _radarController,
                        builder: (context, child) {
                          return CustomPaint(
                              painter: RadarPainter(_radarController.value));
                        },
                      ),
                    ),

                    // Pulso central
                    AnimatedBuilder(
                      animation: _radarController,
                      builder: (context, child) {
                        return Container(
                          width: 65 +
                              (30 * sin(_radarController.value * pi * 2).abs()),
                          height: 65 +
                              (30 * sin(_radarController.value * pi * 2).abs()),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.brandCyan.withOpacity(0.3),
                                width: 1.5),
                          ),
                        );
                      },
                    ),

                    // Ícono Limpio en el medio
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.whiteColor,
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.brandBlue.withOpacity(0.15),
                              blurRadius: 20,
                              spreadRadius: 2)
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.school_rounded,
                            color: AppColors.brandBlue, size: 32),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar Búsqueda",
                style: TextStyle(
                    fontFamily: _kFontFamily,
                    color: AppColors.redColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // VISTA 2: LISTA DE TUTORES ENCONTRADOS
  // ==========================================
  Widget _buildFoundTutorsView() {
    return Column(
      key: const ValueKey('list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Tutores Listos",
                      style: TextStyle(
                          fontFamily: _kTitleFont,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.blackColor)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.dividerColor)),
                    child: Text(
                      _formatTime(_currentSeconds),
                      style: const TextStyle(
                        fontFamily: _kTitleFont,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [
                          FontFeature.tabularFigures()
                        ], // 🚀 APLICADO AL RELOJ PEQUEÑO TAMBIÉN
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Text("Han respondido a tu solicitud de ${widget.subjectName}.",
                  style: const TextStyle(
                      fontFamily: _kFontFamily,
                      color: AppColors.greyColor,
                      fontSize: 14)),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: _acceptedTutors.length,
            itemBuilder: (context, index) {
              final tutor = _acceptedTutors[index];

              return TutorCard(
                tutor: tutor,
                subjectName: widget.subjectName,
                onReject: () {
                  setState(() => _acceptedTutors.removeAt(index));
                  if (_acceptedTutors.isEmpty)
                    setState(() => _isSearching = true);
                },

                onAccept: () async {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Confirmando tutor...'),
                          duration: Duration(seconds: 1)),
                    );

                    final prefs = await SharedPreferences.getInstance();
                    final miToken = prefs.getString('token') ?? '';

                    final resultado = await crearReserva(
                        int.parse(_batchId!), tutor.id, miToken);

                    if (resultado['success'] == true) {
                      
                      int elNuevoBookingId = resultado['booking_id'];

                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentPaymentScreen(
                              tutor: tutor,
                              subjectName: widget.subjectName,
                              bookingId: elNuevoBookingId,
                            ),
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(resultado['message'] ?? 'Error al elegir tutor'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString().replaceAll('Exception: ', '')),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
