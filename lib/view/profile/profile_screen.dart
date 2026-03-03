import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/insights/insights_screen.dart';
import 'package:flutter_projects/view/invoice/invoice_screen.dart';
import 'package:flutter_projects/view/payouts/payout_history.dart';
import 'package:flutter_projects/view/profile/edit_profile_screen.dart';
import 'package:flutter_projects/view/profile/skeleton/profile_image_skeleton.dart';
import 'package:flutter_projects/view/settings/account_settings.dart';
import 'package:flutter_projects/view/tutor/certificate/certificate_detail.dart';
import 'package:flutter_projects/view/tutor/education/education_details.dart';
import 'package:flutter_projects/view/tutor/experience/experience_detail.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

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

  Future<void> _fetchProfile() async {
    print('ENTRANDO A _fetchProfile');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    print('authProvider: $authProvider');
    final token = authProvider.token;
    final userId = authProvider.userData?['user']?['id'];
    print('token: $token, userId: $userId');
    if (token != null && userId != null) {
      try {
        final response = await getProfile(token, userId);
        final data = response['data'];
        // Obtener imagen real de perfil
        final imageUrl = await _fetchProfileImage(userId);
        setState(() {
          profileImageUrl = imageUrl;
          isLoading = false;
        });
      } catch (e) {
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
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String?> _fetchProfileImage(int userId) async {
    try {
      final response = await http.get(
          Uri.parse('https://classgoapp.com/api/user/$userId/profile-image'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['profile_image'] as String?;
      }
    } catch (e) {
      print('Error fetching profile image: $e');
    }
    return null;
  }

  Future<void> _logout() async {
    setState(() {
      isLoading = true;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        showCustomToast(context, 'Error al cerrar sesión', false);
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // 🔒 SI ES GUEST, NO HACER NADA
      if (!authProvider.isLoggedIn) return;

      if (authProvider.userData != null) {
        final newBalance = authProvider.userData?['user']?['balance'] ?? 0.00;
        authProvider.updateBalance(double.parse(newBalance.toString()));
        setState(() {});
      }

      final int? userId = authProvider.userId;
      if (userId != null) {
        try {
          final response = await http.get(
            Uri.parse('https://classgoapp.com/api/user/$userId/profile-image'),
          );
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            setState(() {
              profileImageUrl = data['profile_image'] as String?;
            });
          }
        } catch (_) {}
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
    final authProvider = Provider.of<AuthProvider>(context);

// 🔒 MODO INVITADO (NO LOGUEADO)
    if (!authProvider.isLoggedIn) {
      return _GuestProfile();
    }

    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    final bookingProvider = Provider.of<BookingProvider>(context);
    final userData = authProvider.userData;
    final int? userId = authProvider.userId;
    final String? fullName = userData != null && userData['user'] != null
        ? (userData['user']['profile']['full_name'] ??
            (userData['user']['profile']['first_name'] != null &&
                    userData['user']['profile']['last_name'] != null
                ? '${userData['user']['profile']['first_name']} ${userData['user']['profile']['last_name']}'
                : userData['user']['profile']['first_name'] ??
                    userData['user']['profile']['last_name']))
        : null;
    final String? role = userData != null && userData['user'] != null
        ? userData['user']['email']
        : null;

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
      child: Stack(
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
                        child: profileImageUrl != null &&
                                profileImageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: profileImageUrl!,
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
                        fullName ?? '',
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
                        role ?? '',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
                        value:
                            favoriteSubject.isNotEmpty ? favoriteSubject : '-',
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
                                builder: (context) => EditProfileScreen(),
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
                                MaterialPageRoute(
                                    builder: (_) => InsightScreen()),
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
                        // Botón de cerrar sesión debajo de cambiar contraseña
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
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
                                    color: Colors
                                        .white, // Cambiado a blanco para contraste
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
                              side: BorderSide(
                                  color: AppColors.redBorderColor, width: 0.7),
                              backgroundColor:
                                  AppColors.redColor, // Cambiado a rojo sólido
                              minimumSize: Size(double.infinity, 50),
                              textStyle: TextStyle(
                                fontSize: FontSize.scale(context, 16),
                              ),
                            ),
                          ),
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

class _GuestProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.white.withOpacity(0.85),
              ),
              const SizedBox(height: 24),
              Text(
                'Inicia sesión para acceder a tu perfil',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Revisa tu historial, estadísticas, pagos y configuración personal.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightBlueColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Iniciar sesión',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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

