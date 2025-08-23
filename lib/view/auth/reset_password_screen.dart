import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/base_components/textfield.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/tutor/search_tutors_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_projects/helpers/back_button_handler.dart';
import 'register_screen.dart';

class ResetPassword extends StatefulWidget {
  @override
  State<ResetPassword> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<ResetPassword>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  bool _isEmailValid = true;
  String _errorMessage = '';
  bool _isLoading = false;

  static bool isValidEmail(String email) {
    bool emailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
    return emailValid;
  }

  void _forgetPassword() async {
    String email = _emailController.text;

    setState(() {
      if (email.isEmpty) {
        _errorMessage = 'Email should not be empty';
        _isEmailValid = false;
      } else if (isValidEmail(email)) {
        _errorMessage = '';
        _isEmailValid = true;
      } else {
        _errorMessage = 'Invalid email address';
        _isEmailValid = false;
      }
    });

    if (_isEmailValid) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await forgetPassword(email);

        if (response['status'] == 200) {
          showCustomToast(context, response['message'], true);
        } else {
          showCustomToast(context, response['message'], false);
        }
      } catch (e) {
        showCustomToast(context, 'Failed to send email: $e', false);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void showCustomToast(BuildContext context, String message, bool isSuccess) {
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 2.0,
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

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;


    return WillPopScope(
      onWillPop: () => BackButtonHandler.handleBackButton(
        context,
        isLoading: _isLoading,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primaryGreen,
        body: SafeArea(
          child: Column(
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
                            builder: (context) => SearchTutorsScreen()),
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                AppImages.logo,
                                width: 150,
                                height: 150,
                                alignment: Alignment.center,
                              ),
                              SizedBox(height: 30.0),
                              Text(
                                'Restablecer Contraseña',
                                textScaler: TextScaler.noScaling,
                                style: TextStyle(
                                    fontFamily: 'SF-Pro-Text',
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.normal,
                                    fontSize: FontSize.scale(context, 24),
                                    color: AppColors.whiteColor),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                'Ingrese su correo electronico para restrablecer la contraseña de su cuenta.',
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


                            ],
                          ),
                        ),
                        SizedBox(height: height * 0.2),

                        Column(
                          children: [
                            CustomTextField(
                              hint: 'Email Address',
                              obscureText: false,
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              hasError: !_isEmailValid,
                            ),
                            if (_errorMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(color: AppColors.redColor),
                                ),
                              ),
                            SizedBox(height: 20.0),
                            _isLoading
                                ? Center(
                                    child: CircularProgressIndicator(
                                    color: AppColors.primaryGreen,
                                  ))
                                : ElevatedButton(
                                    onPressed: _forgetPassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:AppColors.lightBlueColor,
                                      minimumSize: Size(double.infinity, 55),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Send Reset link',
                                      textScaler: TextScaler.noScaling,
                                      style: TextStyle(
                                        fontSize: FontSize.scale(context, 16),
                                        color: AppColors.whiteColor,
                                        fontFamily: 'SF-Pro-Text',
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FontStyle.normal,
                                      ),
                                    ),
                                  ),
                            SizedBox(height: 16.0),
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
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: AppColors.primaryGreen,
                                ),
                                child: Text(
                                  'Crear cuenta nueva',
                                  style: TextStyle(
                                    color: AppColors.whiteColor,
                                    fontSize: FontSize.scale(context, 16),
                                    fontFamily: 'SF-Pro-Text',
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 6.0),
                            Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 15.0,horizontal: 16.0),
                                child: RichText(
                                  text: TextSpan(
                                    text: "Ya tienes una cuenta? ",
                                    style: TextStyle(
                                      fontSize: FontSize.scale(context, 16),
                                      color: AppColors.whiteColor,
                                      fontFamily: 'SF-Pro-Text',
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.normal,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: "Iniciar sesión",
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
                                                  builder: (context) => LoginScreen()),
                                            );
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20.0),
                          ],
                        ),
                      ],
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
