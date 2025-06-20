import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'package:flutter_projects/helpers/slide_up_route.dart';
import 'package:flutter_projects/view/tutor/instant_tutoring_screen.dart';

class TutorProfileScreen extends StatefulWidget {
  final String tutorId;
  final String tutorName;
  final String tutorImage;
  final String tutorVideo;
  final String description;
  final double rating;
  final List<String> subjects;

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

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.network(widget.tutorVideo)
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double avatarRadius = 54;
    final double videoHeight = 210;
    // Valor de ejemplo para cursos completados
    final int cursosCompletados = 4;
    final int totalCursosTutor = 18;
    // Altura total del header visual (video + mitad avatar + margen + nombre + valoración)
    final double headerHeight = videoHeight + avatarRadius * 0.85 + 24;
    return NotificationListener<OverscrollNotification>(
      onNotification: (notification) {
        if (notification.dragDetails != null && notification.dragDetails!.delta.dy > 15) {
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
                  // Video
                  Container(
                    width: double.infinity,
                    height: videoHeight,
                    child: _isVideoInitialized
                        ? AspectRatio(
                            aspectRatio: _videoController.value.aspectRatio,
                            child: VideoPlayer(_videoController),
                          )
                        : Center(child: CircularProgressIndicator(color: Colors.white)),
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
                              _videoController.value.isPlaying ? Icons.pause : Icons.play_arrow,
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
                  // Avatar superpuesto
                  Positioned(
                    top: videoHeight - avatarRadius,
                    left: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: avatarRadius,
                        backgroundColor: Colors.white,
                        backgroundImage: NetworkImage(widget.tutorImage),
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
                            SizedBox(width: 3),
                            Text(
                              'Valoración',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.school, color: AppColors.blueColor, size: 13),
                            SizedBox(width: 2),
                            Text(
                              '$cursosCompletados/$totalCursosTutor cursos de tutor',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.blueColor,
                                fontWeight: FontWeight.w600,
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
                      Align(
                        alignment: Alignment.center,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Materias',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            _buildSubjectsSection(),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      // Idiomas después
                      Align(
                        alignment: Alignment.center,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Idiomas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: widget.languages.map((lang) => Chip(
                                label: Text(lang, style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                                backgroundColor: Colors.white,
                                avatar: Icon(Icons.language, color: AppColors.primaryGreen, size: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      // Descripción
                      Align(
                        alignment: Alignment.center,
                        child: Card(
                          color: Colors.white.withOpacity(0.12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Acerca del tutor',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  widget.description,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.95),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // Botones y precio (sin cambios)
        bottomNavigationBar: bottomNavigationBar(context),
      ),
    );
  }

  Widget _buildSubjectsSection() {
    final subjectsToShow = _areAllSubjectsShown
        ? widget.subjects
        : widget.subjects.take(_initialSubjectCount).toList();

    return Wrap(
      spacing: 6,
      runSpacing: 2,
      alignment: WrapAlignment.center,
      children: [
        ...subjectsToShow.map((subject) => Chip(
              label: Text(subject, style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600, fontSize: 12)),
              backgroundColor: Colors.white.withOpacity(0.9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )),
        if (widget.subjects.length > _initialSubjectCount)
          ActionChip(
            onPressed: () {
              setState(() {
                _areAllSubjectsShown = !_areAllSubjectsShown;
              });
            },
            label: Text(
              _areAllSubjectsShown ? 'Ver menos' : '+${widget.subjects.length - _initialSubjectCount} más',
              style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)
            ),
            backgroundColor: Colors.white.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          )
      ],
    );
  }

  // Extraigo la parte inferior a una función para mantener el código limpio
  Widget bottomNavigationBar(BuildContext context) {
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
            padding: EdgeInsets.fromLTRB(16, 20, 16, 20 + MediaQuery.of(context).padding.bottom),
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
                                  size: 16, 
                                  color: AppColors.blueColor),
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
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => InstantTutoringScreen(
                                tutorName: widget.tutorName,
                                tutorImage: widget.tutorImage,
                                subjects: widget.subjects,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orangeprimary,
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
                                  color: Colors.white, 
                                  size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Tutoría ahora',
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
                            // Aquí irá la lógica para reservar
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
                                  color: AppColors.primaryGreen, 
                                  size: 18),
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
  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
} 