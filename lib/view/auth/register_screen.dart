import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/base_components/textfield.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/layout/main_shell.dart';
import 'package:flutter_projects/view/tutor/search_tutors_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/helpers/back_button_handler.dart';

import 'login_screen.dart';
import 'verification_pending_screen.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _isFirstNameValid = true;
  bool _isLastNameValid = true;
  bool _isEmailValid = true;
  bool _isPasswordValid = true;
  bool _isConfirmPasswordValid = true;
  String _isChecked = "";
  bool _isCheckboxValid = true;

  String _firstNameErrorMessage = '';
  String _lastNameErrorMessage = '';
  String _emailErrorMessage = '';
  String _passwordErrorMessage = '';
  String _confirmPasswordErrorMessage = '';
  String role = 'student';

  bool _isLoading = false;

  bool _isValidEmail(String email) {
    return RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

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

  void showCustomToast(BuildContext context, String message, bool isSuccess) {
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 1.0,
        left: 16.0,
        right: 16.0,
        child: CustomToast(
          message: message,
          isSuccess: isSuccess,
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 1), () {
      overlayEntry.remove();
    });
  }

  void _validateAndSubmit() async {
    String firstName = _firstNameController.text;
    String lastName = _lastNameController.text;
    String email = _emailController.text;
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    setState(() {
      if (firstName.isEmpty) {
        _firstNameErrorMessage = "First Name should not be empty";
        _isFirstNameValid = false;
      } else {
        _firstNameErrorMessage = '';
        _isFirstNameValid = true;
      }

      if (lastName.isEmpty) {
        _lastNameErrorMessage = "Last Name should not be empty";
        _isLastNameValid = false;
      } else {
        _lastNameErrorMessage = '';
        _isLastNameValid = true;
      }

      if (email.isEmpty) {
        _emailErrorMessage = "Email should not be empty";
        _isEmailValid = false;
      } else if (!_isValidEmail(email)) {
        _emailErrorMessage = 'Enter a valid email address';
        _isEmailValid = false;
      } else {
        _emailErrorMessage = '';
        _isEmailValid = true;
      }

      if (password.isEmpty) {
        _passwordErrorMessage = "Password should not be empty";
        _isPasswordValid = false;
      } else if (password.length < 8) {
        _passwordErrorMessage = 'Password must be at least 8 characters';
        _isPasswordValid = false;
      } else {
        _passwordErrorMessage = '';
        _isPasswordValid = true;
      }

      if (confirmPassword.isEmpty) {
        _confirmPasswordErrorMessage = "Confirm Password should not be empty";
        _isConfirmPasswordValid = false;
      } else if (password != confirmPassword) {
        _confirmPasswordErrorMessage =
            'Password and Confirm Password must match';
        _isConfirmPasswordValid = false;
      } else {
        _confirmPasswordErrorMessage = '';
        _isConfirmPasswordValid = true;
      }

      if (_isChecked.isEmpty) {
        showCustomToast(
            context, 'You must agree to the Terms & Conditions', false);
      }
    });

    if (_isFirstNameValid &&
        _isLastNameValid &&
        _isEmailValid &&
        _isPasswordValid &&
        _isConfirmPasswordValid &&
        _isChecked.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      Map<String, dynamic> userData = {
        "first_name": firstName,
        "last_name": lastName,
        "email": email,
        "password": password,
        "password_confirmation": confirmPassword,
        "user_role": role,
        "terms": _isChecked,
      };

      try {
        print('Iniciando proceso de registro...');
        final responseData = await registerUser(userData);
        print('Respuesta del registro: $responseData');
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (responseData.containsKey('data') &&
            responseData['data'].containsKey('token')) {
          final String token = responseData['data']['token'];
          authProvider.setToken(token);
        }

        showCustomToast(context,
            responseData['message'] ?? 'Registration successful', true);

        // Redirigir a la pantalla de verificación pendiente en lugar del login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => VerificationPendingScreen(
                    userData: {
                      'email': email,
                      'first_name': firstName,
                      'last_name': lastName,
                      'response': responseData,
                    },
                  )),
        );
      } catch (error) {
        print('Error capturado en registro: $error');
        print('Tipo de error: ${error.runtimeType}');

        String errorMessage = 'Registration failed: ';

        if (error is Map<String, dynamic> && error.containsKey('message')) {
          errorMessage += error['message'];
          print('Error estructurado: ${error['message']}');
        } else if (error.toString().contains('HandshakeException')) {
          errorMessage +=
              'Error de conexión segura. Verifica tu conexión a internet.';
          print('Error de SSL detectado en pantalla');
        } else if (error.toString().contains('SocketException')) {
          errorMessage +=
              'No se pudo conectar al servidor. Verifica tu conexión a internet.';
          print('Error de conexión detectado en pantalla');
        } else {
          errorMessage += 'An unknown error occurred: ${error.toString()}';
          print('Error inesperado en pantalla: $error');
        }

        showCustomToast(context, errorMessage, false);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () => BackButtonHandler.handleBackButton(
        context,
        isLoading: _isLoading,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primaryGreen,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2, right: 20),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MainShell()),
                            (Route<dynamic> route) => false,
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Skip',
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
                        padding: const EdgeInsets.symmetric(horizontal: 14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              AppImages.logo,
                              width: 150,
                              height: 150,
                              alignment: Alignment.center,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Crea tu cuenta',
                              textScaler: TextScaler.noScaling,
                              style: TextStyle(
                                fontFamily: 'SF-Pro-Text',
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.normal,
                                fontSize: FontSize.scale(context, 24),
                                color: AppColors.whiteColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 10),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Text(
                                'Regístrate como estudiante o tutor y comienza tu viaje educativo con nosotros.',
                                textScaler: TextScaler.noScaling,
                                style: TextStyle(
                                  fontFamily: 'SF-Pro-Text',
                                  fontWeight: FontWeight.w400,
                                  fontStyle: FontStyle.normal,
                                  fontSize: FontSize.scale(context, 16),
                                  color: AppColors.whiteColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 60),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CustomTextField(
                                  hint: 'Nombres',
                                  obscureText: false,
                                  controller: _firstNameController,
                                  focusNode: _firstNameFocusNode,
                                  hasError: !_isFirstNameValid,
                                ),
                                if (_firstNameErrorMessage.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      _firstNameErrorMessage,
                                      style:
                                          TextStyle(color: AppColors.redColor),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CustomTextField(
                                  hint: 'Apellidos',
                                  obscureText: false,
                                  controller: _lastNameController,
                                  focusNode: _lastNameFocusNode,
                                  hasError: !_isLastNameValid,
                                ),
                                if (_lastNameErrorMessage.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      _lastNameErrorMessage,
                                      style:
                                          TextStyle(color: AppColors.redColor),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 15),
                            CustomTextField(
                              hint: 'Correo electrónico',
                              obscureText: false,
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              hasError: !_isEmailValid,
                            ),
                            if (_emailErrorMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _emailErrorMessage,
                                  style: TextStyle(color: AppColors.redColor),
                                ),
                              ),
                            SizedBox(height: 15),
                            CustomTextField(
                              hint: 'Contraseña',
                              obscureText: true,
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              hasError: !_isPasswordValid,
                            ),
                            if (_passwordErrorMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _passwordErrorMessage,
                                  style: TextStyle(color: AppColors.redColor),
                                ),
                              ),
                            SizedBox(height: 15),
                            CustomTextField(
                              hint: 'Confirmar Contraseña',
                              obscureText: true,
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocusNode,
                              hasError: !_isConfirmPasswordValid,
                            ),
                            if (_confirmPasswordErrorMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _confirmPasswordErrorMessage,
                                  style: TextStyle(color: AppColors.redColor),
                                ),
                              ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          role = (role == 'student')
                                              ? ''
                                              : 'student';
                                        });
                                      },
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: role == 'student'
                                                  ? AppColors.lightBlueColor
                                                  : AppColors.whiteColor,
                                              border: Border.all(
                                                color: role == 'student'
                                                    ? Colors.transparent
                                                    : AppColors.dividerColor,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Center(
                                              child: Container(
                                                width: 9,
                                                height: 9,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: role == 'student'
                                                      ? AppColors.whiteColor
                                                      : Colors.transparent,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Estudiante',
                                            style: TextStyle(
                                              fontSize:
                                                  FontSize.scale(context, 16),
                                              fontFamily: 'SF-Pro-Text',
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.whiteColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 20),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          role =
                                              (role == 'tutor') ? '' : 'tutor';
                                        });
                                      },
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: role == 'tutor'
                                                  ? AppColors.lightBlueColor
                                                  : AppColors.whiteColor,
                                              border: Border.all(
                                                color: role == 'tutor'
                                                    ? Colors.transparent
                                                    : AppColors.dividerColor,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Center(
                                              child: Container(
                                                width: 9,
                                                height: 9,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: role == 'tutor'
                                                      ? AppColors.whiteColor
                                                      : Colors.transparent,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Tutor',
                                            style: TextStyle(
                                              fontSize:
                                                  FontSize.scale(context, 16),
                                              fontFamily: 'SF-Pro-Text',
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.whiteColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Transform.translate(
                                  offset: Offset(-10.0, -12.0),
                                  child: Transform.scale(
                                    scale: 1.3,
                                    child: Checkbox(
                                      value: _isChecked == 'accepted',
                                      checkColor: AppColors.whiteColor,
                                      activeColor: AppColors.lightBlueColor,
                                      fillColor: WidgetStateProperty
                                          .resolveWith<Color>((states) {
                                        if (states
                                            .contains(WidgetState.selected)) {
                                          return AppColors.lightBlueColor;
                                        }
                                        return AppColors.whiteColor;
                                      }),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                      ),
                                      side: BorderSide(
                                        color: _isCheckboxValid
                                            ? AppColors.dividerColor
                                            : AppColors.redColor,
                                        width: 1,
                                      ),
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _isChecked = value! ? 'accepted' : '';
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Transform.translate(
                                    offset: Offset(-12, 0),
                                    child: RichText(
                                      text: TextSpan(
                                        text:
                                            'He leído y estoy de acuerdo con todos los ',
                                        style: TextStyle(
                                          fontSize: FontSize.scale(context, 14),
                                          fontFamily: 'SF-Pro-Text',
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.whiteColor,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Terminos y condiciones',
                                            style: TextStyle(
                                                fontSize:
                                                    FontSize.scale(context, 14),
                                                fontFamily: 'SF-Pro-Text',
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.blueColor,
                                                decoration:
                                                    TextDecoration.underline),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {},
                                          ),
                                          TextSpan(
                                            text: ' ',
                                          ),
                                          TextSpan(
                                            text: 'y ',
                                            style: TextStyle(
                                              fontSize:
                                                  FontSize.scale(context, 14),
                                              fontFamily: 'SF-Pro-Text',
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.whiteColor,
                                              height: 1.7,
                                            ),
                                          ),
                                          TextSpan(
                                            text: 'Políticas de Privacidad',
                                            style: TextStyle(
                                                fontSize:
                                                    FontSize.scale(context, 14),
                                                fontFamily: 'SF-Pro-Text',
                                                fontWeight: FontWeight.w400,
                                                color: AppColors.blueColor,
                                                decoration:
                                                    TextDecoration.underline),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {},
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _validateAndSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.lightBlueColor,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Registrarse',
                                style: TextStyle(
                                  color: AppColors.whiteColor,
                                  fontSize: FontSize.scale(context, 16),
                                  fontFamily: 'SF-Pro-Text',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 15.0, horizontal: 16.0),
                                child: RichText(
                                  text: TextSpan(
                                    text: '¿Ya tienes una cuenta? ',
                                    style: TextStyle(
                                      fontSize: FontSize.scale(context, 16),
                                      color: AppColors.whiteColor,
                                      fontFamily: 'SF-Pro-Text',
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.normal,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Iniciar sesión',
                                        style: TextStyle(
                                          fontSize: FontSize.scale(context, 16),
                                          fontFamily: 'SF-Pro-Text',
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.lightBlueColor,
                                          decoration: TextDecoration.underline,
                                          decorationThickness: 1,
                                          fontStyle: FontStyle.normal,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      LoginScreen()),
                                            );
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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
        ),
      ),
    );
  }
}
