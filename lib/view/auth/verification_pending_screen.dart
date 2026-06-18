import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/helpers/simple_deep_link_handler.dart';
import 'package:flutter_projects/helpers/email_verification_helper.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';

class VerificationPendingScreen extends StatefulWidget {
  final Map<String, dynamic> userData; // Datos del usuario registrado
  

  const VerificationPendingScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<VerificationPendingScreen> createState() =>
      _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends State<VerificationPendingScreen>
    with TickerProviderStateMixin {
  bool _isResending = false;

  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  
  late AnimationController _animationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 60;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_cooldownSeconds > 0) {
          _cooldownSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
    });

    try {
      final String token = widget.userData['token'] ?? 
        widget.userData['response']?['data']?['token'] ?? 
        '';

      final String email = widget.userData['email'] ?? 
        widget.userData['response']?['data']?['user']?['email'] ?? 
        '';

      if (token.isEmpty) {
        if (mounted) {
          CustomToast.show(
            context, 
            'Tu sesión expiró o hubo un problema. Por favor, inicia sesión de nuevo.', 
            isSuccess: false
          );
        }
        return;
      }
      
      if (email.isEmpty) {
        if (mounted) {
          CustomToast.show(
            context, 
            'Email no disponible. Verifica tus datos.', 
            isSuccess: false
          );
        }
        return;
      }

      final result = await EmailVerificationHelper.resendVerificationEmail(token);
      
      final String mensajeBackend = result['message'] ?? '';
      final bool isSuccess = (result['success'] == true) || mensajeBackend.contains('successfully');

      if (mounted) {
        if (isSuccess) {
          CustomToast.show(
            context, 
            '¡Correo enviado correctamente! Revisa tu bandeja de entrada.',
            isSuccess: true
          );
          
          _startCooldown();
        } else {
          CustomToast.show(
            context, 
            mensajeBackend.isNotEmpty ? mensajeBackend : 'No se pudo reenviar el correo.',
            isSuccess: false
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          'No pudimos conectarnos. Por favor, revisa tu internet e inténtalo de nuevo.',
          isSuccess: false
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.darkBlue, AppColors.blurprimary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),            

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Icono animado de email
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, 5 * _animationController.value),
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.lightBlueColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.lightBlueColor,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.lightBlueColor
                                          .withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.email_outlined,
                                  color: AppColors.lightBlueColor,
                                  size: 60,
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 32),
                    
                        // Título
                        Text(
                          '¡Registro exitoso!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                    
                        // Mensaje principal
                        Text(
                          'Hemos enviado un email de verificación a:',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                    
                        // Email del usuario
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.lightBlueColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.userData['email'] ?? 'email@ejemplo.com',
                            style: TextStyle(
                              color: AppColors.lightBlueColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                    
                        // Instrucciones
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.green, size: 20),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Revisa tu bandeja de entrada',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.green, size: 20),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Haz clic en el enlace de verificación',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.green, size: 20),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Tu cuenta se activará automáticamente',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 32),
                    
                        // Botón de reenviar email
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1.0 + (_pulseController.value * 0.05),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: (_isResending || _cooldownSeconds > 0)
                                      ? null
                                      : _resendVerificationEmail,
                                  icon: _isResending
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          _cooldownSeconds > 0 ? Icons.timer : Icons.refresh, 
                                          color: Colors.white
                                        ),
                                  label: Text(
                                    _isResending
                                        ? 'Reenviando...'
                                        : _cooldownSeconds > 0
                                            ? 'Reenviar en ${_cooldownSeconds}s'
                                            : 'Reenviar email',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.orangeprimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 24),
                    
                        // Enlace al login
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => LoginScreen()),
                              (Route<dynamic> route) => false,
                            );
                          },
                          child: Text(
                            '¿Ya tienes cuenta? Inicia sesión',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
