import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/base_components/textfield.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';

import '../../provider/auth_provider.dart';

class AccountSettings extends StatefulWidget {
  @override
  _AccountSettingsState createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _isPasswordValid = true;
  bool _isConfirmPasswordValid = true;
  String _passwordErrorMessage = '';
  String _confirmPasswordErrorMessage = '';

  late double screenWidth;
  late double screenHeight;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
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

  void _validatePassword() {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      if (_passwordController.text.isEmpty) {
        _passwordErrorMessage = l10n.passwordRequired;
        _isPasswordValid = false;
      } else if (_passwordController.text.length < 8) {
        _passwordErrorMessage = l10n.passwordLengthError;
        _isPasswordValid = false;
      } else {
        _passwordErrorMessage = '';
        _isPasswordValid = true;
      }
    });
  }

  void _validateConfirmPassword() {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      if (_confirmPasswordController.text.isEmpty) {
        _confirmPasswordErrorMessage = l10n.confirmPasswordRequired;
        _isConfirmPasswordValid = false;
      } else if (_passwordController.text != _confirmPasswordController.text) {
        _confirmPasswordErrorMessage = l10n.passwordMismatch;
        _isConfirmPasswordValid = false;
      } else {
        _confirmPasswordErrorMessage = '';
        _isConfirmPasswordValid = true;
      }
    });
  }

  void _updatePassword() async {
    final l10n = AppLocalizations.of(context)!;
    _validatePassword();
    _validateConfirmPassword();

    if (_isPasswordValid && _isConfirmPasswordValid) {
      setState(() {
        _isLoading = true;
      });

      Map<String, dynamic> userData = {
        "password": _passwordController.text,
        "confirm": _confirmPasswordController.text,
      };

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token;
        final userId = authProvider.userId;

        final responseData = await updatePassword(userData, token!, userId!);

        setState(() {
          _isLoading = false;
        });

        if (responseData['status'] == 200) {
          showCustomToast(context, responseData['message'], true);

          _passwordController.clear();
          _confirmPasswordController.clear();
        } else {
          showCustomToast(context, responseData['message'], false);
        }
      } catch (error) {
        showCustomToast(
            context, l10n.passwordUpdateError(error.toString()), false);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: Container(
          color: AppColors.primaryGreen,
          child: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: AppBar(
              backgroundColor: AppColors.primaryGreen,
              forceMaterialTransparency: true,
              elevation: 0,
              titleSpacing: 0,
              title: Text(
                l10n.passwordSettings,
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: AppColors.whiteColor,
                  fontSize: FontSize.scale(context, 20),
                  fontFamily: 'SF-Pro-Text',
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.normal,
                ),
              ),
              leading: Padding(
                padding: const EdgeInsets.only(top: 3.0),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.arrow_back_ios,
                      size: 20, color: AppColors.whiteColor),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              centerTitle: false,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 10,
              ),
              Container(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.changePassword,
                      style: TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: FontSize.scale(context, 16),
                        fontFamily: 'SF-Pro-Text',
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    SizedBox(height: 15),
                    CustomTextField(
                      hint: l10n.newPassword,
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
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(height: 15),
                    CustomTextField(
                      hint: l10n.confirmPassword,
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
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updatePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightBlueColor,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.update,
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              fontSize: FontSize.scale(context, 16),
                              color: AppColors.whiteColor,
                              fontFamily: 'SF-Pro-Text',
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                          if (_isLoading) SizedBox(width: 10),
                          if (_isLoading)
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.whiteColor,
                                strokeWidth: 2.0,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
