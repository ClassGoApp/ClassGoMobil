// import 'package:flutter/material.dart';
// import 'dart:async';

// // Asegúrate de importar tus archivos reales
// import 'package:flutter_projects/styles/app_styles.dart'; 
// import 'tutor_model.dart';
// import 'booking_success_screen.dart';

// class WaitingRoomScreen extends StatefulWidget {
//   final TutorResponse tutor;
//   final String subjectName;

//   const WaitingRoomScreen({
//     Key? key,
//     required this.tutor,
//     required this.subjectName,
//   }) : super(key: key);

//   @override
//   State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
// }

// class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
//   @override
//   void initState() {
//     super.initState();
    
//     // 🚀 LA MAGIA DE LA SIMULACIÓN
//     // Esperamos 3 segundos para darle tiempo de lectura al usuario,
//     // y luego saltamos automáticamente a la pantalla de éxito.
//     Future.delayed(const Duration(seconds: 3), () {
//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => BookingSuccessScreen(
//               tutor: widget.tutor,
//               subjectName: widget.subjectName,
//               meetingLink: "https://meet.google.com/abc-defg-hij", 
//             ),
//           ),
//         );
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundLight,
//       body: SafeArea(
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // 1. Ruedita de carga
//                 const SizedBox(
//                   width: 60,
//                   height: 60,
//                   child: CircularProgressIndicator(
//                     color: AppColors.brandBlue,
//                     strokeWidth: 5,
//                   ),
//                 ),
//                 const SizedBox(height: 32),

//                 // 2. Textos de tranquilidad
//                 const Text(
//                   "Validando comprobante...",
//                   style: TextStyle(
//                     fontFamily: 'outfit', // Tu _kTitleFont
//                     fontSize: 24,
//                     fontWeight: FontWeight.w800,
//                     color: AppColors.blackColor,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 12),
//                 const Text(
//                   "Por favor, no cierres esta pantalla.\nEstamos confirmando tu clase con el tutor.",
//                   style: TextStyle(
//                     fontFamily: 'manrope', // Tu _kBodyFont
//                     fontSize: 16,
//                     color: AppColors.greyColor,
//                     height: 1.5,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }