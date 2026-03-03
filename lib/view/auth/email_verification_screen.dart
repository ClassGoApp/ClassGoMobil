import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/helpers/email_verification_helper.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/components/role_based_navigation.dart';
import 'package:flutter_projects/helpers/auth_helper.dart';
import 'package:flutter_projects/view/components/success_verification_dialog.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String verificationHash;

  EmailVerificationScreen({
    Key? key,
    required this.verificationId,
    required this.verificationHash,
  }) : super(key: key) {
    print('EmailVerificationScreen: constructor - id: ' +
        verificationId +
        ', hash: ' +
        verificationHash);
  }

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with TickerProviderStateMixin {
  bool _isVerifying = true;
  bool _isVerified = false;
  bool _isError = false;
  String _errorMessage = '';
  late AnimationController _animationController;
  late AnimationController _successController;

  @override
  void initState() {
    super.initState();
    print('EmailVerificationScreen: initState');
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _successController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _verifyEmail();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    try {
      print('Iniciando verificación de email...');
      print('ID: ${widget.verificationId}, Hash: ${widget.verificationHash}');

      final result = await EmailVerificationHelper.verifyEmail(
        widget.verificationId,
        widget.verificationHash,
      );

      print('Resultado de verificación: $result');

      if (mounted) {
        setState(() {
          _isVerifying = false;
          _isVerified = result['success'];
          _isError = !result['success'];
          if (!result['success']) {
            _errorMessage = result['message'] ??
                'El enlace de verificación no es válido o ha expirado.';
          }
        });

        if (result['success']) {
          print('Verificación exitosa, procesando datos del usuario...');
          // Guardar token y datos del usuario si vienen en la respuesta (dentro de result['data'])
          final data = result['data'] ?? {};
          final token = data['token'];
          final user = data['user'];

          print('Token recibido: ${token != null ? 'Sí' : 'No'}');
          print('Datos de usuario recibidos: ${user != null ? 'Sí' : 'No'}');

          if (token != null && user != null) {
            print('Guardando datos de autenticación...');
            await AuthHelper.loginAfterVerification(context, token, user);
            print('Datos de autenticación guardados exitosamente');
          } else {
            print('No se recibieron token o datos de usuario en la respuesta');
          }

          // Mostrar modal de éxito con sonido y cerrar automáticamente
          if (mounted) {
            print('Mostrando modal de éxito...');
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => SuccessVerificationDialog(),
            );
            // Esperar 2 segundos y luego cerrar el modal y navegar a Home
            await Future.delayed(Duration(seconds: 2));
            if (mounted) {
              print('Navegando a RoleBasedNavigation...');
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => RoleBasedNavigation()),
                (Route<dynamic> route) => false,
              );
            }
          }
        } else {
          print('Verificación fallida: ${result['message']}');
          // Mostrar mensaje de error
          EmailVerificationHelper.showResultSnackBar(context, result);
        }
      }
    } catch (e) {
      print('Error durante la verificación: $e');
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _isError = true;
          _errorMessage =
              'Error al verificar el email. Por favor, inténtalo de nuevo.';
        });

        EmailVerificationHelper.showResultSnackBar(
          context,
          {
            'success': false,
            'message':
                'Error de conexión. Verifica tu internet e inténtalo de nuevo.',
          },
        );
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.lightBlueColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.email_outlined,
                    color: AppColors.lightBlueColor,
                    size: 60,
                  ),
                ),
                SizedBox(height: 32),

                if (_isVerifying) ...[
                  // Animación de verificación
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _animationController.value * 2 * 3.14159,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.lightBlueColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.lightBlueColor,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.verified_outlined,
                              color: AppColors.lightBlueColor,
                              size: 40,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Verificando tu cuenta...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Estamos verificando tu email. Esto puede tomar unos segundos.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else if (_isVerified) ...[
                  // Éxito
                  AnimatedBuilder(
                    animation: _successController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.8 + (_successController.value * 0.2),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.green,
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 60,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 24),
                  Text(
                    '¡Cuenta verificada!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Tu cuenta ha sido verificada exitosamente. Te estamos redirigiendo...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  // Error
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Error de verificación',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => LoginScreen()),
                              (Route<dynamic> route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Ir al Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _verifyEmail(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orangeprimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Reintentar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
