import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class ProfileAvatarStatus extends StatelessWidget {
  // ⬇️ VOLVIMOS A TUS PARÁMETROS ORIGINALES ⬇️
  final String? imageUrl; 
  final bool isOnline;
  final bool isLoading;
  final double size;

  const ProfileAvatarStatus({
    Key? key,
    required this.imageUrl, // Ahora te pedirá la imagen obligatoriamente
    required this.isOnline,
    this.isLoading = false,
    this.size = 56.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'profile-image-shared',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. EL CÍRCULO CON LA FOTO (Tu lógica exacta de CachedNetworkImage)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            ),
            child: ClipOval(
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : (imageUrl != null && imageUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: imageUrl!, // Usa la variable que le pasamos
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Icon(Icons.person, color: Colors.white70, size: 32),
                          errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.white70, size: 32),
                        )
                      : const Icon(Icons.person, color: Colors.white70, size: 32),
            ),
          ),

          // 2. EL PUNTITO VERDE DE ESTADO
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: isOnline ? const Color(0xFF00D856) : AppColors.greyColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.headerDark, width: 2.5), 
              ),
            ),
          ),
        ],
      ),
    );
  }
}