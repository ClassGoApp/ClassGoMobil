import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'package:flutter_projects/view/student/reservations/instant-reservation/instant_tutoring_screen.dart';
import 'package:flutter_projects/view/student/reservations/widgets/confirm_booking_modal.dart';
import 'package:flutter_projects/view/student/reservations/services/reservations_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';

class ReservationTutorProfileScreen extends StatefulWidget {
  final String tutorId;
  final String tutorName;
  final String tutorImage;
  final String tutorVideo;
  final String description;
  final double rating;
  final List<Map<String, dynamic>> subjects;
  final int completedCourses;

  // Idiomas por defecto
  final List<String> languages;
  final String? tagline;
  final double? price;

  const ReservationTutorProfileScreen({
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
    this.tagline = '',
    this.price,
  }) : super(key: key);

  @override
  _ReservationTutorProfileScreenState createState() =>
      _ReservationTutorProfileScreenState();
}

class _ReservationTutorProfileScreenState
    extends State<ReservationTutorProfileScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  final ScrollController _scrollController = ScrollController();
  bool _areAllSubjectsShown = false;
  static const int _initialSubjectCount = 6;
  static final _cacheManager = DefaultCacheManager();
  bool _instantAvailable = false;
  bool _checkingInstantAvailability = true;
  int _selectedTabIndex = 0;

  String _displaySubjectName(dynamic subject) {
    try {
      String name;
      if (subject is String) {
        name = subject;
      } else if (subject is Map && subject.containsKey('name')) {
        name = subject['name']?.toString() ?? '';
      } else {
        name = subject.toString();
      }
      final idx = name.indexOf('-');
      if (idx >= 0 && idx < name.length - 1) {
        return name.substring(idx + 1).trim();
      }
      return name;
    } catch (_) {
      return subject.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInstantAvailability();
    });
  }

  void _initializeVideo() async {
    if (widget.tutorVideo.isEmpty) return;

    try {
      final fileInfo = await _cacheManager.getFileFromCache(widget.tutorVideo);

      if (fileInfo != null) {
        _videoController = VideoPlayerController.file(fileInfo.file);
      } else {
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
      print('Error al inicializar el video: $e');
    }
  }

  Future<void> _checkInstantAvailability() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) {
        if (mounted) {
          setState(() {
            _instantAvailable = false;
            _checkingInstantAvailability = false;
          });
        }
        return;
      }

      final available = await ReservationsService.isTutorInstantAvailable(
          token, widget.tutorId);
      if (mounted) {
        setState(() {
          _instantAvailable = available;
          _checkingInstantAvailability = false;
        });
      }
    } catch (e) {
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
    try {
      _videoController.dispose();
    } catch (_) {}
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildStyledChip(dynamic label) {
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
        _displaySubjectName(label),
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
    // Ajusto headerHeight para dejar más espacio debajo del nombre
    // así los recuadros de estadísticas quedan claramente debajo del texto
    final double headerHeight = videoHeight + avatarRadius + 80;
    return NotificationListener<OverscrollNotification>(
      onNotification: (notification) {
        if (notification.dragDetails != null &&
            notification.dragDetails!.delta.dy > 15) {
          Navigator.of(context).pop();
        }
        return true;
      },
      child: Scaffold(
        // Fondo claro y elegante (predomina el blanco)
        backgroundColor: AppColors.backgroundLight,
        body: Stack(
          children: [
            ScrollConfiguration(
              behavior: NoGlowScrollBehavior(),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header con video, avatar, nombre y lema
                    Container(
                      width: double.infinity,
                      height: headerHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: double.infinity,
                            height: videoHeight,
                            color: AppColors.backgroundLight,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_isVideoInitialized)
                                  _videoController.value.aspectRatio > 1.1
                                      ? SizedBox.expand(
                                          child: FittedBox(
                                            fit: BoxFit.cover,
                                            child: SizedBox(
                                              width: _videoController
                                                  .value.size.width,
                                              height: _videoController
                                                  .value.size.height,
                                              child:
                                                  VideoPlayer(_videoController),
                                            ),
                                          ),
                                        )
                                      : Stack(
                                          alignment: Alignment.center,
                                          children: [
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
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                ),
                                              ),
                                            ),
                                            SizedBox.expand(
                                              child: FittedBox(
                                                fit: BoxFit.contain,
                                                child: SizedBox(
                                                  width: _videoController
                                                      .value.size.width,
                                                  height: _videoController
                                                      .value.size.height,
                                                  child: VideoPlayer(
                                                      _videoController),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                if (!_isVideoInitialized)
                                  Center(
                                    child: Image.asset(
                                      'assets/images/ave_animada.gif',
                                      width: 80,
                                    ),
                                  ),
                              ],
                            ),
                          ),
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
                          Positioned(
                            top: videoHeight,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: AppColors.backgroundLight,
                              height: avatarRadius + 40,
                            ),
                          ),
                          // Avatar centrado con check de verificación
                          Positioned(
                            top: videoHeight - avatarRadius,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Hero(
                                    tag:
                                        'reservation-tutor-image-${widget.tutorId}',
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: AppColors.dividerLight,
                                            width: 3),
                                      ),
                                      child: CircleAvatar(
                                        radius: avatarRadius,
                                        backgroundColor: AppColors.cardLight,
                                        backgroundImage:
                                            CachedNetworkImageProvider(
                                                widget.tutorImage),
                                      ),
                                    ),
                                  ),
                                  // Check de verificación
                                  Positioned(
                                    right: 4,
                                    bottom: 4,
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: AppColors.cardLight,
                                            width: 2),
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Nombre y detalle centrados debajo de la foto
                          Positioned(
                            top: videoHeight + avatarRadius + 8,
                            left: 0,
                            right: 0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  widget.tutorName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textLightPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.tagline != null &&
                                    widget.tagline!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 6.0,
                                      bottom: 4.0,
                                      left: 24.0,
                                      right: 24.0,
                                    ),
                                    child: Text(
                                      widget.tagline!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textLightSecondary,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0.2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildStatistics(),
                    SizedBox(height: 20),
                    _buildTabs(),
                    SizedBox(height: 20),
                    if (_selectedTabIndex == 0) ...[
                      _buildMaterias(),
                      SizedBox(height: 18),
                      Align(
                        alignment: Alignment.center,
                        child: _buildIdiomas(),
                      ),
                      SizedBox(height: 20),
                      _buildDescription(widget.description),
                    ] else ...[
                      _buildReviews(),
                    ],
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            // Botón de back posicionado de forma absoluta
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
                    child: Icon(Icons.arrow_back,
                        color: AppColors.textLightPrimary),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar:
            _buildBottomBar(context, widget.tutorName, widget.tutorImage),
      ),
    );
  }

  Widget _buildStatistics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildStatCard(
              Icons.star,
              widget.rating.toStringAsFixed(1),
              'Calificación',
              Colors.amber,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              Icons.rate_review,
              '124',
              'Reseñas',
              AppColors.blueColor,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              Icons.school,
              '89',
              'Clases',
              AppColors.orangeprimary,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              Icons.menu_book,
              '${widget.completedCourses}/18',
              'Cursos',
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.dividerLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textLightPrimary,
              ),
              maxLines: 1,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textLightSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTabIndex == 0
                          ? AppColors.blueColor
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  'Información',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: _selectedTabIndex == 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _selectedTabIndex == 0
                        ? AppColors.textLightPrimary
                        : AppColors.textLightSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTabIndex == 1
                          ? AppColors.blueColor
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  'Reseñas (124)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: _selectedTabIndex == 1
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _selectedTabIndex == 1
                        ? AppColors.textLightPrimary
                        : AppColors.textLightSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.blueColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.menu_book,
                        color: AppColors.blueColor, size: 18),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Materias que imparte',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLightPrimary),
                  ),
                ],
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
        SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.dividerLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
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
                color: AppColors.textLightSecondary,
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.language, color: Colors.green, size: 18),
              ),
              SizedBox(width: 10),
              Text(
                'Idiomas',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLightPrimary),
              ),
            ],
          ),
        ),
        SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.dividerLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Card(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: SizedBox(
          width: double.infinity,
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
                    color: Color(0xFF1A1D1E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textLightPrimary,
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

  Widget _buildReviews() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          _buildReviewCard(
            'María González',
            5.0,
            'Excelente tutor, muy claro en sus explicaciones.',
            '2 días atrás',
          ),
          SizedBox(height: 14),
          _buildReviewCard(
            'Carlos Ruiz',
            4.5,
            'Muy buena experiencia, aprendí mucho.',
            '1 semana atrás',
          ),
          SizedBox(height: 14),
          _buildReviewCard(
            'Ana Martínez',
            5.0,
            'Es paciente y explica todo de manera sencilla.',
            '2 semanas atrás',
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
      String name, double rating, String comment, String time) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dividerLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.greyFadeColor,
                child: Icon(Icons.person,
                    color: AppColors.textLightPrimary, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLightPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 14),
                        SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textLightSecondary,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textLightSecondary,
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
          Text(
            comment,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textLightPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
      BuildContext context, String tutorName, String tutorImage) {
    return Container(
      decoration: BoxDecoration(
        // Azul sólido para el panel inferior (no transparente)
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
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
            // Aseguramos que el color interno coincida con la decoración exterior
            color: AppColors.primaryGreen,
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
                                (widget.price != null)
                                    ? '\Bs ${widget.price!.toStringAsFixed(2)}'
                                    : '20',
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
                                        : 'No disponible',
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
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => ConfirmBookingModal(
                                tutorName: widget.tutorName,
                                tutorImage: widget.tutorImage,
                                subjects: widget.subjects,
                                tagline: widget.tagline,
                                tutorId: int.tryParse(widget.tutorId) ?? 1,
                                subjectId: 1,
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

class NoGlowScrollBehavior extends ScrollBehavior {}
