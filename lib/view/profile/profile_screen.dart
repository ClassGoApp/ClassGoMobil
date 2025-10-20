import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/insights/insights_screen.dart';
import 'package:flutter_projects/view/payouts/payout_history.dart';
import 'package:flutter_projects/view/profile/edit_profile_screen.dart';
import 'package:flutter_projects/view/profile/skeleton/profile_image_skeleton.dart';
import 'package:flutter_projects/view/settings/account_settings.dart';
import 'package:flutter_projects/view/settings/google_integrations_screen.dart';
import 'package:flutter_projects/view/tutor/certificate/certificate_detail.dart';
import 'package:flutter_projects/view/tutor/education/education_details.dart';
import 'package:flutter_projects/view/tutor/experience/experience_detail.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../../provider/auth_provider.dart';
import 'package:flutter_projects/provider/booking_provider.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = false;
  String? profileImageUrl;

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      print('DEBUG - ProfileScreen initState - userData: ${authProvider.userData}');
      print('DEBUG - ProfileScreen initState - isLoggedIn: ${authProvider.isLoggedIn}');
      print('DEBUG - ProfileScreen initState - token: ${authProvider.token != null ? "SÍ" : "NO"}');

      if (authProvider.userData != null) {
        final newBalance = authProvider.userData?['user']?['balance'] ?? 0.00;
        authProvider.updateBalance(double.parse(newBalance.toString()));
        setState(() {});
      }
      
      // Cargar información completa del usuario
      await authProvider.loadCompleteUserProfile();
      
      // Forzar actualización de la UI
      if (mounted) {
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
    final bookingProvider = Provider.of<BookingProvider>(context);
    
    // Obtener datos del usuario con fallbacks
    String fullName = authProvider.userName;
    String? email = authProvider.email;
    
    // Fallback: si no hay datos en userData, intentar desde las variables individuales
    if (fullName.isEmpty || fullName == 'Usuario') {
      final firstName = authProvider.firstName ?? '';
      final lastName = authProvider.lastName ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        fullName = '$firstName $lastName'.trim();
      }
    }
    
    if (email == null || email.isEmpty) {
      // Intentar obtener email desde userData directamente
      if (authProvider.userData != null && authProvider.userData!['user'] != null) {
        email = authProvider.userData!['user']['email'];
      }
    }
    
    // Debug logging mejorado
    print('DEBUG - ProfileScreen - fullName: $fullName');
    print('DEBUG - ProfileScreen - email: $email');
    print('DEBUG - ProfileScreen - firstName: ${authProvider.firstName}');
    print('DEBUG - ProfileScreen - lastName: ${authProvider.lastName}');
    print('DEBUG - ProfileScreen - userData: ${authProvider.userData}');
    print('DEBUG - ProfileScreen - isLoggedIn: ${authProvider.isLoggedIn}');
    print('DEBUG - ProfileScreen - token: ${authProvider.token != null ? "SÍ" : "NO"}');

    // --- Cálculos de perfil tipo Duolingo ---
    final List<Map<String, dynamic>> tutorias = bookingProvider.bookings;
    // Racha de días (días consecutivos con tutoría)
    int streak = 0;
    if (tutorias.isNotEmpty) {
      final days = tutorias
          .map((t) => DateTime(t['date'].year, t['date'].month, t['date'].day))
          .toSet()
          .toList()
        ..sort();
      streak = 1;
      for (int i = days.length - 2; i >= 0; i--) {
        if (days[i + 1].difference(days[i]).inDays == 1) {
          streak++;
        } else {
          break;
        }
      }
    }
    // Materia favorita (la más repetida)
    String favoriteSubject = '';
    if (tutorias.isNotEmpty) {
      final subjectCount = <String, int>{};
      for (var t in tutorias) {
        final subject = (t['subject'] ?? t['title'] ?? '').toString();
        if (subject.isNotEmpty) {
          subjectCount[subject] = (subjectCount[subject] ?? 0) + 1;
        }
      }
      if (subjectCount.isNotEmpty) {
        favoriteSubject = subjectCount.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }
    }
    // Tiempo total de tutoría (en horas:minutos)
    int totalMinutes = 0;
    for (var t in tutorias) {
      if (t['duration'] != null) {
        totalMinutes += int.tryParse(t['duration'].toString()) ?? 0;
      } else if (t['start_time'] != null && t['end_time'] != null) {
        try {
          final start = DateTime.parse(t['start_time'].toString());
          final end = DateTime.parse(t['end_time'].toString());
          totalMinutes += end.difference(start).inMinutes;
        } catch (_) {}
      }
    }
    final int totalHours = totalMinutes ~/ 60;
    final int totalMins = totalMinutes % 60;
    // --- Fin cálculos ---

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
        body: Stack(
          children: [
            // Fondo degradado superior
            Container(
              height: 260,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.darkBlue, AppColors.primaryGreen],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Contenido principal
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 18),
                  // Foto de perfil con borde y sombra
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.lightBlueColor,
                          width: 4,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: Colors.transparent,
                        child: ClipOval(
                          child: authProvider.userData?['user']?['profile_image'] != null &&
                                  authProvider.userData!['user']['profile_image'].isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: authProvider.userData!['user']['profile_image'],
                                  width: 108,
                                  height: 108,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      ProfileImageSkeleton(radius: 54),
                                  errorWidget: (context, url, error) =>
                                      CircleAvatar(
                                    radius: 54,
                                    backgroundColor: AppColors.lightGreyColor,
                                    child: Icon(Icons.person,
                                        color: Colors.white, size: 48),
                                  ),
                                )
                              : ProfileImageSkeleton(radius: 54),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 14),
                  // Nombre y correo centrados
                  Center(
                    child: Column(
                      children: [
                        Text(
                          fullName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          email ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18),
                  // Bloque de estadísticas con animación y badges
                  AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeOutExpo,
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.darkBlue.withOpacity(0.98),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ProfileStat(
                          icon: Icons.local_fire_department,
                          label: 'Racha',
                          value: '$streak días',
                          color: AppColors.orangeprimary,
                          badge: streak >= 7
                              ? Icon(Icons.emoji_events,
                                  color: AppColors.yellowColor, size: 18)
                              : null,
                        ),
                        _ProfileStat(
                          icon: Icons.bookmark,
                          label: 'Materia favorita',
                          value: favoriteSubject.isNotEmpty
                              ? favoriteSubject
                              : '-',
                          color: AppColors.lightBlueColor,
                          badge: favoriteSubject.isNotEmpty
                              ? Icon(Icons.star,
                                  color: AppColors.starYellow, size: 18)
                              : null,
                        ),
                        _ProfileStat(
                          icon: Icons.access_time,
                          label: 'Tiempo total',
                          value: totalHours > 0
                              ? '$totalHours h $totalMins min'
                              : '$totalMins min',
                          color: AppColors.primaryGreen,
                          badge: totalHours >= 10
                              ? Icon(Icons.workspace_premium,
                                  color: AppColors.purpleColor, size: 18)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18),
                  // Resto del contenido (opciones)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkBlue,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(28)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 12,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      child: ListView(
                        padding: EdgeInsets.only(top: 18, bottom: 90),
                        children: [
                          // Botón de configuración de perfil
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryGreen.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.whiteColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: SvgPicture.asset(
                                    AppImages.personOutline,
                                    color: AppColors.whiteColor,
                                    width: 20,
                                    height: 20,
                                  ),
                                ),
                                title: Text(
                                  'Configuración de Perfil',
                                  style: TextStyle(
                                    fontSize: FontSize.scale(context, 16),
                                    color: AppColors.whiteColor,
                                    fontFamily: 'SF-Pro-Text',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: AppColors.whiteColor.withOpacity(0.8),
                                  size: 16,
                                ),
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditProfileScreen(),
                                    ),
                                  );
                                  
                                  // Mostrar mensaje de éxito si se actualizó el perfil
                                  if (result == true) {
                                    showCustomToast(context, 'Perfil actualizado exitosamente', true);
                                  }
                                },
                              ),
                            ),
                          ),
                          if (authProvider.userRole == "tutor")
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
                                  MaterialPageRoute(
                                      builder: (_) => InsightScreen()),
                                );
                              },
                            ),
                          if (authProvider.userRole == "tutor")
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
                          if (authProvider.userRole == "tutor")
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
                          if (authProvider.userRole == "tutor")
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
                                      builder: (context) =>
                                          CertificateDetail()),
                                );
                              },
                            ),
                          if (authProvider.userRole == "tutor")
                            Divider(
                              color: AppColors.dividerColor,
                              height: 0,
                              thickness: 0.7,
                              indent: 15.0,
                              endIndent: 15.0,
                            ),
                          // Botón de cambiar contraseña
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryGreen.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.whiteColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: SvgPicture.asset(
                                    AppImages.settingIcon,
                                    color: AppColors.whiteColor,
                                    width: 20,
                                    height: 20,
                                  ),
                                ),
                                title: Text(
                                  'Cambiar Contraseña',
                                  style: TextStyle(
                                    fontSize: FontSize.scale(context, 16),
                                    color: AppColors.whiteColor,
                                    fontFamily: 'SF-Pro-Text',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: AppColors.whiteColor.withOpacity(0.8),
                                  size: 16,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => AccountSettings()),
                                  );
                                },
                              ),
                            ),
                          ),
                          // Integraciones de Google
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryGreen.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.whiteColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.integration_instructions,
                                    color: AppColors.whiteColor,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  'Integraciones de Google',
                                  style: TextStyle(
                                    fontSize: FontSize.scale(context, 16),
                                    color: AppColors.whiteColor,
                                    fontFamily: 'SF-Pro-Text',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Conectar Google Calendar',
                                  style: TextStyle(
                                    fontSize: FontSize.scale(context, 12),
                                    color: AppColors.whiteColor.withOpacity(0.7),
                                    fontFamily: 'SF-Pro-Text',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: AppColors.whiteColor.withOpacity(0.8),
                                  size: 16,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => GoogleIntegrationsScreen()),
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          // Botón de cerrar sesión
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.redColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: isLoading 
                                    ? SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                        Icons.power_settings_new,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                ),
                                title: Text(
                                  'Cerrar sesión',
                                  style: TextStyle(
                                    fontSize: FontSize.scale(context, 16),
                                    color: Colors.white,
                                    fontFamily: 'SF-Pro-Text',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: isLoading ? null : _logout,
                              ),
                            ),
                          ),
                          if (authProvider.userRole == "tutor")
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
                          // if (authProvider.userRole == "student")
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
                  ),
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
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Widget? badge;

  const _ProfileStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: color, size: 32),
            if (badge != null)
              Positioned(
                bottom: -8,
                right: -8,
                child: badge!,
              ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: AppColors.whiteColor.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.whiteColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
