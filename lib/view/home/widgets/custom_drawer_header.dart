import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';

class CustomDrawerHeader extends StatelessWidget {
  final AuthProvider authProvider;
  final Map<int, String> highResTutorImages;

  const CustomDrawerHeader(
      {required this.authProvider, required this.highResTutorImages});

  @override
  Widget build(BuildContext context) {
    final userData = authProvider.userData;

    // Corregir la URL de la imagen si es necesario
    String? imageUrl = userData?['user']?['profile']?['image'];
    int? userId = userData?['user']?['id'];
    String? hdImageUrl =
        (userId != null && highResTutorImages.containsKey(userId))
            ? highResTutorImages[userId]
            : null;
    if (hdImageUrl != null && hdImageUrl.isNotEmpty) {
      imageUrl = hdImageUrl;
    } else if (imageUrl != null &&
        imageUrl.contains(
            'https://classgoapp.com/storage/thumbnails/https://classgoapp.com/storage/thumbnails/')) {
      imageUrl = imageUrl.replaceFirst(
          'https://classgoapp.com/storage/thumbnails/https://classgoapp.com/storage/thumbnails/',
          'https://classgoapp.com/storage/thumbnails/');
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightBlueColor,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          topLeft: Radius.circular(0),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl ?? '',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person,
                          size: 30, color: AppColors.lightBlueColor),
                    ),
                    errorWidget: (context, url, error) => CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person,
                          size: 30, color: AppColors.lightBlueColor),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (userData != null)
                      Text(
                        userData['user']?['profile']?['full_name'] ??
                            userData['user']?['name'] ??
                            userData['user']?['email'] ??
                            'Usuario',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()),
                            (Route<dynamic> route) => false,
                          );
                        },
                        child: Text(
                          'Iniciar sesión',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    SizedBox(height: 4),
                    if (userData != null)
                      Text(
                        userData['user']?['email'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          Divider(color: Colors.white24, thickness: 1),
        ],
      ),
    );
  }
}