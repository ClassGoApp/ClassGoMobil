import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';

// Este "Mixin" le da superpoderes lógicos a cualquier State donde lo conectemos
mixin TutorProfileLogic<T extends StatefulWidget> on State<T> implements WidgetsBindingObserver {
  
  // Nuestras variables de estado (antes estaban en tu UI)
  String? profileImageUrl;
  bool isLoadingProfileImage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Escucha si la app se minimiza
    
    // Tu lógica original de carga inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        syncProfileImageFromAuthProvider();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Dejamos de escuchar al salir
    super.dispose();
  }

  // Tu lógica original cuando la app se reanuda (vuelve del fondo)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          syncProfileImageFromAuthProvider();
          loadProfileImage(); 
        }
      });
    }
  }

  // Tu método exacto para sincronizar la imagen
  void syncProfileImageFromAuthProvider() {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // ¡AQUÍ ESTABA LA RUTA CORRECTA A TU IMAGEN!
    final authImageUrl = authProvider.userData?['user']?['profile']?['image'] ??
        authProvider.userData?['user']?['profile']?['profile_image'];

    if (authImageUrl != null && authImageUrl.isNotEmpty && authImageUrl != profileImageUrl) {
      final cleanUrl = cleanImageUrl(authImageUrl);
      setState(() {
        profileImageUrl = cleanUrl;
      });
    }
  }

  // Pega aquí el contenido de tu función original _cleanImageUrl
  String cleanImageUrl(String url) {
    // Si tenías lógica aquí (como agregar el https), ponla. 
    // Por ejemplo:
    /* if (!url.startsWith('http')) {
      return 'https://tuservidor.com$url';
    } 
    */
    return url;
  }

  // Pega aquí el contenido de tu función original _loadProfileImage
  Future<void> loadProfileImage() async {
    setState(() => isLoadingProfileImage = true);
    
    // Tu código de API original va aquí
    // await apiService.getProfile()...
    
    if (mounted) {
      setState(() => isLoadingProfileImage = false);
    }
  }
}