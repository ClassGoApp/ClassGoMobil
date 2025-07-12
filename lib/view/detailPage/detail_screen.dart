import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/detailPage/widgets/tutor_video_section.dart';
import 'package:flutter_projects/view/detailPage/widgets/tutor_info_section.dart';
import 'package:flutter_projects/view/detailPage/component/html_description.dart';
import 'package:flutter_projects/view/bookSession/book_session.dart';
import 'package:flutter_projects/api_structure/api_service.dart' as api;
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';

class TutorDetailScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  final Map<String, dynamic> tutor;

  const TutorDetailScreen({
    Key? key,
    required this.profile,
    required this.tutor,
  }) : super(key: key);

  @override
  State<TutorDetailScreen> createState() => _TutorDetailScreenState();
}

class _TutorDetailScreenState extends State<TutorDetailScreen> {
  Map<String, dynamic>? tutorDetails;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchTutorDetails();
  }

  Future<void> _fetchTutorDetails() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final slug = widget.tutor['slug'] ?? '';

      final fetchedDetails = await api.getTutors(token, slug);

      setState(() {
        tutorDetails = fetchedDetails;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _onBookSession() {
    if (tutorDetails == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookSessionScreen(
          tutorDetails: tutorDetails!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        title: Text(
          'Perfil del Tutor',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? _buildLoadingWidget()
          : error != null
              ? _buildErrorWidget()
              : _buildContent(),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primaryGreen,
          ),
          SizedBox(height: 16),
          Text(
            'Cargando perfil del tutor...',
            style: TextStyle(
              color: AppColors.greyColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.greyColor,
          ),
          SizedBox(height: 16),
          Text(
            'Error al cargar el perfil',
            style: TextStyle(
              color: AppColors.greyColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            error ?? 'Error desconocido',
            style: TextStyle(
              color: AppColors.greyColor.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchTutorDetails,
            child: Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (tutorDetails == null) return _buildErrorWidget();

    final data = tutorDetails!['data'] ?? {};
    final profile = data['profile'] ?? {};
    final videoUrl = profile['intro_video'];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección de video
          TutorVideoSection(
            videoUrl: videoUrl,
            isLoading: isLoading,
          ),

          SizedBox(height: 16),

          // Sección de información del tutor
          TutorInfoSection(
            tutorDetails: data,
            onBookSession: _onBookSession,
          ),

          SizedBox(height: 16),

          // Sección de descripción
          if (profile['description'] != null &&
              profile['description'].isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sobre mí',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blackColor,
                    ),
                  ),
                  SizedBox(height: 12),
                  AboutMeSection(
                    description: profile['description'],
                  ),
                ],
              ),
            ),

          SizedBox(height: 100), // Espacio para el bottom bar
        ],
      ),
    );
  }
}
