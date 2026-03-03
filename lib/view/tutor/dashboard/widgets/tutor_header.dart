// import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter_projects/styles/app_styles.dart';

// class TutorHeader extends StatelessWidget {
//   final String tutorName;
//   final String? profileImageUrl;
//   final double rating;
//   final int completedSessions;
//   final bool isLoadingImage;
//   final VoidCallback onEditProfile;
//   final VoidCallback onLogout;

//   const TutorHeader({
//     Key? key,
//     required this.tutorName,
//     this.profileImageUrl,
//     required this.rating,
//     required this.completedSessions,
//     this.isLoadingImage = false,
//     required this.onEditProfile,
//     required this.onLogout,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [AppColors.primaryGreen, Color(0xFF2E7D32)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(18),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.15),
//             blurRadius: 12,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           _buildProfileImage(),
//           const SizedBox(width: 16),
//           Expanded(child: _buildWelcomeText()),
//           _buildActionButtons(),
//         ],
//       ),
//     );
//   }

//   Widget _buildProfileImage() {
//     return Hero(
//       tag: 'profile-image-header',
//       child: Container(
//         width: 56,
//         height: 56,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           color: Colors.white.withOpacity(0.2),
//           border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
//         ),
//         child: ClipOval(
//           child: isLoadingImage
//               ? const Padding(
//                   padding: EdgeInsets.all(16.0),
//                   child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//                 )
//               : (profileImageUrl != null && profileImageUrl!.isNotEmpty)
//                   ? CachedNetworkImage(
//                       imageUrl: profileImageUrl!,
//                       fit: BoxFit.cover,
//                       placeholder: (context, url) => const Icon(Icons.person, color: Colors.white),
//                       errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.white),
//                     )
//                   : const Icon(Icons.person, color: Colors.white, size: 32),
//         ),
//       ),
//     );
//   }

//   Widget _buildWelcomeText() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           '¡Hola, $tutorName!',
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.w700,
//             fontFamily: 'outline',
//             fontSize: 15,
//             height: 1.3
//           ),
//           maxLines: 2,
//           overflow: TextOverflow.ellipsis,
//         ),
//         const SizedBox(height: 4),
//         Row(
//           children: [
//             const Icon(Icons.star, color: AppColors.starYellow, size: 16),
//             const SizedBox(width: 4),
//             Text(
//               '$rating',
//               style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
//             ),
//             const SizedBox(width: 12),
//             const Icon(Icons.check_circle, color: Colors.white, size: 16),
//             const SizedBox(width: 4),
//             Expanded(
//               child: Text(
//                 '$completedSessions sesiones',
//                 style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButtons() {
//     return Row(
//       children: [
//         _CircleIconButton(
//           icon: Icons.edit_outlined,
//           onTap: onEditProfile,
//           tooltip: 'Editar perfil',
//         ),
//         const SizedBox(width: 8),
//         _CircleIconButton(
//           icon: Icons.logout_rounded,
//           onTap: onLogout,
//           tooltip: 'Cerrar sesión',
//         ),
//       ],
//     );
//   }
// }

// class _CircleIconButton extends StatelessWidget {
//   final IconData icon;
//   final VoidCallback onTap;
//   final String tooltip;

//   const _CircleIconButton({
//     required this.icon,
//     required this.onTap,
//     required this.tooltip,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.15),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.white.withOpacity(0.3)),
//       ),
//       child: IconButton(
//         onPressed: onTap,
//         icon: Icon(icon, color: Colors.white, size: 18),
//         tooltip: tooltip,
//         constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
//         padding: EdgeInsets.zero,
//       ),
//     );
//   }
// }