// import 'package:flutter/material.dart';

// // 🎨 CONSTANTES DE DISEÑO (NEO-CLEAN)
// const String kFontFamily = 'manrope';
// const String kTitleFont = 'outfit';

// const Color kBackgroundLight = Color(0xFFF8FAFC); // Fondo gris casi blanco
// const Color kCardWhite = Colors.white;
// const Color kBrandBlue = Color(0xFF1E40AF); // Tu azul principal
// const Color kBrandCyan = Color(0xFF06B6D4); // Cyan para detalles/radar
// const Color kTextDark = Color(0xFF0F172A);
// const Color kTextGray = Color(0xFF64748B);
// const Color kSuccessGreen = Color(0xFF10B981);

// // 📦 MODELO DE DATOS
// class TutorResponse {
//   final int id;
//   final String name;
//   final String avatarUrl;
//   final bool isVerified;
//   final String pricePerHour;
//   final double rating;

//   TutorResponse({
//     required this.id,
//     required this.name,
//     required this.avatarUrl,
//     required this.isVerified,
//     required this.pricePerHour,
//     required this.rating,
//   });
// }

// // 📦 DATOS DUMMY (Backend)
// final List<TutorResponse> dummyFoundTutors = [
//   TutorResponse(id: 1, name: 'Carlos Mendoza', avatarUrl: 'https://i.pravatar.cc/150?img=11', isVerified: true, pricePerHour: '50.00 Bs', rating: 4.8),
//   TutorResponse(id: 2, name: 'Ana Salazar', avatarUrl: 'https://i.pravatar.cc/150?img=5', isVerified: true, pricePerHour: '45.00 Bs', rating: 4.9),
//   TutorResponse(id: 3, name: 'Roberto Gómez', avatarUrl: 'https://i.pravatar.cc/150?img=8', isVerified: false, pricePerHour: '40.00 Bs', rating: 4.5),
// ];