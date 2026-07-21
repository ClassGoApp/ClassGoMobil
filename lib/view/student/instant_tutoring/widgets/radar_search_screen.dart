import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/student/instant_tutoring/logic/radar_controller.dart';
import 'package:flutter_projects/view/student/instant_tutoring/widgets/tutor_card.dart';
import 'package:flutter_projects/view/student/instant_tutoring/widgets/student_payment_screen.dart';
import 'package:flutter_projects/view/student/reservations/request_schedule_screen.dart';
import 'dart:math';

import 'radar_painter.dart';

const String _kFontFamily = 'manrope';
const String _kTitleFont = 'outfit';

class RadarSearchScreen extends StatefulWidget {
  final String subjectName;
  final String subjectId;
  final int timerSeconds;
  final bool isRecovered;

  const RadarSearchScreen({
    super.key,
    required this.subjectName,
    required this.subjectId,
    this.timerSeconds = 300,
    required this.isRecovered,
  });

  @override
  State<RadarSearchScreen> createState() => _RadarSearchScreenState();
}

class _RadarSearchScreenState extends State<RadarSearchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarAnimController;
  late RadarController _logicController;

  @override
  void initState() {
    super.initState();
    _radarAnimController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _logicController = RadarController(subjectId: widget.subjectId, initialSeconds: widget.timerSeconds);

    if (widget.isRecovered) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Retomando tu tutoría activa'),
              backgroundColor: AppColors.brandBlue,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _radarAnimController.dispose();
    _logicController.dispose();
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
        child: ListenableBuilder(
          listenable: _logicController,
          builder: (context, _) {
            if (_logicController.isTimeout &&
                _radarAnimController.isAnimating) {
              _radarAnimController.stop();
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: (_logicController.isSearching || _logicController.isTimeout)
                  ? _buildRadarView()
                  : _buildFoundTutorsView(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRadarView() {
    final isTimeout = _logicController.isTimeout;

    return Column(
      key: const ValueKey('radar'),
      children: [
        const SizedBox(height: 60),
        
        Text(
          _formatTime(_logicController.currentSeconds),
          style: TextStyle(
            fontFamily: _kTitleFont,
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: isTimeout ? AppColors.redColor : AppColors.brandBlue,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isTimeout
              ? "El tiempo terminó. Ningún tutor disponible."
              : "Buscando tutores...",
          style: TextStyle(
              fontFamily: _kFontFamily,
              color: isTimeout ? AppColors.redColor : AppColors.greyColor,
              fontSize: 16,
              fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
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
            style: const TextStyle(
                fontFamily: _kTitleFont,
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w800,
                fontSize: 16),
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
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.whiteColor,
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.brandBlue.withOpacity(0.15),
                                blurRadius: 20)
                          ]),
                      child: Icon(
                          isTimeout
                              ? Icons.timer_off_rounded
                              : Icons.school_rounded,
                          color: isTimeout
                              ? AppColors.redColor
                              : AppColors.brandBlue,
                          size: 32),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isTimeout)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandCyan,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      final int subId = int.tryParse(widget.subjectId) ?? 0;
                      final subjectMap = {'id': subId, 'name': widget.subjectName};
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RequestScheduleScreen(
                            subjects: [subjectMap],
                            selectedSubject: subjectMap,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.more_time, color: Colors.white),
                    label: const Text(
                      "Solicitar Horario",
                      style: TextStyle(fontFamily: _kFontFamily, fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Nueva solicitud",
                      style: TextStyle(fontFamily: _kFontFamily, fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          const Spacer(),
          TextButton.icon(
            onPressed: _logicController.isCancelling
                ? null
                : () => _confirmCancel(context),
            icon: _logicController.isCancelling
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.redColor,
                    ),
                  )
                : const Icon(Icons.close_rounded, size: 20),
            label: Text(
              _logicController.isCancelling
                  ? "Cancelando..."
                  : "Cancelar búsqueda",
              style: const TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.redColor,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Cancelar búsqueda",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "¿Seguro que deseas cancelar esta solicitud de tutoría? Podrás volver a elegir otra materia e intentarlo de nuevo.",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "No, volver",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Sí, cancelar",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await _logicController.cancelBatch();
      if (ok && mounted) {
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No se pudo cancelar la solicitud"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
                      _formatTime(_logicController.currentSeconds),
                      style: const TextStyle(
                          fontFamily: _kTitleFont,
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()]),
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
            itemCount: _logicController.acceptedTutors.length,
            itemBuilder: (context, index) {
              final tutor = _logicController.acceptedTutors[index];

              return TutorCard(
                tutor: tutor,
                subjectName: widget.subjectName,
                onReject: () => _logicController.removeTutor(index),
                onAccept: () async {
                  if (_logicController.isProcessing) return;

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Confirmando tutor...'),
                      duration: Duration(seconds: 1)));

                  final resultado =
                      await _logicController.confirmTutor(tutor.id);

                  if (context.mounted) {
                    if (resultado['success'] == true) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentPaymentScreen(
                            tutor: tutor,
                            subjectName: widget.subjectName,
                            bookingId: resultado['booking_id'],
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(resultado['message'] ??
                                'Error al elegir tutor'),
                            backgroundColor: Colors.red),
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
