import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/home/home_screen.dart';

class BookingSuccessScreen extends StatefulWidget {
  final String tutorName;
  final String tutorImage;
  final String subjectName;
  final String sessionDuration;
  final String amount;
  final String? meetingLink;
  final DateTime? sessionTime;

  const BookingSuccessScreen({
    Key? key,
    required this.tutorName,
    required this.tutorImage,
    required this.subjectName,
    required this.sessionDuration,
    required this.amount,
    this.meetingLink,
    this.sessionTime,
  }) : super(key: key);

  @override
  _BookingSuccessScreenState createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _checkmarkController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _checkmarkScale;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _playSuccessSound();
    _startAnimations();
    _startAutoCloseTimer();
  }

  void _initializeAnimations() {
    // Controlador para el fade
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    // Controlador para el checkmark
    _checkmarkController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    // Animaciones
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _checkmarkScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkmarkController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() {
    _checkmarkController.forward();
    Future.delayed(Duration(milliseconds: 300), () {
      _fadeController.forward();
    });
  }

  void _startAutoCloseTimer() {
    Future.delayed(Duration(seconds: 4), () {
      if (mounted) {
        _navigateToHomeWithReload();
      }
    });
  }

  void _navigateToHomeWithReload() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreenWithLoading(),
      ),
      (route) => false,
    );
  }

  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
      setState(() {
        _isAudioPlaying = true;
      });

      Future.delayed(Duration(seconds: 3), () {
        _audioPlayer.stop();
        setState(() {
          _isAudioPlaying = false;
        });
      });
    } catch (e) {
      print('Error al reproducir audio: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _checkmarkController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.darkBlue,
              AppColors.darkBlue.withOpacity(0.8),
              AppColors.darkBlue.withOpacity(0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Header con logo
                    _buildHeader(),

                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Checkmark animado con Lottie (más grande y centrado)
                          _buildAnimatedCheckmark(),

                          SizedBox(height: 50),

                          // Mensaje de éxito
                          _buildSuccessMessage(),

                          SizedBox(height: 50),

                          // Información de la tutoría
                          _buildTutoringInfo(),

                          SizedBox(height: 50),

                          // Botón de acción
                          _buildActionButton(),
                        ],
                      ),
                    ),

                    // Footer
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Logo pequeño
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.lightBlueColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.school,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'ClassGo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          // Indicador de audio
          if (_isAudioPlaying)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.lightBlueColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.volume_up,
                    color: AppColors.lightBlueColor,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '¡Éxito!',
                    style: TextStyle(
                      color: AppColors.lightBlueColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCheckmark() {
    return AnimatedBuilder(
      animation: _checkmarkController,
      builder: (context, child) {
        return Transform.scale(
          scale: _checkmarkScale.value,
          child: Container(
            width: 300,
            height: 300,
            child: Lottie.asset(
              'assets/animations/Success.json', // ← Nueva animación de éxito
              fit: BoxFit.contain,
              repeat: false,
              animate: true,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessMessage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Text(
            '¡Gracias por tu tutoría!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'En unos segundos, verás el estado en tiempo real.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTutoringInfo() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.lightBlueColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Información del tutor
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage(widget.tutorImage),
                  backgroundColor: Colors.grey[300],
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tutorName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.subjectName,
                        style: TextStyle(
                          color: AppColors.lightBlueColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Detalles de la sesión
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  icon: Icons.access_time,
                  label: 'Duración',
                  value: widget.sessionDuration,
                ),
                _buildInfoItem(
                  icon: Icons.payment,
                  label: 'Monto',
                  value: widget.amount,
                ),
              ],
            ),

            if (widget.sessionTime != null) ...[
              SizedBox(height: 12),
              _buildInfoItem(
                icon: Icons.calendar_today,
                label: 'Fecha',
                value:
                    '${widget.sessionTime!.day}/${widget.sessionTime!.month}/${widget.sessionTime!.year}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.lightBlueColor,
          size: 20,
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 20),
        child: ElevatedButton(
          onPressed: _navigateToHomeWithReload,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.lightBlueColor,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: AppColors.lightBlueColor.withOpacity(0.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.home,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Volver al inicio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            '¡Tu aprendizaje comienza ahora!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star,
                color: AppColors.lightBlueColor,
                size: 16,
              ),
              SizedBox(width: 4),
              Text(
                'ClassGo - Tu plataforma de aprendizaje',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Pantalla de loading con recarga del HomeScreen
class HomeScreenWithLoading extends StatefulWidget {
  @override
  _HomeScreenWithLoadingState createState() => _HomeScreenWithLoadingState();
}

class _HomeScreenWithLoadingState extends State<HomeScreenWithLoading>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _loadHomeScreen();
  }

  void _initializeAnimations() {
    _rotationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
  }

  void _loadHomeScreen() {
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.darkBlue,
              AppColors.darkBlue.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animado
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.lightBlueColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.lightBlueColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: 40),

              // Texto de carga
              Text(
                'Cargando...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),

              SizedBox(height: 20),

              // Indicador de progreso
              Container(
                width: 200,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.lightBlueColor),
                ),
              ),

              SizedBox(height: 30),

              // Texto descriptivo
              Text(
                'Actualizando tu información',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
