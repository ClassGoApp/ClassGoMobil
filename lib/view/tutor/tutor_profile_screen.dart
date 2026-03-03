import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'package:flutter_projects/view/tutor/instant_tutoring_screen.dart';
import 'package:flutter_projects/view/tutor/search_tutors_screen.dart'
    show BookingModal;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/api_structure/api_service.dart';

class TutorProfileScreen extends StatefulWidget {
  final String tutorId;
  final String tutorName;
  final String tutorImage;
  final String tutorVideo;
  final String description;
  final double rating;
  final List<String> subjects;
  final int completedCourses;

  // Idiomas por defecto
  final List<String> languages;

  const TutorProfileScreen({
    Key? key,
    required this.tutorId,
    required this.tutorName,
    required this.tutorImage,
    required this.tutorVideo,
    required this.description,
    required this.rating,
    required this.subjects,
    required this.completedCourses,
    this.languages = const ['Español', 'Inglés'],
  }) : super(key: key);

  @override
  _TutorProfileScreenState createState() => _TutorProfileScreenState();
}

class _TutorProfileScreenState extends State<TutorProfileScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  final ScrollController _scrollController = ScrollController();
  bool _areAllSubjectsShown = false;
  static const int _initialSubjectCount = 6;
  static final _cacheManager = DefaultCacheManager();
  bool _instantAvailable = false;
  bool _checkingInstantAvailability = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    // Verificar disponibilidad inmediata del tutor para el botón "Tutoría ahora"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInstantAvailability();
    });
  }

  void _initializeVideo() async {
    if (widget.tutorVideo.isEmpty) return;

    try {
      final fileInfo = await _cacheManager.getFileFromCache(widget.tutorVideo);

      if (fileInfo != null) {
        // Video encontrado en el caché, usar el archivo local
        _videoController = VideoPlayerController.file(fileInfo.file);
      } else {
        // Video no está en caché, descargarlo y guardarlo
        final downloadedFile =
            await _cacheManager.downloadFile(widget.tutorVideo);
        _videoController = VideoPlayerController.file(downloadedFile.file);
      }

      await _videoController.initialize();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      // Manejar el error, por ejemplo si la URL del video es inválida
      print('Error al inicializar el video: $e');
    }
  }

  Future<void> _checkInstantAvailability() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) {
        setState(() {
          _instantAvailable = false;
          _checkingInstantAvailability = false;
        });
        return;
      }

      print(
          '[TutorProfile] Checking instant availability for tutorId=${widget.tutorId}');
      final response = await getTutorAvailableSlots(token, widget.tutorId);
      final now = DateTime.now();

      bool available = false;
      final Map<String, dynamic> responseMap = response;
      final dynamic data =
          responseMap.containsKey('data') ? responseMap['data'] : responseMap;

      // La API puede devolver Map agrupado o List plana
      if (data is Map) {
        data.forEach((groupName, subjects) {
          if (available) return; // early exit
          if (subjects is Map) {
            subjects.forEach((subjectName, subjectData) {
              if (available) return;
              final List<dynamic> slots = subjectData['slots'] ?? [];
              for (final slot in slots) {
                try {
                  final start =
                      DateTime.parse((slot['start_time'] as String).trim());
                  final end =
                      DateTime.parse((slot['end_time'] as String).trim());
                  if ((now.isAfter(start) || now.isAtSameMomentAs(start)) &&
                      now.isBefore(end)) {
                    available = true;
                    break;
                  }
                } catch (_) {}
              }
            });
          }
        });
      } else if (data is List) {
        for (final slot in data) {
          try {
            final start = DateTime.parse((slot['start_time'] as String).trim());
            final end = DateTime.parse((slot['end_time'] as String).trim());
            if ((now.isAfter(start) || now.isAtSameMomentAs(start)) &&
                now.isBefore(end)) {
              available = true;
              break;
            }
          } catch (_) {}
        }
      }

      print('[TutorProfile] Instant availability: $available');
      if (mounted) {
        setState(() {
          _instantAvailable = available;
          _checkingInstantAvailability = false;
        });
      }
    } catch (e) {
      print('[TutorProfile] Error checking availability: $e');
      if (mounted) {
        setState(() {
          _instantAvailable = false;
          _checkingInstantAvailability = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildStyledChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.blueColor.withOpacity(0.9),
            AppColors.blueColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppColors.blueColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blueColor.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double avatarRadius = 54;
    final double videoHeight = 210;
    // Valor de ejemplo para cursos completados
    // valores no usados eliminados
    // Altura total del header visual (video + mitad avatar + margen + nombre + valoración)
    final double headerHeight = videoHeight + avatarRadius * 0.85 + 24;
    return NotificationListener<OverscrollNotification>(
      onNotification: (notification) {
        if (notification.dragDetails != null &&
            notification.dragDetails!.delta.dy > 15) {
          Navigator.of(context).pop();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.primaryGreen,
        body: Column(
          children: [
            // HEADER FIJO
            Container(
              width: double.infinity,
              height: headerHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Video con placeholder de imagen
                  Container(
                    width: double.infinity,
                    height: videoHeight,
                    color: AppColors.primaryGreen,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // El video se mostrará aquí cuando esté listo
                        if (_isVideoInitialized)
                          // Lógica condicional para el tipo de video
                          _videoController.value.aspectRatio > 1.1
                              ? // Video Horizontal: Rellena la pantalla
                              SizedBox.expand(
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: _videoController.value.size.width,
                                      height:
                                          _videoController.value.size.height,
                                      child: VideoPlayer(_videoController),
                                    ),
                                  ),
                                )
                              : // Video Vertical: Fondo desenfocado
                              Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Fondo con imagen del tutor, expandida y desenfocada
                                    SizedBox.expand(
                                      child: Image.network(
                                        widget.tutorImage,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    ClipRRect(
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 10, sigmaY: 10),
                                        child: Container(
                                          color: Colors.black.withOpacity(0.2),
                                        ),
                                      ),
                                    ),
                                    // Video contenido encima del fondo
                                    SizedBox.expand(
                                      child: FittedBox(
                                        fit: BoxFit.contain,
                                        child: SizedBox(
                                          width:
                                              _videoController.value.size.width,
                                          height: _videoController
                                              .value.size.height,
                                          child: VideoPlayer(_videoController),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        // Animación de carga personalizada mientras el video no está listo
                        if (!_isVideoInitialized)
                          Center(
                            child: Image.asset(
                              'assets/images/ave_animada.gif',
                              width: 80, // ajusta el tamaño como prefieras
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Botón de play sobre el video
                  if (_isVideoInitialized)
                    Positioned.fill(
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_videoController.value.isPlaying) {
                                _videoController.pause();
                              } else {
                                _videoController.play();
                              }
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(16),
                            child: Icon(
                              _videoController.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Fondo azul para la info
                  Positioned(
                    top: videoHeight,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: AppColors.primaryGreen,
                      height: avatarRadius + 40,
                    ),
                  ),
                  // Avatar (Circular)
                  Positioned(
                    top: videoHeight - avatarRadius,
                    left: 32,
                    child: Hero(
                      tag: 'tutor-image-${widget.tutorId}',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              CachedNetworkImageProvider(widget.tutorImage),
                        ),
                      ),
                    ),
                  ),
                  // Info a la derecha del avatar
                  Positioned(
                    top: videoHeight + 2,
                    left: 32 + avatarRadius + 68,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tutorName,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 14),
                            SizedBox(width: 2),
                            Text(
                              widget.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.school,
                                color: AppColors.blueColor, size: 13),
                            SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                '${widget.completedCourses}/18 cursos completados',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.blueColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Botón de regreso
                  Positioned(
                    top: 32,
                    left: 12,
                    child: SafeArea(
                      child: IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // CONTENIDO SCROLLABLE
            Expanded(
              child: ScrollConfiguration(
                behavior: NoGlowScrollBehavior(),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 8),
                      // Materias primero
                      _buildMaterias(),
                      SizedBox(height: 12),
                      // Idiomas después
                      Align(
                        alignment: Alignment.center,
                        child: _buildIdiomas(),
                      ),
                      SizedBox(height: 24),
                      _buildDescription(widget.description),
                      SizedBox(height: 100), // Espacio para el bottom bar
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // Botones y precio (sin cambios)
        bottomNavigationBar:
            _buildBottomBar(context, widget.tutorName, widget.tutorImage),
      ),
    );
  }

  Widget _buildMaterias() {
    final displayedSubjects = _areAllSubjectsShown
        ? widget.subjects
        : widget.subjects.take(_initialSubjectCount).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Materias que imparte',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              if (widget.subjects.length > _initialSubjectCount)
                TextButton(
                  child: Text(
                    _areAllSubjectsShown ? 'Ver menos' : 'Ver más...',
                    style: TextStyle(
                      color: AppColors.orangeprimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _areAllSubjectsShown = !_areAllSubjectsShown;
                    });
                  },
                ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            padding: EdgeInsets.all(16),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.start,
              children: displayedSubjects.map((subject) {
                return _buildStyledChip(subject);
              }).toList(),
            ),
          ),
        ),
        if (widget.subjects.length > _initialSubjectCount &&
            !_areAllSubjectsShown)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '${widget.subjects.length - _initialSubjectCount} materias más disponibles',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIdiomas() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Idiomas',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            padding: EdgeInsets.all(16),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.start,
              children: widget.languages.map((lang) {
                return _buildStyledChip(lang);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Card(
        color: Colors.white.withOpacity(0.12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: SizedBox(
          width: double.infinity, // Asegura que ocupe todo el ancho
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Acerca del Tutor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description, // Usar la descripción obtenida de la API
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Extraigo la parte inferior a una función para mantener el código limpio
  Widget _buildBottomBar(
      BuildContext context, String tutorName, String tutorImage) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: Offset(0, -10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.fromLTRB(
                16, 20, 16, 20 + MediaQuery.of(context).padding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '15 Bs',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '/ tutoría',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.timer_outlined,
                                  size: 16,
                                  color: Colors.white.withOpacity(0.8)),
                              SizedBox(width: 4),
                              Text(
                                '20 min',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              SizedBox(width: 12),
                              Icon(Icons.verified,
                                  size: 16, color: AppColors.blueColor),
                              SizedBox(width: 4),
                              Text(
                                'Tutor verificado',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.orangeprimary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: (_instantAvailable &&
                                  !_checkingInstantAvailability)
                              ? () {
                                  // Abrir Tutoría instantánea
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => Container(
                                      margin: EdgeInsets.only(top: 60),
                                      decoration: BoxDecoration(
                                        color: AppColors.darkBlue,
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(24)),
                                      ),
                                      child: InstantTutoringScreen(
                                        tutorName: widget.tutorName,
                                        tutorImage: widget.tutorImage,
                                        subjects: widget.subjects,
                                        tutorId:
                                            int.tryParse(widget.tutorId) ?? 1,
                                        subjectId: 1,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orangeprimary,
                            disabledBackgroundColor:
                                AppColors.orangeprimary.withOpacity(0.4),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_circle_outline,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                _checkingInstantAvailability
                                    ? 'Comprobando...'
                                    : _instantAvailable
                                        ? 'Tutoría ahora'
                                        : 'No disponible ahora',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            // Abrir modal de agendar (reserva)
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => Container(
                                margin: EdgeInsets.only(top: 60),
                                decoration: BoxDecoration(
                                  color: AppColors.darkBlue,
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(24)),
                                ),
                                child: BookingModal(
                                  tutorName: widget.tutorName,
                                  tutorImage: widget.tutorImage,
                                  subjects: widget.subjects,
                                  tutorId: int.tryParse(widget.tutorId) ?? 1,
                                  subjectId: 1,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  color: AppColors.primaryGreen, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Reservar',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NoGlowScrollBehavior extends ScrollBehavior {
  // buildViewportChrome is deprecated; keep default behavior
}
