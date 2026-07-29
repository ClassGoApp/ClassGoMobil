import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/base_components/textfield.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/widgets/google_role_modal.dart';
import 'package:flutter_projects/view/components/role_based_navigation.dart';
import 'package:flutter_projects/view/home/home_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_projects/helpers/back_button_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';

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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _isFirstNameValid = true;
  bool _isLastNameValid = true;
  bool _isEmailValid = true;
  bool _isPhoneNumberValid = true;
  bool _isPasswordValid = true;
  bool _isConfirmPasswordValid = true;
  String _isChecked = "";
  bool _isCheckboxValid = true;

  String _firstNameErrorMessage = '';
  String _lastNameErrorMessage = '';
  String _emailErrorMessage = '';
  String _phoneNumberErrorMessage = '';
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

    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    super.dispose();
  }

  Future<void> _executeRegistration(Map<String, dynamic> finalUserData) async {
    setState(() => _isLoading = true);

    try {
      final responseData = await registerUser(finalUserData);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (responseData.containsKey('data') &&
          responseData['data'].containsKey('token')) {
        authProvider.setToken(responseData['data']['token']);
      }

      final String email = _emailController.text;
      final String password = _passwordController.text;
      await _saveAccount(email, password);

      showCustomToast(
          context, "Registro exitoso, verifica tu correo", true);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationPendingScreen(
            userData: {
              'email': finalUserData['email'],
              'first_name': finalUserData['first_name'],
              'last_name': finalUserData['last_name'],
              'response': responseData,
            },
          ),
        ),
      );
    } catch (error) {
      String errorMessage = 'No se pudo registrar';

      if (error is Map<String, dynamic> && error.containsKey('message')) {
        errorMessage = error['message'];
      } else if (error.toString().contains('HandshakeException')) {
        errorMessage =
            'Error de conexión segura. Verifica tu conexión a internet.';
      } else if (error.toString().contains('SocketException')) {
        errorMessage =
            'No se pudo conectar al servidor. Verifica tu conexión a internet.';
      } else {
        errorMessage = error.toString();
      }

      if (mounted) {
        showCustomToast(context, errorMessage, false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
    String phoneNumber = _phoneController.text.trim();
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    setState(() {
      if (firstName.isEmpty) {
        _firstNameErrorMessage = AppLocalizations.of(context)!.enterFirstName;
        _isFirstNameValid = false;
      } else {
        _firstNameErrorMessage = '';
        _isFirstNameValid = true;
      }

      if (lastName.isEmpty) {
        _lastNameErrorMessage = AppLocalizations.of(context)!.enterLastName;
        _isLastNameValid = false;
      } else {
        _lastNameErrorMessage = '';
        _isLastNameValid = true;
      }

      if (email.isEmpty) {
        _emailErrorMessage = AppLocalizations.of(context)!.enterEmail;
        _isEmailValid = false;
      } else if (!_isValidEmail(email)) {
        _emailErrorMessage = AppLocalizations.of(context)!.invalidEmail;
        _isEmailValid = false;
      } else {
        _emailErrorMessage = '';
        _isEmailValid = true;
      }

      if (phoneNumber.isEmpty) {
        _phoneNumberErrorMessage = AppLocalizations.of(context)!.enterPhoneNumber;
        _isPhoneNumberValid = false;
      } else if (!RegExp(r'^[0-9+\-\s()]{8,15}$').hasMatch(phoneNumber)) {
        _phoneNumberErrorMessage = AppLocalizations.of(context)!.invalidPhoneNumber;
        _isPhoneNumberValid = false;
      } else {
        _phoneNumberErrorMessage = '';
        _isPhoneNumberValid = true;
      }

      if (password.isEmpty) {
        _passwordErrorMessage = AppLocalizations.of(context)!.enterPassword;
        _isPasswordValid = false;
      } else if (password.length < 8) {
        _passwordErrorMessage = AppLocalizations.of(context)!.passwordMinChars;
        _isPasswordValid = false;
      } else {
        _passwordErrorMessage = '';
        _isPasswordValid = true;
      }

      if (confirmPassword.isEmpty) {
        _confirmPasswordErrorMessage = AppLocalizations.of(context)!.confirmPasswordPrompt;
        _isConfirmPasswordValid = false;
      } else if (password != confirmPassword) {
        _confirmPasswordErrorMessage = AppLocalizations.of(context)!.passwordsDontMatch;
        _isConfirmPasswordValid = false;
      } else {
        _confirmPasswordErrorMessage = '';
        _isConfirmPasswordValid = true;
      }

      if (_isChecked.isEmpty) {
        showCustomToast(
            context, 'Acepta términos y privacidad para continuar', false);
      }
    });

    if (_isFirstNameValid &&
        _isLastNameValid &&
        _isEmailValid &&
        _isPhoneNumberValid &&
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
        "phone_number": phoneNumber,
        "password": password,
        "password_confirmation": confirmPassword,
        "user_role": role,
        "terms": _isChecked,
      };

      await _executeRegistration(userData);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                                builder: (context) => HomeScreen()),
                            (Route<dynamic> route) => false,
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.home,
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
                              AppLocalizations.of(context)!.createYourAccount,
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
                                AppLocalizations.of(context)!.registerAsStudentOrTutor,
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
                                  hint: AppLocalizations.of(context)!.nombres,
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
                                  hint: AppLocalizations.of(context)!.apellidos,
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
                              hint: AppLocalizations.of(context)!.emailHint,
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
                              hint: AppLocalizations.of(context)!.phoneNumber,
                              obscureText: false,
                              controller: _phoneController,
                              focusNode: _phoneFocusNode,
                              keyboardType: TextInputType.phone,
                              hasError: !_isPhoneNumberValid,
                            ),
                            if (_phoneNumberErrorMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _phoneNumberErrorMessage,
                                  style: TextStyle(color: AppColors.redColor),
                                ),
                              ),
                            SizedBox(height: 15),
                            CustomTextField(
                              hint: AppLocalizations.of(context)!.passwordHint,
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
                              hint: AppLocalizations.of(context)!.confirmPasswordPrompt,
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
                                            'Student',
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
                                        text: AppLocalizations.of(context)!.iHaveReadAndAgreeToAll,
                                        style: TextStyle(
                                          fontSize: FontSize.scale(context, 14),
                                          fontFamily: 'SF-Pro-Text',
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.whiteColor,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: AppLocalizations.of(context)!.termsAndConditions,
                                            style: TextStyle(
                                                fontSize:
                                                    FontSize.scale(context, 14),
                                                fontFamily: 'SF-Pro-Text',
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.blueColor,
                                                decoration:
                                                    TextDecoration.underline),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () async {
                                                final uri = Uri.parse(
                                                    'https://classgoapp.com/terminos');
                                                if (await canLaunchUrl(uri)) {
                                                  await launchUrl(uri,
                                                      mode: LaunchMode
                                                          .inAppWebView);
                                                }
                                              },
                                          ),
                                          TextSpan(
                                            text: ' ',
                                          ),
                                          TextSpan(
                                            text: AppLocalizations.of(context)!.andWord,
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
                                            text: AppLocalizations.of(context)!.privacyPolicy,
                                            style: TextStyle(
                                                fontSize:
                                                    FontSize.scale(context, 14),
                                                fontFamily: 'SF-Pro-Text',
                                                fontWeight: FontWeight.w400,
                                                color: AppColors.blueColor,
                                                decoration:
                                                    TextDecoration.underline),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () async {
                                                final uri = Uri.parse(
                                                    'https://classgoapp.com/terminos');
                                                if (await canLaunchUrl(uri)) {
                                                  await launchUrl(uri,
                                                      mode: LaunchMode
                                                          .inAppWebView);
                                                }
                                              },
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
                                AppLocalizations.of(context)!.register,
                                style: TextStyle(
                                  color: AppColors.whiteColor,
                                  fontSize: FontSize.scale(context, 16),
                                  fontFamily: 'SF-Pro-Text',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: Image.asset(
                                'assets/images/google_logo.png',
                                width: 24,
                                height: 24,
                              ),
                              label: Text(AppLocalizations.of(context)!.registerWithGoogle),
                              onPressed: _isLoading
                                  ? null
                                  : () => _signInWithGoogle(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                minimumSize: Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle:
                                    TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 15.0, horizontal: 16.0),
                                child: RichText(
                                  text: TextSpan(
                                    text: AppLocalizations.of(context)!.alreadyHaveAnAccount,
                                    style: TextStyle(
                                      fontSize: FontSize.scale(context, 16),
                                      color: AppColors.whiteColor,
                                      fontFamily: 'SF-Pro-Text',
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.normal,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: AppLocalizations.of(context)!.signIn,
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

  Future<void> _signInWithGoogle(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId:
          '777182771573-p7vjm3nh5393g3fhpbd71d2q14gclv1p.apps.googleusercontent.com',
    );
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      if (idToken == null) {
        throw Exception('No se pudo obtener el token de Google');
      }

      String roleToUse = this.role;
      if (roleToUse.isEmpty || _isChecked != 'accepted') {
        if (!mounted) return;
        final selectedRole = await showGoogleRoleSelectionDialog(context);
        if (selectedRole == null) {
          setState(() { _isLoading = false; });
          return;
        }
        roleToUse = selectedRole;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_token': idToken,
          'role': roleToUse,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }

      final responseData = jsonDecode(response.body);
      final Map<String, dynamic> loginData = responseData['data'];

      final Map<String, dynamic>? userMap = loginData['user'];
      if (userMap == null || userMap['role'] == null || userMap['profile'] == null) {
        throw Exception('El usuario no tiene un rol asignado o no tiene un perfil asignado.');
      }

      final String token = loginData['token'];

      await authProvider.setToken(token);
      await authProvider.setUserData(loginData);
      await authProvider.setAuthToken(token);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registro de usuarios exitoso')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => RoleBasedNavigation()),
        (route) => false,
      );
    } catch (e) {
      try {
        await googleSignIn.signOut();
      } catch (signoutError) {
        print('Error al cerrar sesión de Google tras fallo: $signoutError');
      }
      String displayMessage = 'Error al registrarse con Google';
      try {
        final errorString = e.toString().replaceFirst('Exception: ', '').trim();
        final decoded = jsonDecode(errorString);
        if (decoded is Map && decoded.containsKey('message')) {
          displayMessage = decoded['message'];
        }
      } catch (_) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '').trim();
        if (errorMsg.isNotEmpty) {
          displayMessage = errorMsg;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(displayMessage)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveAccount(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> savedAccounts = [];
    final String? accountsJson = prefs.getString('saved_accounts');
    if (accountsJson != null) {
      final List decoded = jsonDecode(accountsJson);
      savedAccounts = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    savedAccounts.removeWhere((acc) => acc['email'] == email);
    savedAccounts.insert(0, {
      'email': email,
      'password': password,
    });
    if (savedAccounts.length > 5) {
      savedAccounts = savedAccounts.sublist(0, 5);
    }
    await prefs.setString('saved_accounts', jsonEncode(savedAccounts));
  }
}
