import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/student/instant_tutoring/logic/radar_controller.dart';
import 'package:flutter_projects/view/student/instant_tutoring/widgets/tutor_card.dart';
import 'package:flutter_projects/view/student/instant_tutoring/widgets/student_payment_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'dart:math';
import 'package:http/http.dart' as http;


// Importa tu nuevo controlador y el RadarPainter
// import 'radar_controller.dyyart'; 
import 'radar_painter.dart';

const String _kFontFamily = 'manrope';
const String _kTitleFont = 'outfit';

class RadarSearchScreen extends StatefulWidget {
  final String subjectName;
  final String subjectId;
  final int timerSeconds;

  const RadarSearchScreen({
    super.key,
    required this.subjectName,
    required this.subjectId,
    this.timerSeconds = 300,
  });

  @override
  State<RadarSearchScreen> createState() => _RadarSearchScreenState();
}

class _RadarSearchScreenState extends State<RadarSearchScreen> with SingleTickerProviderStateMixin {
  late AnimationController _radarAnimController;
  late RadarController _logicController;

  @override
  void initState() {
    super.initState();
    // Animación visual
    _radarAnimController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    // Instanciamos el cerebro
    _logicController = RadarController(subjectId: widget.subjectId, initialSeconds: widget.timerSeconds);
  }

  @override
  void dispose() {
    _radarAnimController.dispose();
    _logicController.dispose(); // Importante: mata los timers
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        // ListenableBuilder escucha al cerebro y redibuja la pantalla cuando cambian los datos
        child: ListenableBuilder(
          listenable: _logicController,
          builder: (context, _) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _logicController.isSearching 
                  ? _buildRadarView() 
                  : _buildFoundTutorsView(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRadarView() {
    return Column(
      
      key: const ValueKey('radar'),
      children: [
        ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
  onPressed: () async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    
    final response = await http.get(
      Uri.parse('http://192.168.0.145:8000/api/force-fcm'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
       print("🔥 ¡Petición enviada desde el móvil! FELICIDADES asjasjdsaasjfa");
    } else {
       print("❌ Error: ${response.statusCode}");
       print("📄 DETALLE DEL ERROR: ${response.body}");
    }
  },
  child: const Text("PROBAR NOTIFICACIÓN AHORA", style: TextStyle(color: Colors.white)),
),
        const SizedBox(height: 30),
        Text(
          _formatTime(_logicController.currentSeconds),
          style: const TextStyle(
            fontFamily: _kTitleFont, fontSize: 48, fontWeight: FontWeight.w800,
            color: AppColors.brandBlue, fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        const Text("Buscando tutores...",
            style: TextStyle(fontFamily: _kFontFamily, color: AppColors.greyColor, fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.brandBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.brandBlue.withOpacity(0.1)),
          ),
          child: Text(
            widget.subjectName,
            style: const TextStyle(fontFamily: _kTitleFont, color: AppColors.brandBlue, fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),

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
                        animation: _radarAnimController,
                        builder: (context, child) => CustomPaint(painter: RadarPainter(_radarAnimController.value)),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _radarAnimController,
                      builder: (context, child) {
                        return Container(
                          width: 65 + (30 * sin(_radarAnimController.value * pi * 2).abs()),
                          height: 65 + (30 * sin(_radarAnimController.value * pi * 2).abs()),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.brandCyan.withOpacity(0.3), width: 1.5)),
                        );
                      },
                    ),
                    Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.whiteColor, boxShadow: [BoxShadow(color: AppColors.brandBlue.withOpacity(0.15), blurRadius: 20)]),
                      child: const Center(child: Icon(Icons.school_rounded, color: AppColors.brandBlue, size: 32)),
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
  // VISTA 2: LISTA DE TUTORES
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
                      _formatTime(_logicController.currentSeconds),
                      style: const TextStyle(fontFamily: _kTitleFont, color: AppColors.brandBlue, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Text("Han respondido a tu solicitud de ${widget.subjectName}.", style: const TextStyle(fontFamily: _kFontFamily, color: AppColors.greyColor, fontSize: 14)),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: _logicController.acceptedTutors.length,
            itemBuilder: (context, index) {
              final tutor = _logicController.acceptedTutors[index];

              return TutorCard(
                tutor: tutor,
                subjectName: widget.subjectName,
                onReject: () => _logicController.removeTutor(index), // Todo se maneja en el cerebro
                onAccept: () async {
                  if (_logicController.isProcessing) return; // Evita doble click

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Confirmando tutor...'), duration: Duration(seconds: 1)));
                  
                  // Llamamos al cerebro para reservar
                  final resultado = await _logicController.confirmTutor(tutor.id);

                  if (context.mounted) {
                    if (resultado['success'] == true) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentPaymentScreen(
                            tutor: tutor,
                            subjectName: widget.subjectName,
                            bookingId: resultado['booking_id'], // Obtenido directo de la nueva API
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(resultado['message'] ?? 'Error al elegir tutor'), backgroundColor: Colors.red),
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