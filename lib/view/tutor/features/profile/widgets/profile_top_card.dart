import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class ProfileTopCard extends StatelessWidget {
  final String? photoUrl;
  final String userName;
  final bool isDark;

  const ProfileTopCard({
    Key? key,
    required this.photoUrl,
    required this.userName,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [const Color(0xFF16181D), const Color(0xFF232833)] 
              : [AppColors.brandBlue, const Color(0xFF1A5A7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.brandBlue).withOpacity(0.35), 
            blurRadius: 25, 
            offset: const Offset(0, 15)
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Stack(
          children: [
            Positioned(
              top: -60, right: -40,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.0)]),
                ),
              ),
            ),
            Positioned(
              bottom: -40, left: -30,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [AppColors.brandCyan.withOpacity(0.2), AppColors.brandCyan.withOpacity(0.0)]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 30),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 115, height: 115,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(color: Colors.white.withOpacity(0.9), width: 4),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(31),
                          child: photoUrl != null
                              ? CachedNetworkImage(imageUrl: photoUrl!, fit: BoxFit.cover, errorWidget: (_,__,___) => const Icon(Icons.person, size: 50))
                              : const Icon(Icons.person, size: 60, color: Colors.grey),
                        ),
                      ),
                      Positioned(
                        bottom: -5, right: -5,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.brandOrange,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [BoxShadow(color: AppColors.brandOrange.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      userName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, color: AppColors.brandCyan, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "TUTOR VERIFICADO",
                          style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}