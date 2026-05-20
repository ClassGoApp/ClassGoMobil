import 'dart:convert';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/layout/main_shell.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_projects/base_components/textfield.dart';
import 'package:flutter_projects/view/auth/register_screen.dart';
import 'package:flutter_projects/view/auth/reset_password_screen.dart';
import 'package:flutter_projects/view/home/home_screen.dart';
import 'package:flutter_projects/view/tutor/dashboard_tutor.dart';
import 'package:flutter_projects/helpers/back_button_handler.dart';
import 'package:flutter_projects/view/components/role_based_navigation.dart';

class LoginScreen extends StatefulWidget {
  final Map<String, dynamic>? registrationResponse;
  LoginScreen({this.registrationResponse});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  bool _isChecked = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isEmailValid = true;
  String _errorMessage = '';
  String _passwordErrorMessage = '';
  bool _isPasswordValid = true;
  bool _isLoading = false;

  static bool isValidEmail(String email) {
    bool emailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
    return emailValid;
  }

  void _validateEmailAndSubmit() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    setState(() {
      if (email.isEmpty) {
        _errorMessage = 'El correo no puede estar vacío';
        _isEmailValid = false;
      } else if (isValidEmail(email)) {
        _errorMessage = '';
        _isEmailValid = true;
      } else {
        _errorMessage = 'Ingresa un correo válido';
        _isEmailValid = false;
      }
      if (password.isEmpty) {
        _passwordErrorMessage = 'La contraseña no puede estar vacía';
        _isPasswordValid = false;
      } else if (password.length < 6) {
        _passwordErrorMessage =
            'La contraseña debe tener al menos 6 caracteres';
        _isPasswordValid = false;
      } else {
        _passwordErrorMessage = '';
        _isPasswordValid = true;
      }
    });

    if (_isEmailValid && _isPasswordValid) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await loginUser(email, password);
        print('Login API Response: $response');
        final String token = response['data']['token'];
        final Map<String, dynamic> userData = response['data'];
        print('Extracted User Data after login: $userData');
        print('Token extraído del login: $token');
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        print('Llamando a setToken...');
        await authProvider.setToken(token);
        print('setToken completado');

        print('Llamando a setUserData...');
        await authProvider.setUserData(userData);
        print('setUserData completado');

        print('Llamando a setAuthToken...');
        await authProvider.setAuthToken(token);
        print('setAuthToken completado');

        setState(() {
          _isLoading = false;
        });

