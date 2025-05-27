import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/billing/billing_information.dart';
import 'package:flutter_projects/view/insights/insights_screen.dart';
import 'package:flutter_projects/view/invoice/invoice_screen.dart';
import 'package:flutter_projects/view/payouts/payout_history.dart';
import 'package:flutter_projects/view/profile/profile_setting_screen.dart';
import 'package:flutter_projects/view/profile/skeleton/profile_image_skeleton.dart';
import 'package:flutter_projects/view/settings/account_settings.dart';
import 'package:flutter_projects/view/tutor/certificate/certificate_detail.dart';
import 'package:flutter_projects/view/tutor/education/education_details.dart';
import 'package:flutter_projects/view/tutor/experience/experience_detail.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../provider/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = false;

  late double screenWidth;
  late double screenHeight;

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

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token != null) {
      setState(() {
        isLoading = true;
      });

      try {
        final response = await logout(token);
        if (response['status'] == 200) {
          showCustomToast(
            context,
            response['message'],
            true,
          );

          await authProvider.clearToken();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        } else {
          showCustomToast(
            context,
            'Logout failed: ${response['message']}',
            false,
          );
        }
      } catch (e) {
        showCustomToast(
          context,
          'Error during logout: $e',
          false,
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      showCustomToast(
        context,
        'No token found, clearing session locally',
        false,
      );
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.userData != null) {
        final newBalance = authProvider.userData?['user']?['balance'] ?? 0.00;
        authProvider.updateBalance(double.parse(newBalance.toString()));
        setState(() {});
      }
    });
  }

  final List<Color> availableColors = [
    AppColors.yellowColor,
    AppColors.blueColor,
    AppColors.lightGreenColor,
    AppColors.purpleColor,
    AppColors.greyColor,
  ];

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;
    print(userData.toString());
    String profileImageUrl =
        authProvider.userData?['user']?['profile']?['image'] ?? '';

    final String? fullName = userData != null && userData['user'] != null
        ? userData['user']['profile']['full_name']
        : null;
    final String? role = userData != null && userData['user'] != null
        ? userData['user']['email']
        : null;

    final random = Random();

    return WillPopScope(
      onWillPop: () async {
        if (isLoading) {
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primaryGreen,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(100.0),
          child: Container(
            padding: const EdgeInsets.only(left: 15.0, top: 50),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.transparent,
                  radius: screenWidth * 0.078,
                  child: ClipOval(
                    child: profileImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: profileImageUrl,
                            width: screenWidth * 0.15,
                            height: screenHeight * 0.15,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => ProfileImageSkeleton(
                              radius: screenWidth * 0.078,
                            ),
                            errorWidget: (context, url, error) => CircleAvatar(
                              radius: screenWidth * 0.07,
                              backgroundColor: availableColors[
                                  random.nextInt(availableColors.length)],
                              child: Text(
                                fullName != null && fullName.isNotEmpty
                                    ? fullName[0].toUpperCase()
                                    : 'N',
                                style: TextStyle(
                                  color: AppColors.blackColor,
                                  fontSize: FontSize.scale(context, 20),
                                  fontFamily: 'SF-Pro-Text',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : CircleAvatar(
                            radius: screenWidth * 0.07,
                            backgroundColor: availableColors[
                                random.nextInt(availableColors.length)],
                            child: Text(
                              fullName != null && fullName.isNotEmpty
                                  ? fullName[0].toUpperCase()
                                  : 'N',
                              style: TextStyle(
                                color: AppColors.blackColor,
                                fontSize: FontSize.scale(context, 20),
                                fontFamily: 'SF-Pro-Text',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      fullName ?? '',
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: FontSize.scale(context, 18),
                        fontFamily: 'SF-Pro-Text',
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      role ?? '',
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: FontSize.scale(context, 14),
                        fontFamily: 'SF-Pro-Text',
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      splashColor: Colors.transparent,
                      leading: SvgPicture.asset(
                        AppImages.personOutline,
                        color: AppColors.whiteColor,
                        width: 20,
                        height: 20,
                      ),
                      title: Transform.translate(
                        offset: const Offset(-10, 0.0),
                        child: Text(
                          'Configuración de Perfil',
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                            color: AppColors.whiteColor,
                            fontSize: FontSize.scale(context, 16),
                            fontFamily: 'SF-Pro-Text',
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    if (role == "tutor")
                      ListTile(
                        splashColor: Colors.transparent,
                        leading: SvgPicture.asset(
                          AppImages.insightsIcon,
                          color: AppColors.whiteColor,
                          width: 20,
                          height: 20,
                        ),
                        title: Transform.translate(
                          offset: const Offset(-10, 0.0),
                          child: Text(
                            'Estadísticas',
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              color: AppColors.whiteColor,
                              fontSize: FontSize.scale(context, 16),
                              fontFamily: 'SF-Pro-Text',
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => InsightScreen()),
                          );
                        },
                      ),
                    if (role == "tutor")
                      ListTile(
                        splashColor: Colors.transparent,
                        leading: SvgPicture.asset(
                          AppImages.bookEducationIcon,
                          color: AppColors.whiteColor,
                          width: 20,
                          height: 20,
                        ),
                        title: Transform.translate(
                          offset: const Offset(-10, 0.0),
                          child: Text(
                            'Educación',
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              color: AppColors.whiteColor,
                              fontSize: FontSize.scale(context, 16),
                              fontFamily: 'SF-Pro-Text',
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    EducationalDetailsScreen()),
                          );
                        },
                      ),
                    if (role == "tutor")
                      ListTile(
                        splashColor: Colors.transparent,
                        leading: SvgPicture.asset(
                          AppImages.briefcase,
                          width: 20,
                          height: 20,
                          color: AppColors.whiteColor,
                        ),
                        title: Transform.translate(
                          offset: const Offset(-10, 0.0),
                          child: Text(
                            'Experiencia',
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              color: AppColors.whiteColor,
                              fontSize: FontSize.scale(context, 16),
                              fontFamily: 'SF-Pro-Text',
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    ExperienceDetailsScreen()),
                          );
                        },
                      ),
                    if (role == "tutor")
                      ListTile(
                        splashColor: Colors.transparent,
                        leading: SvgPicture.asset(
                          color: AppColors.whiteColor,
                          AppImages.certificateIcon,
                          width: 20,
                          height: 20,
                        ),
                        title: Transform.translate(
                          offset: const Offset(-10, 0.0),
                          child: Text(
                            'Certificados',
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              color: AppColors.whiteColor,
                              fontSize: FontSize.scale(context, 16),
                              fontFamily: 'SF-Pro-Text',
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CertificateDetail()),
                          );
                        },
                      ),
                    if (role == "tutor")
                      Divider(
                        color: AppColors.dividerColor,
                        height: 0,
                        thickness: 0.7,
                        indent: 15.0,
                        endIndent: 15.0,
                      ),
                    ListTile(
                      splashColor: Colors.transparent,
                      leading: SvgPicture.asset(
                        AppImages.settingIcon,

                        width: 20,
                        height: 20,
                        color: AppColors.whiteColor,
                      ),
                      title: Transform.translate(
                        offset: const Offset(-10, 0.0),
                        child: Text(
                          'Cambiar Contraseña',
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                            color: AppColors.whiteColor,
                            fontSize: FontSize.scale(context, 16),
                            fontFamily: 'SF-Pro-Text',
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AccountSettings()),
                        );
                      },
                    ),
                    if (role == "tutor")
                      ListTile(
                        splashColor: Colors.transparent,
                        leading: SvgPicture.asset(
                          AppImages.dollarIcon,
                          width: 20,
                          height: 20,
                          color: AppColors.whiteColor,
                        ),
                        title: Transform.translate(
                          offset: const Offset(-10, 0.0),
                          child: Text(
                            'Pagos',
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              color: AppColors.whiteColor,
                              fontSize: FontSize.scale(context, 16),
                              fontFamily: 'SF-Pro-Text',
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PayoutsHistory()),
                          );
                        },
                      ),
                    if (role == "student")
                      ListTile(
                        splashColor: Colors.transparent,
                        leading: SvgPicture.asset(
                          AppImages.invoicesIcon,
                          width: 20,
                          height: 22,
                          color: AppColors.whiteColor,
                        ),
                        title: Transform.translate(
                          offset: const Offset(-10, 0.0),
                          child: Text(
                            'Mis facturas',
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              color: AppColors.whiteColor,
                              fontSize: FontSize.scale(context, 16),
                              fontFamily: 'SF-Pro-Text',
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => InvoicesScreen()),
                          );
                        },
                      ),
                    // if (role == "student")
                      // ListTile(
                      //   splashColor: Colors.transparent,
                      //   leading: SvgPicture.asset(
                      //     AppImages.walletIcon,
                      //     width: 20,
                      //     height: 20,
                      //     color: AppColors.whiteColor,
                      //   ),
                      //   title: Transform.translate(
                      //     offset: const Offset(-10, 0.0),
                      //     child: Text(
                      //       'Datos de Facturación',
                      //       textScaler: TextScaler.noScaling,
                      //       style: TextStyle(
                      //         color: AppColors.whiteColor,
                      //         fontSize: FontSize.scale(context, 16),
                      //         fontFamily: 'SF-Pro-Text',
                      //         fontWeight: FontWeight.w400,
                      //         fontStyle: FontStyle.normal,
                      //       ),
                      //     ),
                      //   ),
                      //   onTap: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //           builder: (context) => BillingInformation()),
                      //     );
                      //   },
                      // ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Padding(
              //   padding: const EdgeInsets.only(right: 15, left: 15),
              //   child: Consumer<AuthProvider>(
              //     builder: (context, authProvider, child) {
              //       final userData = authProvider.userData;
              //       String balance =
              //           userData?['user']?['balance']?.toString() ?? "0.00";
              //
              //       return Container(
              //         padding: EdgeInsets.all(10.0),
              //         height: 55,
              //         decoration: BoxDecoration(
              //           color: AppColors.primaryWhiteColor,
              //           borderRadius: BorderRadius.circular(8),
              //         ),
              //         child: Row(
              //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //           crossAxisAlignment: CrossAxisAlignment.center,
              //           children: [
              //             Row(
              //               children: [
              //                 SvgPicture.asset(
              //                   AppImages.walletIcon,
              //                   width: 20,
              //                   height: 20,
              //                   color: AppColors.greyColor,
              //                 ),
              //                 SizedBox(width: 10),
              //                 Text(
              //                   'Balance de Billetera',
              //                   style: TextStyle(
              //                     color: AppColors.greyColor,
              //                     fontSize: FontSize.scale(context, 16),
              //                     fontFamily: 'SF-Pro-Text',
              //                     fontWeight: FontWeight.w400,
              //                     fontStyle: FontStyle.normal,
              //                   ),
              //                 ),
              //               ],
              //             ),
              //             Text(
              //               '\$$balance',
              //               style: TextStyle(
              //                 color: AppColors.blackColor,
              //                 fontSize: FontSize.scale(context, 18),
              //                 fontFamily: 'SF-Pro-Text',
              //                 fontWeight: FontWeight.w600,
              //                 fontStyle: FontStyle.normal,
              //               ),
              //             ),
              //           ],
              //         ),
              //       );
              //     },
              //   ),
              // ),

              Padding(
                padding: const EdgeInsets.only(right: 15, left: 15),
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : _logout,
                  icon: Icon(
                    Icons.power_settings_new,
                    color: AppColors.redColor,
                    size: 20.0,
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Cerrar sesión',
                        style: TextStyle(
                          color: AppColors.redColor,
                          fontFamily: 'SF-Pro-Text',
                          fontSize: FontSize.scale(context, 16),
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                      if (isLoading) ...[
                        SizedBox(width: 10),
                        SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ],
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    side:
                        BorderSide(color: AppColors.redBorderColor, width: 0.7),
                    backgroundColor: AppColors.redBackgroundColor,
                    minimumSize: Size(double.infinity, 50),
                    textStyle: TextStyle(
                      fontSize: FontSize.scale(context, 16),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 30,
              )
            ],
          ),
        ),
      ),
    );
  }
}
