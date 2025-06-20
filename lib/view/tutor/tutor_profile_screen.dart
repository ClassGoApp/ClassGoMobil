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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double avatarRadius = 54;
    final double videoHeight = 210;
    // Valor de ejemplo para cursos completados
    final int cursosCompletados = 4;
    final int totalCursosTutor = 18;
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER: video + fondo azul + avatar superpuesto + info a la derecha
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Video (sin overlays ni fondos encima)
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
                // Fondo azul para la info (empieza justo donde termina el video)
                Positioned(
                  top: videoHeight,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: AppColors.primaryGreen,
                    height: avatarRadius + 32,
                  ),
                ),
                // Avatar superpuesto (mitad sobre video, mitad sobre azul)
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
                // Info a la derecha del avatar, alineada verticalmente al centro de la mitad inferior del avatar
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
                      ),
                      SizedBox(height: 2),
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
            // SOLO ESTO ES SCROLLABLE
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Espacio justo para que no tape el header
                    SizedBox(height: avatarRadius / 2 + 40),
                    // Idiomas
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
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: widget.languages.map((lang) => Chip(
                              label: Text(lang, style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                              backgroundColor: Colors.white,
                              avatar: Icon(Icons.language, color: AppColors.primaryGreen, size: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18),
                    // Materias
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
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: widget.subjects.map((subject) => Chip(
                              label: Text(subject, style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
                              backgroundColor: Colors.white.withOpacity(0.9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18),
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
                    SizedBox(height: 160),
                  ],
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

  // Extraigo la parte inferior a una función para mantener el código limpio
  Widget bottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, -8),
            spreadRadius: 2,
          ),
        ],
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryGreen.withOpacity(0.95),
            AppColors.primaryGreen,
          ],
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
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
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.timer_outlined, 
                                  size: 16, 
                                  color: Colors.white.withOpacity(0.7)),
                              SizedBox(width: 4),
                              Text(
                                '20 min',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7),
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
                                  color: Colors.white.withOpacity(0.7),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
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