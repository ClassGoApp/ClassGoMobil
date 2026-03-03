// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_projects/styles/app_styles.dart';

// // 🧱 TUS NUEVOS LADRILLOS COMPARTIDOS
// import 'package:flutter_projects/view/tutor/shared_components/profile_avatar_status.dart';
// import 'package:flutter_projects/view/tutor/shared_components/circle_action_button.dart';

// // 🧩 TUS WIDGETS QUE YA EXISTÍAN
// import 'package:flutter_projects/view/tutor/dashboard/widgets/theme_toggle_button.dart';
// import 'package:flutter_projects/view/tutor/dashboard/widgets/availability_capsule.dart';

// class TutorHomeHeader extends StatelessWidget {
//   final String tutorName;
//   final String? profileImageUrl;
//   final double rating;
//   final bool isLoadingImage;
//   final bool isAvailable;
//   final VoidCallback onLogoutTap;
//   final Function(bool) onAvailabilityToggle;

//   const TutorHomeHeader({
//     Key? key,
//     required this.tutorName,
//     this.profileImageUrl,
//     this.rating = 4.9,
//     this.isLoadingImage = false,
//     required this.isAvailable,
//     required this.onLogoutTap,
//     required this.onAvailabilityToggle,
//   }) : super(key: key);

//   String _getFirstName(String fullName) {
//     if (fullName.isEmpty) return "Tutor";
//     return fullName.trim().split(' ')[0];
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;
//     final backgroundColor = isDark ? AppColors.headerDark : AppColors.headerLight;
//     final double statusBarHeight = MediaQuery.of(context).padding.top;

//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
//       child: Stack(
//         clipBehavior: Clip.none,
//         alignment: Alignment.topCenter,
//         children: [
//           // 1. EL FONDO OSCURO GIGANTE
//           Container(
//             width: double.infinity,
//             padding: EdgeInsets.only(
//               top: statusBarHeight + 15,
//               bottom: 45, // Espacio para que flote la cápsula
//               left: 20,
//               right: 20,
//             ),
//             decoration: BoxDecoration(
//               color: backgroundColor,
//               borderRadius: const BorderRadius.only(
//                 bottomLeft: Radius.circular(32),
//                 bottomRight: Radius.circular(32),
//               ),
//               boxShadow: !isDark
//                   ? [
//                       BoxShadow(
//                         color: backgroundColor.withOpacity(0.4),
//                         blurRadius: 20,
//                         offset: const Offset(0, 10),
//                       )
//                     ]
//                   : null,
//             ),
//             child: Theme(
//               data: ThemeData.dark().copyWith(scaffoldBackgroundColor: backgroundColor),
//               child: Row(
//                 children: [
//                   // 🧱 APLICANDO EL LADRILLO 1 (FOTO)
//                   ProfileAvatarStatus(
//                     imageUrl: profileImageUrl,
//                     isOnline: isAvailable,
//                     isLoading: isLoadingImage,
//                   ),
                  
//                   const SizedBox(width: 16),
                  
//                   // 2. TEXTOS Y ESTADÍSTICAS
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           "Hola, ${_getFirstName(tutorName)}",
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 24,
//                             fontFamily: 'outfit',
//                             fontWeight: FontWeight.bold,
//                             letterSpacing: -0.5,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         const SizedBox(height: 6),
//                         Row(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
//                               decoration: BoxDecoration(
//                                 color: isDark ? const Color(0xFF1B3B48) : AppColors.cardDark,
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 18),
//                                   const SizedBox(width: 4),
//                                   Text(
//                                     rating.toStringAsFixed(1),
//                                     style: const TextStyle(color: Colors.white, fontFamily: 'manrope', fontWeight: FontWeight.w700, fontSize: 14),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFF1B3B48),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: const Row(
//                                 children: [
//                                   Icon(Icons.verified_user_outlined, color: AppColors.brandCyan, size: 14),
//                                   SizedBox(width: 4),
//                                   Text("VERIFICADO", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, fontFamily: 'manrope', letterSpacing: 0.5)),
//                                 ],
//                               ),
//                             )
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),

//                   // 3. BOTONES DE ACCIÓN (Theme y Logout)
//                   Row(
//                     children: [
//                       const ThemeToggleButton(),
//                       const SizedBox(width: 8),
//                       // 🧱 APLICANDO EL LADRILLO 2 (BOTÓN DE SALIR)
//                       CircleActionButton(
//                         icon: Icons.logout_rounded,
//                         tooltip: 'Cerrar Sesión',
//                         isDestructive: true,
//                         onTap: onLogoutTap,
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // 4. LA CÁPSULA FLOTANTE DE DISPONIBILIDAD
//           Positioned(
//             bottom: -35, 
//             right: 5,
//             left: 5,
//             child: AvailabilityCapsule(
//               isAvailable: isAvailable,
//               onTap: () async {
//                 if (isAvailable) {
//                   await HapticFeedback.lightImpact();
//                 } else {
//                   await HapticFeedback.heavyImpact();
//                 }
//                 onAvailabilityToggle(!isAvailable);
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }