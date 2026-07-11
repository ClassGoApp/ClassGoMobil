import 'package:flutter/material.dart';
import 'package:flutter_projects/view/profile/edit_profile_view.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../provider/auth_provider.dart';
import '../../styles/app_styles.dart';
import '../../base_components/custom_snack_bar.dart';
import '../../api_structure/config/app_config.dart';
import '../../api_structure/api_service.dart';

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
  bool _isPickingVideo = false;
  double _uploadProgress = 0.0;
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

    final storedVideoPath = profile['intro_video'];
    if (storedVideoPath != null && storedVideoPath.toString().isNotEmpty) {
      final fullVideoUrl = _buildFullVideoUrl(storedVideoPath.toString());
      if (mounted) {
        setState(() {
          _profileVideoUrl = fullVideoUrl;
        });
      }
    }

    // Cargar imagen de perfil usando EXACTAMENTE la misma API que el dashboard
    await _loadProfileImageFromDashboard();
  }

  Future<void> _loadProfileImageFromDashboard() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.userData?['user']['id'];

      if (token != null && userId != null) {
        final result = await getUserProfileImage(token, userId);

        if (result['success'] == true) {
          final responseData = result['data'];
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

      if (profile != null &&
          profile['intro_video'] != null &&
          profile['intro_video'].isNotEmpty) {
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
    if (_isPickingVideo) {
      print('Selección de video ya está en progreso, ignorando tap');
      return;
    }

    try {
      _isPickingVideo = true;

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
        final file = File(video.path);
        final int sizeInBytes = await file.length();
        final double sizeInMB = sizeInBytes / (1024 * 1024);
        print(
            'DEBUG - Video seleccionado. Tamaño: ${sizeInMB.toStringAsFixed(2)}MB');

        if (sizeInMB > 50.0) {
          _showCustomToast(
              'El video supera el límite de 50MB permitido (${sizeInMB.toStringAsFixed(1)}MB). Por favor, elige un video más liviano.',
              false);
          return;
        }

        await _updateVideo(video.path);
      }
    } catch (e) {
      if (mounted) {
        _showCustomToast('Error al seleccionar video: $e', false);
      }
    } finally {
      _isPickingVideo = false;
    }
  }

  String? _extractIntroVideoUrl(Map<String, dynamic> responseData) {
    final nestedData = responseData['data'];
    final profileData =
        nestedData is Map<String, dynamic> ? nestedData['profile'] : null;

    final candidates = [
      responseData['intro_video'],
      responseData['video'],
      profileData?['intro_video'],
      responseData['profile']?['intro_video'],
      nestedData?['intro_video'],
      nestedData?['profile']?['intro_video'],
      responseData['user']?['profile']?['intro_video'],
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.isNotEmpty) {
        return candidate;
      }
    }

    return null;
  }

  // Método para actualizar el video
  Future<void> _updateVideo(String videoPath) async {
    try {
      if (mounted) {
        setState(() {
          _isVideoLoading = true;
          _uploadProgress = 0.0;
        });
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userData?['user']['id'];
      final token = authProvider.token;

      if (userId == null || token == null) {
        throw Exception('Usuario no autenticado');
      }

      final result = await updateProfileVideo(
        token: token,
        userId: userId,
        videoPath: videoPath,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
            });
          }
        },
      );

      if (result['success'] == true) {
        final jsonData = (result['data'] as Map<String, dynamic>);
        print('DEBUG - Respuesta completa updateProfileVideo: $jsonData');

        final newVideoUrl = _extractIntroVideoUrl(jsonData);
        print('DEBUG - intro_video extraído de la respuesta: $newVideoUrl');

        if (newVideoUrl == null || newVideoUrl.isEmpty) {
          throw Exception('La respuesta del servidor no contiene intro_video');
        }

        // Construir la URL completa del video
        final fullVideoUrl = _buildFullVideoUrl(newVideoUrl);

        // Actualizar reactivamente usando el AuthProvider
        authProvider.updateProfileVideo(newVideoUrl);

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
        throw Exception(result['message'] ?? 'Error al actualizar el video');
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.lightBlueColor),
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
                      if (_profileVideoUrl != null &&
                          _profileVideoUrl!.isNotEmpty)
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
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.lightBlueColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.lightBlueColor
                                        .withOpacity(0.4),
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
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primaryGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        AppColors.primaryGreen.withOpacity(0.4),
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
                    _videoController.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
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

      final String role =
          authProvider.userData?['user']?['role']?.toString() ?? '';
      final bool isStudentProfile = role == 'student';

      // Preparar los datos en formato x-www-form-urlencoded
      final body = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'full_name':
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
      };

      if (!isStudentProfile) {
        body['description'] = _descriptionController.text.trim();
      }

      final result = await updateUserProfile(
        token: token,
        userId: userId,
        profileData: body,
      );

      if (result['success'] == true) {
        // Actualizar el perfil localmente
        await authProvider.updateUserProfiles(body);

        // Mostrar mensaje de éxito
        _showCustomToast('Perfil actualizado exitosamente', true);

        // Regresar a la pantalla anterior y forzar actualización
        Navigator.pop(context,
            true); // Pasar true para indicar que se actualizó la imagen
      } else {
        throw Exception(result['message'] ?? 'Error al actualizar el perfil');
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

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
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
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);

          // Verificar si se actualizó la imagen para pasar el resultado correcto
          bool imageWasUpdated =
              _profileImageUrl != null && _profileImageUrl!.isNotEmpty;

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
            context, '/dashboard', (route) => false);
      }
    } catch (e) {
      print('Error en cierre de emergencia: $e');
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userData?['user'];
    final profile = user?['profile'] ?? {};
    final String firstName = profile['first_name'] ?? '';
    final String lastName = profile['last_name'] ?? '';
    final bool isVerified = authProvider.isTutorVerified;
    final String userName = '$firstName $lastName'.trim().isEmpty
        ? (user?['name'] ?? 'Tutor')
        : '$firstName $lastName'.trim();

    final String role = user['role']?.toString() ?? '';
    final bool isStudent = role == 'student';

    return EditProfileView(
      formKey: _formKey,
      firstNameController: _firstNameController,
      lastNameController: _lastNameController,
      phoneController: _phoneController,
      descriptionController: _descriptionController,
      isLoading: _isLoading,
      isVideoLoading: _isVideoLoading,
      uploadProgress: _uploadProgress,
      profileImageUrl: _profileImageUrl,
      profileVideoUrl: _profileVideoUrl,
      userName: userName,
      isVerified: isVerified,
      isStudent: isStudent,
      profileImageWidget: _buildProfileImage(),
      videoPlayerWidget: _buildVideoPlayer(),
      videoPlaceholderWidget: _buildVideoPlaceholder(),
      onClose: _closeEditProfile,
      onPickImage: _showImageOptions,
      onSelectVideo: _selectVideo,
      onDeleteVideo: _showDeleteVideoModal,
      onSave: _updateProfile,
      onPhoneChanged: (value) {
        setState(() {
          _isPhoneValid = _validatePhone(value);
        });
      },
    );
  }

  void _showDeleteVideoModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.whiteColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text('Eliminar Video',
                style: TextStyle(
                    fontFamily: 'outfit',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.brandBlue)),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar tu video de presentación? Esta acción no se puede deshacer.',
          style: TextStyle(
              fontFamily: 'manrope', color: Colors.grey, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteVideoLogic();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sí, eliminar',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVideoLogic() async {
    if (mounted) {
      setState(() {
        _isVideoLoading = true;
      });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userData?['user']['id'];
      final token = authProvider.token;

      if (userId == null || token == null) {
        throw Exception('Usuario no autenticado');
      }

      final result = await deleteProfileVideo(
        token: token,
        userId: userId,
      );

      if (result['success'] == true) {
        if (_isVideoInitialized && mounted) {
          _videoController.removeListener(() {});
          _videoController.dispose();
        }

        if (authProvider.userData != null) {
          authProvider.userData!['user']['profile']['intro_video'] = null;
        }

        if (mounted) {
          setState(() {
            _profileVideoUrl = null;
            _isVideoInitialized = false;
          });
        }

        _showCustomToast('Video eliminado correctamente', true);
      } else {
        throw Exception(result['message'] ?? 'Error desconocido');
      }
    } catch (e) {
      if (mounted) {
        _showCustomToast('Error al eliminar video: $e', false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVideoLoading = false;
        });
      }
    }
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.blackColor : AppColors.whiteColor;
    final textColor = isDark ? AppColors.whiteColor : AppColors.brandBlue;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            Text("FOTO DE PERFIL",
                style: TextStyle(
                    fontFamily: 'outfit',
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            const Text("¿Qué deseas hacer con tu imagen?",
                style: TextStyle(
                    fontFamily: 'manrope', color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),
            if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showImagePreview();
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 20),
                  label: const Text("Ver imagen actual",
                      style: TextStyle(
                          fontFamily: 'outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandCyan,
                    side: const BorderSide(color: AppColors.brandCyan),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage();
                },
                icon: const Icon(Icons.camera_alt_outlined,
                    color: Colors.white, size: 20),
                label: const Text("Cambiar imagen",
                    style: TextStyle(
                        fontFamily: 'outfit',
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandCyan,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
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
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.navbar),
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
        final file = File(image.path);
        final int sizeInBytes = await file.length();
        final double sizeInMB = sizeInBytes / (1024 * 1024);
        print(
            'DEBUG - Imagen seleccionada. Tamaño: ${sizeInMB.toStringAsFixed(2)}MB');

        if (sizeInMB > 5.0) {
          _showCustomToast(
              'La imagen supera el límite de 5MB permitido (${sizeInMB.toStringAsFixed(1)}MB). Por favor, elige una imagen más liviana.',
              false);
          return;
        }

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

      final result = await updateProfileImage(
        token: token,
        userId: userId,
        imagePath: imageFile.path,
      );

      if (result['success'] == true) {
        final jsonResponse = result['data'];

        String? newImageUrl;

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
          authProvider.updateProfileImage(newImageUrl);

          setState(() {
            _profileImageUrl = newImageUrl;
          });

          _showCustomToast('Imagen actualizada exitosamente', true);

          await _loadProfileImageFromDashboard();
        } else {
          throw Exception('No se pudo obtener la URL de la imagen actualizada');
        }
      } else {
        throw Exception(result['message'] ?? 'Error al actualizar la imagen');
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
