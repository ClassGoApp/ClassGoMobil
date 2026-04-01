import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui'; // 🚀 IMPORTANTE: Necesario para que el reloj no baile (FontFeature)
import 'package:flutter_projects/styles/app_styles.dart';

// Importa tus otras pantallas
import 'package:flutter_projects/view/student/instant_tutoring/widgets/booking_success_screen.dart';
import 'package:flutter_projects/view/student/instant_tutoring/widgets/student_payment_screen.dart';

// Importa tus modelos y el painter
import 'radar_painter.dart';
import 'tutor_model.dart'; 

// 🎯 FUENTES CENTRALIZADAS
const String _kFontFamily = 'manrope';
const String _kTitleFont = 'outfit';

class RadarSearchScreen extends StatefulWidget {
  final String subjectName;
  final int timerSeconds;

  const RadarSearchScreen({
    super.key,
    required this.subjectName,
    this.timerSeconds = 120, // 2 minutos de búsqueda
  });

  @override
  State<RadarSearchScreen> createState() => _RadarSearchScreenState();
}

class _RadarSearchScreenState extends State<RadarSearchScreen> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  late Timer _countdownTimer;
  int _currentSeconds = 0;
  
  bool _isSearching = true;
  List<TutorResponse> _acceptedTutors = [];

  @override
  void initState() {
    super.initState();
    _currentSeconds = widget.timerSeconds;
    _radarController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _startTimer();
    
    // Simula la respuesta del backend
    _simulateBackendResponses();
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

  void _simulateBackendResponses() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() {
        _acceptedTutors.add(dummyFoundTutors[0]);
        _isSearching = false; 
      });
    });
    Future.delayed(const Duration(seconds: 7), () {
      if (mounted) setState(() => _acceptedTutors.add(dummyFoundTutors[1]));
    });
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) setState(() => _acceptedTutors.add(dummyFoundTutors[2]));
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

  // ==========================================
  // VISTA 1: RADAR (Neo-clean)
  // ==========================================
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
             //  ESTO EVITA QUE EL RELOJ BAILE
          ),
        ),
        const SizedBox(height: 4),
        const Text("Buscando tutores...", style: TextStyle(fontFamily: _kFontFamily, color: AppColors.greyColor, fontSize: 16, fontWeight: FontWeight.w500)),
        
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
            style: const TextStyle(fontFamily: _kTitleFont, color: AppColors.brandBlue, fontWeight: FontWeight.w800, fontSize: 16),
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
                          return CustomPaint(painter: RadarPainter(_radarController.value));
                        },
                      ),
                    ),
                    
                    // Pulso central
                    AnimatedBuilder(
                      animation: _radarController,
                      builder: (context, child) {
                        return Container(
                          width: 65 + (30 * sin(_radarController.value * pi * 2).abs()),
                          height: 65 + (30 * sin(_radarController.value * pi * 2).abs()),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.brandCyan.withOpacity(0.3), width: 1.5),
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
                          BoxShadow(color: AppColors.brandBlue.withOpacity(0.15), blurRadius: 20, spreadRadius: 2)
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.school_rounded, color: AppColors.brandBlue, size: 32),
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
            child: const Text("Cancelar Búsqueda", style: TextStyle(fontFamily: _kFontFamily, color: AppColors.redColor, fontSize: 16, fontWeight: FontWeight.w600)),
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
                  const Text("Tutores Listos", style: TextStyle(fontFamily: _kTitleFont, fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.blackColor)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.whiteColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.dividerColor)),
                    child: Text(
                      _formatTime(_currentSeconds), 
                      style: const TextStyle(
                        fontFamily: _kTitleFont, 
                        color: AppColors.brandBlue, 
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()], // 🚀 APLICADO AL RELOJ PEQUEÑO TAMBIÉN
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Text("Han respondido a tu solicitud de ${widget.subjectName}.", style: const TextStyle(fontFamily: _kFontFamily, color: AppColors.greyColor, fontSize: 14)),
            ],
          ),
        ),
        
        // La Lista Flexible (Para 1 o 100 tutores)
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: _acceptedTutors.length,
            itemBuilder: (context, index) {
              final tutor = _acceptedTutors[index];
              return _buildTutorCard(tutor, index);
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // WIDGET: TARJETA DE TUTOR
  // ==========================================
  Widget _buildTutorCard(TutorResponse tutor, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.blackColor.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 🚀 SOLUCIÓN AL ERROR DE IMAGEN: Inteligencia para saber si es Web o Local (Assets)
              CircleAvatar(
                radius: 28, 
                backgroundImage: tutor.avatarUrl.startsWith('http')
                    ? NetworkImage(tutor.avatarUrl) as ImageProvider
                    : AssetImage(tutor.avatarUrl), 
                backgroundColor: AppColors.fadeColor,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(tutor.name, style: const TextStyle(fontFamily: _kTitleFont, fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.blackColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        if (tutor.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: AppColors.brandBlue, size: 16),
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text("Disponible ahora", style: TextStyle(fontFamily: _kFontFamily, fontSize: 13, color: AppColors.stateSuccess, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(tutor.pricePerHour, style: const TextStyle(fontFamily: _kTitleFont, fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.brandBlue)),
                  const Text("Total aprox.", style: TextStyle(fontFamily: _kFontFamily, fontSize: 11, color: AppColors.greyColor)),
                ],
              )
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: AppColors.dividerColor)),
          Row(
            children: [
              // Botón Rechazar
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() => _acceptedTutors.removeAt(index));
                    if (_acceptedTutors.isEmpty) setState(() => _isSearching = true);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Rechazar", style: TextStyle(fontFamily: _kFontFamily, color: AppColors.greyColor, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              // Botón Aceptar (Navega al pago)
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentPaymentScreen(
                          tutor: tutor,
                          subjectName: widget.subjectName,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandCyan, 
                      padding: const EdgeInsets.symmetric(vertical: 14), 
                      elevation: 0, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
                  ),
                  child: const Text("Aceptar", style: TextStyle(fontFamily: _kFontFamily, color: AppColors.whiteColor, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}