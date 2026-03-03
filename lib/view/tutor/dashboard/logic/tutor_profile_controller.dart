import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/api_structure/api_service.dart';

class TutorProfileController extends ChangeNotifier {
  String? profileImageUrl;
  bool isLoadingProfileImage = false;

  // Tu método original para limpiar URLs de imagen duplicadas
  String cleanImageUrl(String url) {
    if (url.contains('https://classgoapp.com/storagehttps://classgoapp.com')) {
      return url.replaceFirst(
          'https://classgoapp.com/storagehttps://classgoapp.com',
          'https://classgoapp.com');
    }
    if (url.contains('/storage/storage/')) {
      return url.replaceFirst('/storage/storage/', '/storage/');
    }
    return url;
  }

  // Tu método original para sincronizar la imagen del AuthProvider
  void syncProfileImageFromAuthProvider(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authImageUrl = authProvider.userData?['user']?['profile']?['image'] ??
        authProvider.userData?['user']?['profile']?['profile_image'];

    if (authImageUrl != null &&
        authImageUrl.isNotEmpty &&
        authImageUrl != profileImageUrl) {
      profileImageUrl = cleanImageUrl(authImageUrl);
      notifyListeners(); // Avisa a la vista que la imagen cambió
    }
  }

  // Tu método original para cargar la imagen de perfil desde la API
  Future<void> loadProfileImage(BuildContext context) async {
    isLoadingProfileImage = true;
    notifyListeners();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.userId;

      // Primero verificar si ya tenemos una imagen en el AuthProvider
      final cachedImageUrl = authProvider.userData?['user']?['profile']?['image'] ??
          authProvider.userData?['user']?['profile']?['profile_image'];
          
      if (cachedImageUrl != null && cachedImageUrl.isNotEmpty) {
        profileImageUrl = cleanImageUrl(cachedImageUrl);
        notifyListeners();
      }

      if (token != null && userId != null) {
        final response = await getUserProfileImage(token, userId);

        if (response['success'] == true && response['data'] != null) {
          final profileData = response['data'];
          final apiImageUrl = profileData['profile_image'];

          if (apiImageUrl != null && apiImageUrl.isNotEmpty) {
            final cleanUrl = cleanImageUrl(apiImageUrl);
            profileImageUrl = cleanUrl;
            authProvider.updateProfileImage(cleanUrl);
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('Error al cargar imagen de perfil: $e');
    } finally {
      isLoadingProfileImage = false;
      notifyListeners();
    }
  }
}