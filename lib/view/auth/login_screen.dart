import 'dart:convert';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/home/home_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_projects/base_components/textfield.dart';
import 'package:flutter_projects/view/auth/register_screen.dart';
import 'package:flutter_projects/view/auth/reset_password_screen.dart';
import 'package:flutter_projects/helpers/back_button_handler.dart';
import 'package:flutter_projects/view/auth/widgets/google_role_modal.dart';
import 'package:flutter_projects/view/components/role_based_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';

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

  final LayerLink _emailLayerLink = LayerLink();
  final GlobalKey _emailKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  List<Map<String, dynamic>> _savedAccounts = [];

  static bool isValidEmail(String email) {
    bool emailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
    return emailValid;
  }

  void _validateEmailAndSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    String email = _emailController.text;
    String password = _passwordController.text;

    setState(() {
      if (email.isEmpty) {
        _errorMessage = l10n.emailCannotBeEmpty;
        _isEmailValid = false;
      } else if (isValidEmail(email)) {
        _errorMessage = '';
        _isEmailValid = true;
      } else {
        _errorMessage = l10n.enterValidEmail;
        _isEmailValid = false;
      }
      if (password.isEmpty) {
        _passwordErrorMessage = l10n.passwordCannotBeEmpty;
        _isPasswordValid = false;
      } else if (password.length < 6) {
        _passwordErrorMessage = l10n.passwordMinLength;
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

        if (_isChecked) {
          await _saveAccount(email, password);
        } else {
          await _removeAccount(email);
        }

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
          l10n.loginSuccessful,
          true,
        );
      } catch (error) {
        print('Login API call failed: $error');
        final errorMessage = error.toString();
        if (errorMessage.contains("Not verified")) {
          _openBottomSheet(context);
          showCustomToast(
            context,
            l10n.emailNotVerified,
            false,
          );
        } else if (errorMessage.contains("CSRF token mismatch.")) {
          showCustomToast(
            context,
            l10n.serverNotAvailable,
            false,
          );
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: Text(
                l10n.serverDownTitle,
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
                l10n.serverDownMessage,
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
                    l10n.ok,
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
            l10n.loginFailed,
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
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String? _token = authProvider.token;

    if (_token != null) {
      try {
        final response = await resendEmail(_token);
        Navigator.pop(context);
        showCustomToast(
          context,
          l10n.resendEmailSuccess,
          true,
        );
      } catch (error) {
        showCustomToast(
          context,
          l10n.resendEmailFailed,
          false,
        );
      }
    } else {
      showCustomToast(
        context,
        l10n.noActiveSession,
        false,
      );
    }
  }

  void _openBottomSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.emailVerificationTitle,
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
                    l10n.resendEmailButton,
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

  Future<Map<String, dynamic>?> _googleSignInRetry(
      String idToken, BuildContext context) async {
    final selectedRole = await showGoogleRoleSelectionDialog(context);
    if (selectedRole == null) return null;

    final retryResponse = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': idToken, 'role': selectedRole}),
    );
    if (retryResponse.statusCode != 200) {
      throw Exception(retryResponse.body);
    }
    final responseData = jsonDecode(retryResponse.body);
    return responseData['data'];
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
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
      print('🟢 GOOGLE ID TOKEN => $idToken');
      if (idToken == null) {
        throw Exception(l10n.googleTokenError);
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      );

      Map<String, dynamic> loginData;

      if (response.statusCode == 403) {
        final errorBody = jsonDecode(response.body);
        final errorMsg = (errorBody['message'] as String?) ?? '';
        if (errorMsg.contains('no encontrado') || errorMsg.contains('not found')) {
          if (!mounted) return;
          final retryData = await _googleSignInRetry(idToken, context);
          if (retryData == null) {
            setState(() { _isLoading = false; });
            return;
          }
          loginData = retryData;
        } else {
          throw Exception(response.body);
        }
      } else if (response.statusCode != 200) {
        throw Exception(response.body);
      } else {
        final responseData = jsonDecode(response.body);
        loginData = responseData['data'];

        final userMap = loginData['user'];
        if (userMap == null || userMap['role'] == null || userMap['profile'] == null) {
          if (!mounted) return;
          final retryData = await _googleSignInRetry(idToken, context);
          if (retryData == null) {
            setState(() { _isLoading = false; });
            return;
          }
          loginData = retryData;
        }
      }

      final String token = loginData['token'];

      // 🔥 CLAVE: loginData debe ser IGUAL al login normal
      await authProvider.setToken(token);
      await authProvider.setUserData(loginData);
      await authProvider.setAuthToken(token);

      setState(() {
        _isLoading = false;
      });

      showCustomToast(
        context,
        l10n.loginSuccessful,
        true,
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => RoleBasedNavigation()),
        (route) => false,
      );
    } catch (e, stacktrace) {
      print('🔴 ERROR REAL: $e');
      print('📜 STACKTRACE: $stacktrace');
      try {
        await googleSignIn.signOut();
      } catch (signoutError) {
        print('Error al cerrar sesión de Google tras fallo: $signoutError');
      }
      String displayMessage = l10n.googleLoginError;
      try {
        // Limpiamos el texto de la excepción e intentamos decodificar el JSON
        final errorString = e.toString().replaceFirst('Exception: ', '').trim();
        final decoded = jsonDecode(errorString);
        if (decoded is Map && decoded.containsKey('message')) {
          displayMessage = decoded['message'];
        }
      } catch (_) {
        // En caso de que no sea un JSON, mostramos el mensaje de error normal
        final errorMsg = e.toString().replaceFirst('Exception: ', '').trim();
        if (errorMsg.isNotEmpty) {
          displayMessage = errorMsg;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(displayMessage)),
      );
      setState(() {
        _isLoading = false;
      });
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

    _emailFocusNode.addListener(_onEmailFocusChange);
    _loadSavedAccounts();
  }

  @override
  void dispose() {
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _hideSuggestionsOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _onEmailFocusChange() {
    if (_emailFocusNode.hasFocus) {
      _showSuggestionsOverlay();
    } else {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_emailFocusNode.hasFocus) {
          _hideSuggestionsOverlay();
        }
      });
    }
  }

  Future<void> _loadSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? accountsJson = prefs.getString('saved_accounts');
      if (accountsJson != null) {
        final List<dynamic> decoded = jsonDecode(accountsJson);
        setState(() {
          _savedAccounts =
              decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        });
        if (_savedAccounts.isNotEmpty) {
          final lastAccount = _savedAccounts.first;
          _emailController.text = lastAccount['email'] ?? '';
          _passwordController.text = lastAccount['password'] ?? '';
          setState(() {
            _isChecked = true;
          });
        }
      }
    } catch (e) {
      print('Error loading saved accounts: $e');
    }
  }

  Future<void> _saveAccount(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    _savedAccounts.removeWhere((acc) => acc['email'] == email);
    _savedAccounts.insert(0, {
      'email': email,
      'password': password,
    });
    if (_savedAccounts.length > 5) {
      _savedAccounts = _savedAccounts.sublist(0, 5);
    }
    await prefs.setString('saved_accounts', jsonEncode(_savedAccounts));
  }

  Future<void> _removeAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();
    _savedAccounts.removeWhere((acc) => acc['email'] == email);
    await prefs.setString('saved_accounts', jsonEncode(_savedAccounts));
  }

  void _showSuggestionsOverlay() {
    _hideSuggestionsOverlay();
    if (_savedAccounts.isEmpty) return;

    final renderBox =
        _emailKey.currentContext?.findRenderObject() as RenderBox?;
    final width =
        renderBox?.size.width ?? (MediaQuery.of(context).size.width - 24);
    final height = renderBox?.size.height ?? 50.0;

    final overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: width,
          child: CompositedTransformFollower(
            link: _emailLayerLink,
            showWhenUnlinked: false,
            offset: Offset(0, height + 4),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              color: AppColors.whiteColor,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.dividerColor),
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _savedAccounts.length,
                  itemBuilder: (context, index) {
                    final account = _savedAccounts[index];
                    final email = account['email'] ?? '';
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 0),
                      title: Text(
                        email,
                        style: const TextStyle(
                          fontFamily: 'SF-Pro-Text',
                          fontSize: 14,
                          color: AppColors.blackColor,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 20, color: AppColors.redColor),
                        onPressed: () {
                          _deleteSavedAccount(email);
                        },
                      ),
                      onTap: () {
                        _selectSavedAccount(account);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
    overlayState.insert(_overlayEntry!);
  }

  void _hideSuggestionsOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectSavedAccount(Map<String, dynamic> account) {
    setState(() {
      _emailController.text = account['email'] ?? '';
      _passwordController.text = account['password'] ?? '';
      _isChecked = true;
    });
    _hideSuggestionsOverlay();
    _passwordFocusNode.requestFocus();
  }

  void _deleteSavedAccount(String email) async {
    setState(() {
      _savedAccounts.removeWhere((acc) => acc['email'] == email);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_accounts', jsonEncode(_savedAccounts));

    _emailFocusNode.requestFocus();

    if (_savedAccounts.isEmpty) {
      _hideSuggestionsOverlay();
    } else {
      _showSuggestionsOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final l10n = AppLocalizations.of(context)!;

    return WillPopScope(
      onWillPop: () => BackButtonHandler.handleBackButton(
        context,
        isLoading: _isLoading,
      ),
      child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusScope.of(context).unfocus();
          },
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
                              padding:
                                  const EdgeInsets.only(top: 10, right: 20),
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
                                      l10n.homeButton,
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
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
                                            l10n.loginScreenTitle,
                                            style: TextStyle(
                                              fontFamily: 'SF-Pro-Text',
                                              fontWeight: FontWeight.w700,
                                              fontSize:
                                                  FontSize.scale(context, 24),
                                              color: AppColors.whiteColor,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: height * 0.01),
                                          Text(
                                            l10n.loginScreenSubtitle,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'SF-Pro-Text',
                                              fontWeight: FontWeight.w400,
                                              fontSize:
                                                  FontSize.scale(context, 16),
                                              color: AppColors.whiteColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: height * 0.06),
                                      CompositedTransformTarget(
                                        link: _emailLayerLink,
                                        key: _emailKey,
                                        child: CustomTextField(
                                          hint: l10n.emailHint,
                                          obscureText: false,
                                          controller: _emailController,
                                          focusNode: _emailFocusNode,
                                          hasError: !_isEmailValid,
                                        ),
                                      ),
                                      if (_errorMessage.isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(
                                              top: height * 0.01),
                                          child: Text(
                                            _errorMessage,
                                            style: TextStyle(
                                                color: AppColors.redColor),
                                          ),
                                        ),
                                      SizedBox(height: height * 0.02),
                                      CustomTextField(
                                        hint: l10n.passwordHint,
                                        obscureText: true,
                                        controller: _passwordController,
                                        focusNode: _passwordFocusNode,
                                        hasError: !_isPasswordValid,
                                      ),
                                      if (_passwordErrorMessage.isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(
                                              top: height * 0.01),
                                          child: Text(
                                            _passwordErrorMessage,
                                            style: TextStyle(
                                                color: AppColors.redColor),
                                          ),
                                        ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Transform.translate(
                                            offset: Offset(-10, 0),
                                            child: Transform.scale(
                                              scale: 1.3,
                                              child: Checkbox(
                                                value: _isChecked,
                                                checkColor:
                                                    AppColors.whiteColor,
                                                activeColor:
                                                    AppColors.primaryGreen,
                                                fillColor: WidgetStateProperty
                                                    .resolveWith<Color>(
                                                        (states) {
                                                  if (states.contains(
                                                      WidgetState.selected)) {
                                                    return AppColors
                                                        .primaryGreen;
                                                  }
                                                  return AppColors.whiteColor;
                                                }),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5.0),
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
                                              l10n.rememberAccount,
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
                                          backgroundColor:
                                              AppColors.lightBlueColor,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 15),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          l10n.loginButton,
                                          style: TextStyle(
                                            color: AppColors.whiteColor,
                                            fontSize:
                                                FontSize.scale(context, 16),
                                            fontFamily: 'SF-Pro-Text',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        icon: Image.asset(
                                          'assets/images/google_logo.png', // Asegúrate de tener el logo de Google en assets/images
                                          width: 24,
                                          height: 24,
                                        ),
                                        label: Text(l10n.loginWithGoogle),
                                        onPressed: () =>
                                            signInWithGoogle(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 18, vertical: 12),
                                          textStyle: TextStyle(
                                              fontWeight: FontWeight.bold),
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
                                            l10n.forgotPassword,
                                          style: TextStyle(
                                            fontSize:
                                                FontSize.scale(context, 16),
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
                                            borderRadius:
                                                BorderRadius.circular(12),
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
                                            backgroundColor:
                                                AppColors.primaryGreen,
                                          ),
                                          child: Text(
                                            l10n.noAccountRegister,
                                            style: TextStyle(
                                              color: AppColors.whiteColor,
                                              fontSize:
                                                  FontSize.scale(context, 16),
                                              fontFamily: 'SF-Pro-Text',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
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
              ))),
    );
  }
}
