import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/home/home_screen.dart';

class ThankYouPage extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool showButton;
  final VoidCallback? onButtonPressed;

  const ThankYouPage({
    Key? key,
    this.title = '¡Listo! Tu tutoría está reservada',
    this.subtitle = 'En unos segundos verás el detalle de tu reserva.',
    this.showButton = true,
    this.onButtonPressed,
  }) : super(key: key);

  @override
  _ThankYouPageState createState() => _ThankYouPageState();
}

class _ThankYouPageState extends State<ThankYouPage> {
  double _opacity = 0.0;
  double _scale = 0.5;
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _showLoading = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: Duration(seconds: 2));
    _startAnimation();
    _autoClose();
    _playSuccessSound();
  }

  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'), volume: 0.8);
    } catch (e) {
      // Si falla, no hacer nada
    }
  }

  void _startAnimation() {
    Timer(Duration(milliseconds: 400), () {
      setState(() {
        _opacity = 1.0;
        _scale = 1.0;
      });
      _confettiController.play();
    });
  }

  void _autoClose() {
    // Después de 3 segundos, mostrar el loader y navegar a home
    Timer(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showLoading = true;
        });

        // Después de mostrar el loader por 1 segundo, navegar a home
        Timer(Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(forceRefresh: true),
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si está mostrando el loader, mostrar solo el gif de cargando
    if (_showLoading) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          color: Color(0xFF17223B),
          child: Image.asset(
            'assets/images/cargando.gif',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.lightBlueColor, AppColors.primaryGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                emissionFrequency: 0.12,
                numberOfParticles: 30,
                maxBlastForce: 30,
                minBlastForce: 10,
                gravity: 0.25,
                colors: [
                  Colors.white,
                  AppColors.primaryGreen,
                  AppColors.lightBlueColor,
                  Colors.amber,
                  Colors.pinkAccent,
                ],
              ),
            ),
            // Contenido principal
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedOpacity(
                    opacity: _opacity,
                    duration: Duration(milliseconds: 800),
                    child: AnimatedScale(
                      scale: _scale,
                      duration: Duration(milliseconds: 900),
                      curve: Curves.elasticOut,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(24),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primaryGreen,
                          size: 110,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'SF-Pro-Text',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.white.withOpacity(0.92),
                      fontWeight: FontWeight.w400,
                      fontFamily: 'SF-Pro-Text',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),
                  if (widget.showButton)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: ElevatedButton(
                        onPressed: widget.onButtonPressed ??
                            () {
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                            },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                        ),
                        child: Text(
                          'Ir al inicio',
                          style: TextStyle(
                            fontSize: 17,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SF-Pro-Text',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