        // Redirigir según el rol
        final String? role = userData['user']?['role'];
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => RoleBasedNavigation()),
          (route) => false,
        );

        _emailController.clear();
        _passwordController.clear();
        showCustomToast(
          context,
          'Inicio de sesión exitoso',
          true,
        );
      } catch (error) {
        print('Login API call failed: $error');
        final errorMessage = error.toString();
        if (errorMessage.contains("Not verified")) {
          _openBottomSheet(context);
          showCustomToast(
            context,
            'Tu correo no está verificado. Revisa tu bandeja y confirma tu cuenta.',
            false,
          );
        } else if (errorMessage.contains("CSRF token mismatch.")) {
          showCustomToast(
            context,
            'El servidor no está disponible. Intenta nuevamente más tarde.',
            false,
          );
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: Text(
                'Servidor temporalmente fuera de servicio',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontSize: FontSize.scale(context, 18),
                  color: AppColors.blackColor,
                  fontFamily: 'SF-Pro-Text',
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.normal,
                ),
              ),
              content: Text(
                'El servidor no está disponible en este momento. Por favor intenta de nuevo más tarde.',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontSize: FontSize.scale(context, 14),
                  color: AppColors.blackColor,
                  fontFamily: 'SF-Pro-Text',
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'OK',
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: FontSize.scale(context, 14),
                      color: AppColors.blackColor,
                      fontFamily: 'SF-Pro-Text',
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          showCustomToast(
            context,
            'No se pudo iniciar sesión. Revisa tus datos e inténtalo de nuevo.',
            false,
          );
        }
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      if (!_isEmailValid) {
        _emailFocusNode.requestFocus();
      } else if (!_isPasswordValid) {
        _passwordFocusNode.requestFocus();
      }
    }
  }

  void showCustomToast(BuildContext context, String message, bool isSuccess) {
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100.0,
        left: 16.0,
        right: 16.0,
        child: CustomToast(
          message: message,
          isSuccess: isSuccess,
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  void handleResendEmail() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String? _token = authProvider.token;

    if (_token != null) {
      try {
        final response = await resendEmail(_token);
        Navigator.pop(context);
        showCustomToast(
          context,
          'Hemos reenviado el correo. Revisa tu bandeja de entrada para verificar tu cuenta.',
          true,
        );
      } catch (error) {
        showCustomToast(
          context,
          'No se pudo reenviar el correo. Intenta de nuevo más tarde.',
          false,
        );
      }
    } else {
      showCustomToast(
        context,
        'No se encontró sesión activa. Por favor vuelve a iniciar sesión.',
        false,
      );
    }
  }

  void _openBottomSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: AppColors.backgroundColor,
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(10.0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.topBottomSheetDismissColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  'Verificación de correo',
                  style: TextStyle(
                    fontSize: FontSize.scale(context, 18),
                    color: AppColors.blackColor,
                    fontFamily: 'SF-Pro-Text',
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.normal,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                    borderRadius: BorderRadius.circular(8.0),
                    color: AppColors.whiteColor),
                child: ElevatedButton(
                  onPressed: () {
                    handleResendEmail();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Text(
                    'Volver a enviar correo',
                    style: TextStyle(
                      fontSize: FontSize.scale(context, 16),
                      color: AppColors.whiteColor,
                      fontFamily: 'SF-Pro-Text',
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveTokenToProvider(String token) {
    print('_saveTokenToProvider llamado con token: $token');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    print('AuthProvider obtenido, llamando a setAuthToken...');
    authProvider.setAuthToken(token);
    print('_saveTokenToProvider completado');
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      print('🟢 GOOGLE ID TOKEN => $idToken');
      if (idToken == null) {
        throw Exception('No se pudo obtener el token de Google');
      }

      final response = await http.post(
        Uri.parse('https://classgoapp.com/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error backend Google login');
      }

      final data = jsonDecode(response.body);

      // 🔥 CLAVE: data debe ser IGUAL al login normal
      await authProvider.setToken(data['token']);
      await authProvider.setUserData(data);
      await authProvider.setAuthToken(data['token']);

      // ❌ NO navegues
      // RoleBasedNavigation se encarga solo
    } catch (e, stacktrace) {
      print('🔴 ERROR REAL: $e');
      print('📜 STACKTRACE: $stacktrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión con Google')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    if (widget.registrationResponse != null) {
      print(
          'LoginScreen: registrationResponse encontrado: ${widget.registrationResponse}');
      final String? token = widget.registrationResponse?['data']['token'];
      print('LoginScreen: token extraído del registrationResponse: $token');
      if (token != null) {
        print('LoginScreen: llamando a _saveTokenToProvider...');
        _saveTokenToProvider(token);
      } else {
        print('LoginScreen: token es null en registrationResponse');
      }
    } else {
      print('LoginScreen: no hay registrationResponse');
    }

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () => BackButtonHandler.handleBackButton(
        context,
        isLoading: _isLoading,
      ),
      child: Scaffold(
          backgroundColor: AppColors.primaryGreen,
          body: Container(
            height: height,
            child: Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, right: 20),
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const HomeScreen()),
                                (Route<dynamic> route) => false,
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'INICIO',
                                  style: TextStyle(
                                    color: AppColors.whiteColor,
                                    fontSize: FontSize.scale(context, 15),
                                    fontFamily: 'SF-Pro-Text',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: SvgPicture.asset(
                                    AppImages.forwardArrow,
                                    width: 15,
                                    height: 15,
                                    color: AppColors.whiteColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SvgPicture.asset(
                                    AppImages.logo,
                                    width: 150,
                                    height: 150,
                                    alignment: Alignment.center,
                                  ),
                                  SizedBox(height: 20),
                                  Column(
                                    children: [
                                      Text(
                                        'Inicia sesión en tu cuenta',
                                        style: TextStyle(
                                          fontFamily: 'SF-Pro-Text',
                                          fontWeight: FontWeight.w700,
                                          fontSize: FontSize.scale(context, 24),
                                          color: AppColors.whiteColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: height * 0.01),
                                      Text(
                                        'Accede a cursos, administra tu agenda,\ny mantente conectado.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'SF-Pro-Text',
                                          fontWeight: FontWeight.w400,
                                          fontSize: FontSize.scale(context, 16),
                                          color: AppColors.whiteColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: height * 0.06),
                                  CustomTextField(
                                    hint: 'Correo electrónico',
                                    obscureText: false,
                                    controller: _emailController,
                                    focusNode: _emailFocusNode,
                                    hasError: !_isEmailValid,
                                  ),
                                  if (_errorMessage.isNotEmpty)
                                    Padding(
                                      padding:
                                          EdgeInsets.only(top: height * 0.01),
                                      child: Text(
                                        _errorMessage,
                                        style: TextStyle(
                                            color: AppColors.redColor),
                                      ),
                                    ),
                                  SizedBox(height: height * 0.02),
                                  CustomTextField(
                                    hint: 'Contraseña',
                                    obscureText: true,
                                    controller: _passwordController,
                                    focusNode: _passwordFocusNode,
                                    hasError: !_isPasswordValid,
                                  ),
                                  if (_passwordErrorMessage.isNotEmpty)
                                    Padding(
                                      padding:
                                          EdgeInsets.only(top: height * 0.01),
                                      child: Text(
                                        _passwordErrorMessage,
                                        style: TextStyle(
                                            color: AppColors.redColor),
                                      ),
                                    ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Transform.translate(
                                        offset: Offset(-10, 0),
                                        child: Transform.scale(
                                          scale: 1.3,
                                          child: Checkbox(
                                            value: _isChecked,
                                            checkColor: AppColors.whiteColor,
                                            activeColor: AppColors.primaryGreen,
                                            fillColor: WidgetStateProperty
                                                .resolveWith<Color>((states) {
                                              if (states.contains(
                                                  WidgetState.selected)) {
                                                return AppColors.primaryGreen;
                                              }
                                              return AppColors.whiteColor;
                                            }),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                            ),
                                            side: BorderSide(
                                              color: AppColors.dividerColor,
                                              width: 1.5,
                                            ),
                                            onChanged: (bool? value) {
                                              setState(() {
                                                _isChecked = value ?? false;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      Transform.translate(
                                        offset: Offset(-12, 0),
                                        child: Text(
                                          'Recordar cuenta en dispositivo',
                                          style: TextStyle(
                                            fontSize:
                                                FontSize.scale(context, 16),
                                            color: AppColors.whiteColor,
                                            fontFamily: 'SF-Pro-Text',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: height * 0.024),
                                  ElevatedButton(
                                    onPressed: _validateEmailAndSubmit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.lightBlueColor,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Ingresar',
                                      style: TextStyle(
                                        color: AppColors.whiteColor,
                                        fontSize: FontSize.scale(context, 16),
                                        fontFamily: 'SF-Pro-Text',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                ResetPassword()),
                                      );
                                    },
                                    child: Text(
                                      '¿Olvidaste tu contraseña?',
                                      style: TextStyle(
                                        fontSize: FontSize.scale(context, 16),
                                        color: AppColors.whiteColor,
                                        fontFamily: 'SF-Pro-Text',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    decoration: ShapeDecoration(
                                      color: AppColors.whiteColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  RegistrationScreen()),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 15, horizontal: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        backgroundColor: AppColors.primaryGreen,
                                      ),
                                      child: Text(
                                        '¿No tienes una cuenta?, Regístrate',
                                        style: TextStyle(
                                          color: AppColors.whiteColor,
                                          fontSize: FontSize.scale(context, 16),
                                          fontFamily: 'SF-Pro-Text',
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: height * 0.02),
                                  //   ElevatedButton.icon(
                                  //     icon: Image.asset(
                                  //       'assets/images/google_logo.png', // Asegúrate de tener el logo de Google en assets/images
                                  //       width: 24,
                                  //       height: 24,
                                  //     ),
                                  //     label: Text('Iniciar sesión con Google'),
                                  //     onPressed: () => signInWithGoogle(context),
                                  //     style: ElevatedButton.styleFrom(
                                  //       backgroundColor: Colors.white,
                                  //       foregroundColor: Colors.black,
                                  //       shape: RoundedRectangleBorder(
                                  //           borderRadius:
                                  //               BorderRadius.circular(12)),
                                  //       padding: EdgeInsets.symmetric(
                                  //           horizontal: 18, vertical: 12),
                                  //       textStyle:
                                  //           TextStyle(fontWeight: FontWeight.bold),
                                  //     ),
                                  //   ),
                                ]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.grey.withOpacity(0.5),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          )),
    );
  }
}
