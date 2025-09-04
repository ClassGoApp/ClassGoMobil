import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class SuccessAnimationDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onContinue;
  final bool autoClose;
  final Duration autoCloseDuration;
  final bool playSound;

  const SuccessAnimationDialog({
    Key? key,
    required this.title,
    required this.message,
    this.buttonText,
    this.onContinue,
    this.autoClose = true,
    this.autoCloseDuration = const Duration(seconds: 3),
    this.playSound = true,
  }) : super(key: key);

  @override
  _SuccessAnimationDialogState createState() => _SuccessAnimationDialogState();
}

class _SuccessAnimationDialogState extends State<SuccessAnimationDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    if (widget.playSound) {
      _playSuccessSound();
    }
    if (widget.autoClose) {
      _startAutoCloseTimer();
    }
  }

  void _initializeAnimations() {
    // Controlador para el scale
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    // Controlador para el fade
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    // Animaciones
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
  }

  void _startAnimations() {
    _scaleController.forward();
    Future.delayed(Duration(milliseconds: 200), () {
      _fadeController.forward();
    });
  }

  void _startAutoCloseTimer() {
    Future.delayed(widget.autoCloseDuration, () {
      if (mounted) {
        Navigator.of(context).pop();
        if (widget.onContinue != null) {
          widget.onContinue!();
        }
      }
    });
  }

  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
      setState(() {
        _isAudioPlaying = true;
      });

      // Se detiene después de 3 segundos
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isAudioPlaying = false;
          });
        }
      });
    } catch (e) {
      print('Error al reproducir audio: $e');
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.darkBlue.withOpacity(0.98),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animación Lottie
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 200,
                    height: 200,
                    child: Lottie.asset(
                      'assets/animations/Success.json',
                      fit: BoxFit.contain,
                      repeat: false,
                      animate: true,
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 24),

            // Título
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                widget.title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: 16),

            // Mensaje
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                widget.message,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Indicador de audio si está reproduciéndose
            if (_isAudioPlaying) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_up,
                      color: AppColors.primaryGreen,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '¡Éxito!',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Botón de continuar (opcional)
            if (widget.buttonText != null && widget.onContinue != null) ...[
              SizedBox(height: 32),
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.primaryGreen.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onContinue!();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    widget.buttonText!,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Función helper para mostrar el diálogo de éxito
void showSuccessDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? buttonText,
  VoidCallback? onContinue,
  bool autoClose = true,
  Duration autoCloseDuration = const Duration(seconds: 3),
  bool playSound = true,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => SuccessAnimationDialog(
      title: title,
      message: message,
      buttonText: buttonText,
      onContinue: onContinue,
      autoClose: autoClose,
      autoCloseDuration: autoCloseDuration,
      playSound: playSound,
    ),
  );
}
