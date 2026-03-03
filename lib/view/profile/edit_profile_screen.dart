import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../provider/auth_provider.dart';
import '../../styles/app_styles.dart';
import '../../base_components/custom_snack_bar.dart';
import '../../api_structure/config/app_config.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPhoneValid = true;
  String? _profileImageUrl;
  bool _isImageLoading = false;
  
  // Variables para el video
  String? _profileVideoUrl;
  bool _isVideoLoading = false;
  bool _isVideoInitialized = false;
  late VideoPlayerController _videoController;
  final DefaultCacheManager _cacheManager = DefaultCacheManager();
  
  @override
  void initState() {
    super.initState();
    
    // Cargar perfil inmediatamente
    _loadCurrentProfile();
    
    // Inicializar video después de cargar el perfil
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVideo();
    });
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    
    // Dispose del video controller
    if (_isVideoInitialized) {
      try {
        _videoController.removeListener(() {});
        _videoController.dispose();
      } catch (e) {
        print('Error al dispose del video controller: $e');
      }
    }
    
    super.dispose();
  }
  
  void _loadCurrentProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.userData == null) {
      return;
    }
    
    if (authProvider.userData!['user'] == null) {
      return;
    }
    
    final profile = authProvider.userData!['user']['profile'];
    if (profile == null) {
      return;
    }
    
    _firstNameController.text = profile['first_name'] ?? '';
    _lastNameController.text = profile['last_name'] ?? '';
    _phoneController.text = profile['phone_number'] ?? '';
    _descriptionController.text = profile['description'] ?? '';
    
    // Cargar imagen de perfil usando EXACTAMENTE la misma API que el dashboard
    await _loadProfileImageFromDashboard();
  }
  
  Future<void> _loadProfileImageFromDashboard() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.userData?['user']['id'];
      
      if (token != null && userId != null) {
        // Usar EXACTAMENTE la misma API que el dashboard
        final response = await http.get(
          Uri.parse('https://classgoapp.com/api/user/$userId/profile-image'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
        
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          
          // La respuesta viene directamente con los datos, no en {success: true, data: {...}}
          final profileImageUrl = responseData['profile_image'];
          
                     if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
             if (mounted) {
               setState(() {
                 _profileImageUrl = profileImageUrl;
               });
             }
             
             // También actualizar en el AuthProvider para mantener sincronización
             authProvider.updateProfileImage(profileImageUrl);
          }
        }
      }
    } catch (e) {
      // Error silencioso para no interrumpir la experiencia del usuario
    }
  }

  // Método para inicializar el video del perfil
  Future<void> _initializeVideo() async {
    try {
      // Verificar que el widget esté montado antes de continuar
      if (!mounted) {
        print('Widget no está montado, cancelando inicialización del video');
        return;
      }
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final profile = authProvider.userData?['user']?['profile'];
      
      if (profile != null && profile['intro_video'] != null && profile['intro_video'].isNotEmpty) {
        final videoUrl = profile['intro_video'];
        print('URL del video desde el perfil: $videoUrl');
        
        // Construir la URL completa del video
        final fullVideoUrl = _buildFullVideoUrl(videoUrl);
        print('URL completa del video: $fullVideoUrl');
        
        // Verificar que la URL sea válida
        if (!_isValidVideoUrl(fullVideoUrl)) {
          print('URL del video no es válida: $fullVideoUrl');
          if (mounted) {
            _showCustomToast('URL del video no es válida', false);
          }
          return;
        }
        
        if (mounted) {
          setState(() {
            _profileVideoUrl = fullVideoUrl;
          });
        }
        
        // Inicializar el video player
        await _initializeVideoPlayer(fullVideoUrl);
        } else {
        print('No hay video de introducción en el perfil');
      }
    } catch (e) {
      print('Error al inicializar video: $e');
    }
  }

  // Método para construir la URL completa del video
  String _buildFullVideoUrl(String videoPath) {
    print('Construyendo URL para video: $videoPath');
    
    // Si ya es una URL completa, retornarla tal como está
    if (videoPath.startsWith('http://') || videoPath.startsWith('https://')) {
      print('URL ya es completa: $videoPath');
      return videoPath;
    }
    
    // Si es un path relativo, combinarlo con la URL base
    final baseUrl = AppConfig.mediaBaseUrl;
    
    // Asegurar que la URL base termine con '/' y el path no empiece con '/'
    String cleanBaseUrl = baseUrl;
    if (!cleanBaseUrl.endsWith('/')) {
      cleanBaseUrl = '$cleanBaseUrl/';
    }
    
    String cleanVideoPath = videoPath;
    if (cleanVideoPath.startsWith('/')) {
      cleanVideoPath = cleanVideoPath.substring(1);
    }
    
    final fullUrl = '$cleanBaseUrl$cleanVideoPath';
    print('URL base: $cleanBaseUrl');
    print('Path del video: $cleanVideoPath');
    print('URL construida: $fullUrl');
    
    return fullUrl;
  }
  
  // Método para validar si la URL del video es válida
  bool _isValidVideoUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority && uri.path.isNotEmpty;
    } catch (e) {
      print('Error al validar URL: $e');
      return false;
    }
  }
  
  // Método para limpiar caché y reintentar
  Future<void> _clearCacheAndRetry() async {
    try {
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
      
      // Limpiar caché del video
      if (_profileVideoUrl != null) {
        await _cacheManager.removeFile(_profileVideoUrl!);
        print('Caché del video limpiado');
      }
      
      // Reintentar inicialización
      if (_profileVideoUrl != null && mounted) {
        await _initializeVideoPlayer(_profileVideoUrl!);
      }
    } catch (e) {
      print('Error al limpiar caché: $e');
    }
  }

  // Método para inicializar el video player
  Future<void> _initializeVideoPlayer(String videoUrl) async {
    try {
      // Verificar que la URL sea válida
      if (videoUrl.isEmpty) {
        print('URL del video está vacía');
        return;
      }
      
      // Verificar que el widget esté montado antes de continuar
      if (!mounted) {
        print('Widget no está montado, cancelando inicialización del video');
        return;
      }
      
      print('Inicializando video player con URL: $videoUrl');
      
      // Verificar que la URL sea accesible antes de inicializar
      try {
        final response = await http.head(Uri.parse(videoUrl));
        if (response.statusCode != 200) {
          throw Exception('Video no accesible: ${response.statusCode}');
        }
        print('Video accesible, continuando con inicialización...');
      } catch (e) {
        print('Error al verificar accesibilidad del video: $e');
        // Continuar intentando inicializar el video player
      }
      
      // Resetear el estado antes de inicializar
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
      
      // Crear un nuevo controller
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      
      // Agregar listener para detectar cuando se inicializa
      _videoController.addListener(() {
        if (_videoController.value.isInitialized && mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
          print('Video player inicializado correctamente');
        }
      });
      
      // Inicializar el controller con timeout
      await _videoController.initialize().timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout al inicializar el video');
        },
      );
      
      print('Video player inicializado correctamente');
      
    } catch (e) {
      print('Error al inicializar video player: $e');
      // Resetear el estado del video
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
      
      // Mostrar mensaje de error al usuario
      if (mounted) {
        String errorMessage = 'Error al cargar el video';
        
        if (e.toString().contains('404')) {
          errorMessage = 'Video no encontrado en el servidor';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Tiempo de espera agotado al cargar el video';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Error de conexión al cargar el video';
        }
        
        _showCustomToast(errorMessage, false);
      }
    }
  }

  // Método para seleccionar video
  Future<void> _selectVideo() async {
    try {
      // Verificar que el widget esté montado antes de continuar
      if (!mounted) {
        print('Widget no está montado, cancelando selección de video');
        return;
      }
      
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: Duration(seconds: 60), // Máximo 60 segundos
      );
      
      if (video != null && mounted) {
        await _updateVideo(video.path);
      }
    } catch (e) {
      if (mounted) {
        _showCustomToast('Error al seleccionar video: $e', false);
      }
    }
  }

  // Método para actualizar el video
  Future<void> _updateVideo(String videoPath) async {
    try {
      if (mounted) {
        setState(() {
          _isVideoLoading = true;
        });
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userData?['user']['id'];
      final token = authProvider.token;

      if (userId == null || token == null) {
        throw Exception('Usuario no autenticado');
      }

      // Crear request multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://classgoapp.com/api/user/$userId/profile-files'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Agregar el video
      request.files.add(
        await http.MultipartFile.fromPath(
          'intro_video',
          videoPath,
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      if (response.statusCode == 200 && jsonData['success'] == true) {
        // Actualizar la URL del video localmente
        final newVideoUrl = jsonData['data']['profile']['intro_video'];
        
        // Construir la URL completa del video
        final fullVideoUrl = _buildFullVideoUrl(newVideoUrl);
        
        // Actualizar en el AuthProvider (guardar solo el path relativo)
        if (authProvider.userData != null) {
          authProvider.userData!['user']['profile']['intro_video'] = newVideoUrl;
        }

        // Limpiar el video anterior
        if (_isVideoInitialized && mounted) {
          _videoController.removeListener(() {});
          _videoController.dispose();
        }
        
        // Actualizar la URL local
        if (mounted) {
          setState(() {
            _profileVideoUrl = fullVideoUrl;
            _isVideoInitialized = false;
          });
        }

        // Reinicializar el video después de un pequeño delay
        Future.delayed(Duration(milliseconds: 500), () async {
          if (mounted) {
            await _initializeVideoPlayer(fullVideoUrl);
          }
        });

        _showCustomToast('Video actualizado exitosamente', true);
      } else {
        throw Exception(jsonData['message'] ?? 'Error al actualizar el video');
      }
    } catch (e) {
      _showCustomToast('Error al actualizar video: $e', false);
    } finally {
      if (mounted) {
        setState(() {
          _isVideoLoading = false;
        });
      }
    }
  }

  // Método para construir el widget del video player
  Widget _buildVideoPlayer() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.lightBlueColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isVideoInitialized && _videoController.value.isInitialized)
              AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: VideoPlayer(_videoController),
              )
            else
              Container(
                color: AppColors.darkBlue.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightBlueColor),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Cargando video...',
                        style: TextStyle(
                          color: AppColors.lightBlueColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Esto puede tomar unos segundos',
                        style: TextStyle(
                          color: AppColors.lightBlueColor.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                                             SizedBox(height: 12),
                       // Botón para reintentar si falla la carga
                       if (_profileVideoUrl != null && _profileVideoUrl!.isNotEmpty)
                         Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             GestureDetector(
                               onTap: () {
                                 if (mounted) {
                                   _initializeVideoPlayer(_profileVideoUrl!);
                                 }
                               },
                               child: Container(
                                 padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                 decoration: BoxDecoration(
                                   color: AppColors.lightBlueColor.withOpacity(0.2),
                                   borderRadius: BorderRadius.circular(20),
                                   border: Border.all(
                                     color: AppColors.lightBlueColor.withOpacity(0.4),
                                     width: 1,
                                   ),
                                 ),
                                 child: Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     Icon(
                                       Icons.refresh,
                                       color: AppColors.lightBlueColor,
                                       size: 16,
                                     ),
                                     SizedBox(width: 6),
                                     Text(
                                       'Reintentar',
                                       style: TextStyle(
                                         color: AppColors.lightBlueColor,
                                         fontSize: 12,
                                         fontWeight: FontWeight.w500,
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                             ),
                             SizedBox(width: 12),
                             GestureDetector(
                               onTap: () {
                                 if (mounted) {
                                   _clearCacheAndRetry();
                                 }
                               },
                               child: Container(
                                 padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                 decoration: BoxDecoration(
                                   color: AppColors.primaryGreen.withOpacity(0.2),
                                   borderRadius: BorderRadius.circular(20),
                                   border: Border.all(
                                     color: AppColors.primaryGreen.withOpacity(0.4),
                                     width: 1,
                                   ),
                                 ),
                                 child: Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     Icon(
                                       Icons.clear_all,
                                       color: AppColors.primaryGreen,
                                       size: 14,
                                     ),
                                     SizedBox(width: 4),
                                     Text(
                                       'Limpiar Caché',
                                       style: TextStyle(
                                         color: AppColors.primaryGreen,
                                         fontSize: 12,
                                         fontWeight: FontWeight.w500,
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                             ),
                           ],
                         ),
                    ],
                  ),
                ),
              ),
            // Botón de play/pause
            if (_isVideoInitialized && _videoController.value.isInitialized)
              GestureDetector(
                onTap: () {
                  if (mounted) {
                    setState(() {
                      if (_videoController.value.isPlaying) {
                        _videoController.pause();
                      } else {
                        _videoController.play();
                      }
                    });
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(16),
                  child: Icon(
                    _videoController.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Método para construir el placeholder cuando no hay video
  Widget _buildVideoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.darkBlue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.lightBlueColor.withOpacity(0.3),
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off,
            color: AppColors.lightBlueColor.withOpacity(0.6),
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            'No hay video de introducción',
            style: TextStyle(
              color: AppColors.lightBlueColor.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Toca "Cambiar Video" para agregar uno',
            style: TextStyle(
              color: AppColors.lightBlueColor.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  bool _validatePhone(String phone) {
    // Validación básica para números de teléfono
    return phone.length >= 8 && phone.length <= 15;
  }
  
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userData?['user']['id'];
      final token = authProvider.token;
      
      if (userId == null || token == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Preparar los datos en formato x-www-form-urlencoded
      final body = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'description': _descriptionController.text.trim(),
        'full_name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
      };
      
      final response = await http.put(
        Uri.parse('https://classgoapp.com/api/user/$userId/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Actualizar el perfil localmente
        await authProvider.updateUserProfiles(body);
        
        // Mostrar mensaje de éxito
        _showCustomToast('Perfil actualizado exitosamente', true);
        
        // Regresar a la pantalla anterior y forzar actualización
        Navigator.pop(context, true); // Pasar true para indicar que se actualizó la imagen
        
        // El provider se actualizará automáticamente con los datos del servidor
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Error al actualizar el perfil');
      }
    } catch (e) {
      _showCustomToast('Error: ${e.toString()}', false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showCustomToast(String message, bool isSuccess) {
    // Verificar que el contexto esté montado antes de mostrar el toast
    if (!mounted) return;
    
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100.0,
        left: 16.0,
        right: 16.0,
        child: CustomToast(
          message: message,
          isSuccess: isSuccess,
        ),
      ),
    );

    try {
    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
        if (mounted && overlayEntry.mounted) {
      overlayEntry.remove();
        }
      });
    } catch (e) {
      // Si hay un error al insertar el overlay, limpiarlo
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    }
  }

     // Método para cerrar la vista de editar perfil
   void _closeEditProfile() {
     try {
       // Verificar que el contexto esté montado
       if (!mounted) return;
       
       // Agregar un pequeño delay para evitar problemas de timing
       Future.delayed(Duration(milliseconds: 100), () {
         if (!mounted) return;
         
         try {
           // Forzar actualización antes de regresar
           final authProvider = Provider.of<AuthProvider>(context, listen: false);
           
           // Verificar si se actualizó la imagen para pasar el resultado correcto
           bool imageWasUpdated = _profileImageUrl != null && _profileImageUrl!.isNotEmpty;
           
           // Verificar que el Navigator esté disponible y tenga historial
           if (Navigator.canPop(context)) {
             Navigator.pop(context, imageWasUpdated);
           } else {
             // Si no se puede hacer pop, intentar navegar de vuelta al dashboard
             Navigator.pushReplacementNamed(context, '/dashboard');
           }
         } catch (e) {
           print('Error al cerrar vista de editar perfil: $e');
           // En caso de error, intentar navegar de vuelta al dashboard
           try {
             if (mounted) {
               Navigator.pushReplacementNamed(context, '/dashboard');
             }
           } catch (navigationError) {
             print('Error de navegación: $navigationError');
           }
         }
       });
       
       // Timeout de seguridad: si después de 2 segundos no se cerró, forzar cierre
       Future.delayed(Duration(seconds: 2), () {
         if (mounted) {
           print('Timeout de cierre alcanzado, forzando cierre...');
           _emergencyClose();
         }
       });
     } catch (e) {
       print('Error inicial al cerrar vista: $e');
       // En caso de error crítico, intentar cierre de emergencia
       _emergencyClose();
     }
   }
   
   // Método de cierre de emergencia
   void _emergencyClose() {
     try {
       if (!mounted) return;
       
       // Intentar múltiples estrategias de cierre
       if (Navigator.canPop(context)) {
         Navigator.pop(context);
       } else {
         // Forzar navegación al dashboard
         Navigator.pushNamedAndRemoveUntil(
           context, 
           '/dashboard', 
           (route) => false
         );
       }
     } catch (e) {
       print('Error en cierre de emergencia: $e');
     }
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
             body: GestureDetector(
         onPanUpdate: (details) {
           // Detectar deslizamiento hacia abajo
           if (details.delta.dy > 0 && details.delta.dy > 15) {
             // Si se desliza hacia abajo más de 15 píxeles, cerrar la vista
             _closeEditProfile();
           }
         },
         onPanEnd: (details) {
           // Si se desliza hacia abajo con velocidad suficiente, cerrar la vista
           if (details.velocity.pixelsPerSecond.dy > 800) {
             _closeEditProfile();
           }
         },
        child: Container(
          margin: EdgeInsets.only(top: 60),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Barra de arrastre
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // AppBar personalizado
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                                         IconButton(
                       icon: Icon(Icons.close, color: AppColors.whiteColor),
                       onPressed: () {
                         _closeEditProfile();
                       },
                     ),
                    Expanded(
                      child: Text(
          'Editar Perfil',
          style: TextStyle(
            color: AppColors.whiteColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48), // Espacio para centrar el título
                  ],
                ),
              ),
                             // Contenido principal
               Expanded(
                 child: SingleChildScrollView(
                   padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con icono
              Container(
                width: double.infinity,
                          padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.navbar, AppColors.primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                                         GestureDetector(
                       onTap: () => _showImageOptions(),
                       child: Container(
                                  width: 70,
                                  height: 70,
                         decoration: BoxDecoration(
                           shape: BoxShape.circle,
                           border: Border.all(
                             color: AppColors.whiteColor.withOpacity(0.3),
                             width: 3,
                           ),
                           boxShadow: [
                             BoxShadow(
                               color: Colors.black.withOpacity(0.2),
                               blurRadius: 8,
                               offset: Offset(0, 4),
                             ),
                           ],
                         ),
                         child: Stack(
                           children: [
                             ClipOval(
                                        child: Hero(
                                           tag: 'profile-image-${Provider.of<AuthProvider>(context, listen: false).userId ?? 'default'}',
                               child: AnimatedSwitcher(
                                 key: ValueKey(_profileImageUrl ?? 'no-image'),
                                 duration: Duration(milliseconds: 300),
                                 transitionBuilder: (Widget child, Animation<double> animation) {
                                   return FadeTransition(
                                     opacity: animation,
                                     child: child,
                                   );
                                 },
                                 child: _buildProfileImage(),
                                           ),
                               ),
                             ),
                             Positioned(
                               bottom: 0,
                               right: 0,
                               child: Container(
                                 padding: EdgeInsets.all(4),
                                 decoration: BoxDecoration(
                                   color: AppColors.navbar,
                                   shape: BoxShape.circle,
                                   border: Border.all(
                                     color: AppColors.whiteColor,
                                     width: 2,
                                   ),
                                 ),
                                 child: Icon(
                                   Icons.camera_alt,
                                   color: AppColors.whiteColor,
                                             size: 14,
                                 ),
                               ),
                             ),
                           ],
                         ),
                       ),
                     ),
                               SizedBox(height: 12),
                      Text(
                        'Actualiza tu información personal',
                        style: TextStyle(
                          color: AppColors.whiteColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                                             // Mostrar mensaje de éxito si la imagen se actualizó
                       if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                         Column(
                           children: [
                             Container(
                               margin: EdgeInsets.only(top: 8),
                               padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                               decoration: BoxDecoration(
                                 color: AppColors.navbar.withOpacity(0.2),
                                 borderRadius: BorderRadius.circular(20),
                                 border: Border.all(
                                   color: AppColors.navbar.withOpacity(0.5),
                                   width: 1,
                                 ),
                               ),
                               child: Row(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                   Icon(
                                     Icons.check_circle,
                                     color: AppColors.navbar,
                                     size: 16,
                                   ),
                                   SizedBox(width: 6),
                                   Text(
                                     'Imagen actualizada y mostrada',
                                     style: TextStyle(
                                       color: AppColors.navbar,
                                       fontSize: 12,
                                       fontWeight: FontWeight.w500,
                                     ),
                                   ),
                                 ],
                               ),
                             ),
                                     SizedBox(height: 8),
                            // Botón para regresar al dashboard
                            GestureDetector(
                              onTap: () {
                                // Regresar indicando que se actualizó la imagen
                                Navigator.pop(context, true);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.navbar,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.arrow_back,
                                      color: AppColors.whiteColor,
                                      size: 16,
                                    ),
                                             SizedBox(width: 8),
                                    Text(
                                      'Regresar al Dashboard',
                                      style: TextStyle(
                                        color: AppColors.whiteColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                  ],
                ),
              ),
              
                                                 SizedBox(height: 20),
                         
                         // Sección del Video de Introducción
                         Container(
                           width: double.infinity,
                           padding: EdgeInsets.all(20),
                           decoration: BoxDecoration(
                             gradient: LinearGradient(
                               colors: [AppColors.darkBlue.withOpacity(0.9), AppColors.darkBlue.withOpacity(0.7)],
                               begin: Alignment.topLeft,
                               end: Alignment.bottomRight,
                             ),
                             borderRadius: BorderRadius.circular(16),
                             border: Border.all(
                               color: AppColors.lightBlueColor.withOpacity(0.4),
                               width: 1.5,
                             ),
                             boxShadow: [
                               BoxShadow(
                                 color: Colors.black.withOpacity(0.2),
                                 blurRadius: 15,
                                 offset: Offset(0, 8),
                               ),
                             ],
                           ),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Row(
                                 children: [
                                   Container(
                                     padding: EdgeInsets.all(8),
                                     decoration: BoxDecoration(
                                       gradient: LinearGradient(
                                         colors: [AppColors.lightBlueColor, AppColors.primaryGreen],
                                       ),
                                       borderRadius: BorderRadius.circular(12),
                                     ),
                                     child: Icon(
                                       Icons.videocam,
                                       color: Colors.white,
                                       size: 20,
                                     ),
                                   ),
                                   SizedBox(width: 12),
                                   Expanded(
                                     child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         Text(
                                           'Video de Introducción',
                                           style: TextStyle(
                                             color: Colors.white,
                                             fontSize: 18,
                                             fontWeight: FontWeight.w600,
                                           ),
                                         ),
                                         Text(
                                           'Muestra tu personalidad a los estudiantes',
                                           style: TextStyle(
                                             color: Colors.white.withOpacity(0.8),
                                             fontSize: 14,
                                           ),
                                         ),
                                       ],
                                     ),
                                   ),
                                 ],
                               ),
                               SizedBox(height: 16),
                               
                               // Widget del Video
                               if (_profileVideoUrl != null && _profileVideoUrl!.isNotEmpty)
                                 _buildVideoPlayer()
                               else
                                 _buildVideoPlaceholder(),
                               
                               SizedBox(height: 16),
                               
                               // Botón para cambiar video
                               GestureDetector(
                                 onTap: _isVideoLoading ? null : _selectVideo,
                                 child: Container(
                                   width: double.infinity,
                                   padding: EdgeInsets.symmetric(vertical: 14),
                                   decoration: BoxDecoration(
                                     color: AppColors.lightBlueColor.withOpacity(0.2),
                                     borderRadius: BorderRadius.circular(12),
                                     border: Border.all(
                                       color: AppColors.lightBlueColor.withOpacity(0.4),
                                       width: 1,
                                     ),
                                   ),
                                   child: Row(
                                     mainAxisAlignment: MainAxisAlignment.center,
                                     children: [
                                       if (_isVideoLoading)
                                         SizedBox(
                                           width: 20,
                                           height: 20,
                                           child: CircularProgressIndicator(
                                             strokeWidth: 2,
                                             valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                           ),
                                         )
                                       else
                                         Icon(
                                           Icons.video_library,
                                           color: AppColors.lightBlueColor,
                                           size: 20,
                                         ),
                                       SizedBox(width: 8),
                                       Text(
                                         _isVideoLoading ? 'Actualizando...' : 'Cambiar Video',
                                         style: TextStyle(
                                           color: AppColors.lightBlueColor,
                                           fontSize: 16,
                                           fontWeight: FontWeight.w600,
                                         ),
                                       ),
                                     ],
                                   ),
                                 ),
                               ),
                             ],
                           ),
                         ),
                         
                         SizedBox(height: 20),
              
              // Campo Nombre
              _buildTextField(
                controller: _firstNameController,
                label: 'Nombre',
                hint: 'Ingresa tu nombre',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              
                         SizedBox(height: 16),
              
              // Campo Apellido
              _buildTextField(
                controller: _lastNameController,
                label: 'Apellido',
                hint: 'Ingresa tu apellido',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El apellido es requerido';
                  }
                  return null;
                },
              ),
              
                         SizedBox(height: 16),
              
              // Campo Número de Teléfono
              _buildTextField(
                controller: _phoneController,
                label: 'Número de Celular',
                hint: 'Ingresa tu número de celular',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El número de celular es requerido';
                  }
                  if (!_validatePhone(value.trim())) {
                    return 'Ingresa un número de celular válido';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _isPhoneValid = _validatePhone(value);
                  });
                },
              ),
              
                         SizedBox(height: 16),
              
                             // Campo Descripción
               _buildTextField(
                 controller: _descriptionController,
                 label: 'Descripción (opcional)',
                 hint: 'Cuéntanos sobre ti...',
                 icon: Icons.description_outlined,
                           maxLines: 3,
                 validator: (value) {
                   // La descripción es opcional, no hay validación obligatoria
                   return null;
                 },
               ),
              
                         SizedBox(height: 24),
              
              // Botón de Actualizar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navbar,
                    foregroundColor: AppColors.whiteColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                                             ? SizedBox(
                           height: 24,
                           width: 24,
                           child: CircularProgressIndicator(
                             strokeWidth: 2,
                             valueColor: AlwaysStoppedAnimation<Color>(
                               AppColors.navbar,
                             ),
                           ),
                         )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_outlined, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Actualizar Perfil',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              
                                                 SizedBox(height: 16),
                      ],
                    ),
                  ),
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfileImage() {
    if (_isImageLoading) {
      return Container(
         width: 70,
         height: 70,
        decoration: BoxDecoration(
          color: AppColors.darkBlue,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.navbar),
              ),
              SizedBox(height: 4),
              Text(
                'Actualizando...',
                style: TextStyle(
                  color: AppColors.whiteColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Usar la variable local _profileImageUrl que se carga en _loadCurrentProfile
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      // Usar CachedNetworkImage directamente (como en el dashboard)
      return CachedNetworkImage(
        imageUrl: _profileImageUrl!,
         width: 70,
         height: 70,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
           width: 70,
           height: 70,
          decoration: BoxDecoration(
            color: AppColors.darkBlue,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_outline,
            color: AppColors.whiteColor,
             size: 28,
          ),
        ),
        errorWidget: (context, url, error) {
          return Container(
             width: 70,
             height: 70,
            decoration: BoxDecoration(
              color: AppColors.darkBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              color: AppColors.whiteColor,
               size: 28,
            ),
          );
        },
      );
    }
    
    return Container(
       width: 70,
       height: 70,
      decoration: BoxDecoration(
        color: AppColors.darkBlue,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_outline,
        color: AppColors.whiteColor,
         size: 28,
      ),
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBlue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightGreyColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
              ListTile(
                leading: Icon(Icons.visibility, color: AppColors.navbar),
                title: Text(
                  'Ver imagen',
                  style: TextStyle(color: AppColors.whiteColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showImagePreview();
                },
              ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.navbar),
              title: Text(
                'Cambiar imagen',
                style: TextStyle(color: AppColors.whiteColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showImagePreview() {
    if (_profileImageUrl != null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: _profileImageUrl!,
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  color: AppColors.darkBlue,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.navbar),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.darkBlue,
                  child: Icon(
                    Icons.error,
                    color: AppColors.redColor,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _uploadImage(image);
      }
    } catch (e) {
      _showCustomToast('Error al seleccionar la imagen', false);
    }
  }

  Future<void> _uploadImage(XFile imageFile) async {
    setState(() {
      _isImageLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userData?['user']['id'];
      final token = authProvider.token;
      
      if (userId == null || token == null) {
        throw Exception('Usuario no autenticado');
      }
      
                    // Crear la petición multipart con el endpoint correcto
       final request = http.MultipartRequest(
         'POST',
         Uri.parse('https://classgoapp.com/api/user/$userId/profile-files'),
       );
       
       // Agregar headers
       request.headers['Authorization'] = 'Bearer $token';
      
             // Agregar la imagen
       final imageBytes = await imageFile.readAsBytes();
       
       final imageField = http.MultipartFile.fromBytes(
         'image',
         imageBytes,
         filename: imageFile.name,
       );
       request.files.add(imageField);
      
      // Enviar la petición
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
             if (response.statusCode == 200 || response.statusCode == 201) {
         try {
           final jsonResponse = json.decode(responseData);
           
           if (jsonResponse['success'] == true || jsonResponse['status'] == 'success') {
             // Actualizar la imagen localmente
             String? newImageUrl;
             
             // Intentar diferentes estructuras de respuesta
             if (jsonResponse['data'] != null) {
               newImageUrl = jsonResponse['data']['image'] ?? 
                            jsonResponse['data']['profile']?['image'] ??
                            jsonResponse['data']['url'];
             } else if (jsonResponse['image'] != null) {
               newImageUrl = jsonResponse['image'];
             } else if (jsonResponse['url'] != null) {
               newImageUrl = jsonResponse['url'];
             }
             
             if (newImageUrl != null) {
               // Actualizar en el provider PRIMERO para que se sincronice en toda la app
               authProvider.updateProfileImage(newImageUrl);
               
               // Luego actualizar localmente
               setState(() {
                 _profileImageUrl = newImageUrl;
               });
               
               _showCustomToast('Imagen actualizada exitosamente', true);
                
                // Recargar la imagen desde la API para mostrar la nueva imagen
                await _loadProfileImageFromDashboard();
             } else {
               throw Exception('No se pudo obtener la URL de la imagen actualizada');
             }
           } else {
             throw Exception(jsonResponse['message'] ?? 'Error al actualizar la imagen');
           }
         } catch (jsonError) {
           // Si no es JSON válido, verificar si es una respuesta de éxito simple
           if (responseData.contains('success') || responseData.contains('Success')) {
             _showCustomToast('Imagen actualizada exitosamente', true);
           } else {
             throw Exception('Respuesta del servidor no válida: $responseData');
           }
         }
       } else {
         // Manejar diferentes tipos de errores
         String errorMessage = 'Error al actualizar la imagen (${response.statusCode})';
         
         try {
           if (responseData.isNotEmpty) {
             final errorData = json.decode(responseData);
             errorMessage = errorData['message'] ?? errorMessage;
           }
         } catch (e) {
           // Si no es JSON, usar la respuesta como está
           if (responseData.isNotEmpty && responseData.length < 200) {
             errorMessage = responseData;
           }
         }
         
         throw Exception(errorMessage);
       }
    } catch (e) {
      _showCustomToast('Error: ${e.toString()}', false);
    } finally {
      setState(() {
        _isImageLoading = false;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.whiteColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
         SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkBlue,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.navbar.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                 blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.lightGreyColor.withOpacity(0.7),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: AppColors.navbar,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                 vertical: 14,
              ),
            ),
            style: TextStyle(
              color: AppColors.whiteColor,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
