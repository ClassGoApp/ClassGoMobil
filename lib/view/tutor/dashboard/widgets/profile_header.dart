// import 'package:flutter/material.dart';
// import 'package:flutter_projects/styles/app_styles.dart';

// class ProfileHeader extends StatelessWidget {
//   final VoidCallback onBackTap;

//   const ProfileHeader({Key? key, required this.onBackTap}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;

//     // Color de la flecha y texto (Azul en light, Blanco en dark)
//     final textColor = isDark ? Colors.white : AppColors.brandBlue;

//     return Padding(
//       padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
//       child: Row(
//         children: [
//           // 1. Flecha Atrás Grande
//           GestureDetector(
//             onTap: onBackTap,
//             child: Container(
//               padding: const EdgeInsets.all(8),
//               child: Icon(
//                 Icons.arrow_back_ios_new_rounded,
//                 color: textColor,
//                 size: 24,
//               ),
//             ),
//           ),
//           const SizedBox(width: 16),
          
//           // 2. Título "Perfil"
//           Text(
//             "Perfil",
//             style: TextStyle(
//               color: textColor,
//               fontSize: 28, // Tamaño grande como en la imagen
//               fontWeight: FontWeight.w900, // Extra Bold
//               letterSpacing: -0.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }