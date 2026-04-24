import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/components/skeleton/tutor_card_skeleton.dart';
import 'package:flutter_projects/view/student/reservations/tutor_reservation_screen.dart';
import 'package:flutter_projects/view/student/widgets/student_bottom_nav.dart';
import 'package:flutter_projects/view/components/role_based_navigation.dart';
import 'package:flutter_projects/view/student/favorite_tutor/services/favorite_tutor_service.dart';
import 'package:flutter_projects/view/student/serch_Tutor/search_tutors_screen.dart';
import 'package:flutter_projects/view/student/serch_Tutor/widgets/tutor_card.dart';
import 'package:flutter_projects/view/student/reservations/instant-reservation/instant_tutoring_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/helpers/slide_up_route.dart';

class FavoriteTutorsScreen extends StatefulWidget {
  final bool showBottomNav;
  const FavoriteTutorsScreen({Key? key, this.showBottomNav = true})
      : super(key: key);

  @override
  State<FavoriteTutorsScreen> createState() => _FavoriteTutorsScreenState();
}

class _FavoriteTutorsScreenState extends State<FavoriteTutorsScreen> {
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Tutores Favoritos',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'outfit',
          ),
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FavoriteTutorsContent(),
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? StudentBottomNav(
              currentIndex: 2,
              onTap: (index) {
                if (index == 2) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => RoleBasedNavigation()),
                  (route) => false,
                );
              },
            )
          : null,
    );
  }
}

/// Contenido reutilizable de la pantalla de Favoritos
class FavoriteTutorsContent extends StatefulWidget {
  const FavoriteTutorsContent({Key? key}) : super(key: key);

  @override
  State<FavoriteTutorsContent> createState() => _FavoriteTutorsContentState();
}

class _FavoriteTutorsContentState extends State<FavoriteTutorsContent> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;
  bool isInitialLoading = true;

  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadFavorites();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final dynamic rawId = authProvider.userData?['user']?['id'];

      final int? studentId =
          rawId is int ? rawId : (rawId is String ? int.tryParse(rawId) : null);

      if (token == null || token.isEmpty || studentId == null) {
        if (!mounted) return;
        setState(() {
          _favorites = [];
          _isLoading = false;
          isInitialLoading = false;
        });
        return;
      }

      final favorites = await FavoriteTutorService.fetchFavoriteDetails(
        token: token,
        studentId: studentId,
      );

      if (!mounted) return;
      setState(() {
        _favorites = favorites;
        _isLoading = false;
        isInitialLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _favorites = [];
        _isLoading = false;
        isInitialLoading = false;
      });
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  List<Map<String, dynamic>> _extractValidSubjects(Map<String, dynamic> tutor) {
    final subjects = tutor['subjects'];
    if (subjects is! List) return [];

    return subjects
        .whereType<Map>()
        .where((s) => s['status'] == 'active' && s['deleted_at'] == null)
        .map((s) => Map<String, dynamic>.from(s))
        .where((s) => (s['name'] ?? '').toString().isNotEmpty)
        .toList();
  }

  void _openTutorProfile(
    Map<String, dynamic> tutor,
    Map<String, dynamic> profile,
    List<Map<String, dynamic>> validSubjects,
  ) {
    _searchFocusNode.unfocus();

    Navigator.push(
      context,
      SlideUpRoute(
        page: ReservationTutorProfileScreen(
          tutorId: (tutor['id'] ?? profile['id'] ?? '').toString(),
          tutorName:
              (profile['full_name'] ?? tutor['name'] ?? 'No name available')
                  .toString(),
          tutorImage:
              (profile['image'] ?? AppImages.placeHolderImage).toString(),
          tutorVideo: (profile['intro_video'] ?? '').toString(),
          description:
              (profile['description'] ?? 'No hay descripción disponible.')
                  .toString(),
          rating: _toDouble(tutor['avg_rating']),
          subjects: validSubjects,
          completedCourses: _toInt(tutor['completed_courses_count']),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && isInitialLoading) {
      return _buildSkeletonList();
    }

    return _favorites.isEmpty ? _buildEmptyState() : _buildList();
  }

  Widget _buildSkeletonList() {
    return AnimationLimiter(
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 600),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: TutorCardSkeleton(isFullWidth: true),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Aún no tienes tutores favoritos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.blackColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Guarda tutores que te gusten para encontrarlos rápidamente.',
              style: TextStyle(
                  color: isDark ? Colors.white54 : AppColors.greyColor,
                  fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchTutorsScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Buscar Tutores',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primaryGreen,
      child: AnimationLimiter(
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _favorites.length,
          itemBuilder: (context, index) {
            final t = _favorites[index];

            final profile = (t['profile'] is Map)
                ? Map<String, dynamic>.from(t['profile'] as Map)
                : <String, dynamic>{};

            final validSubjects = _extractValidSubjects(t);
            final validSubjectNames = validSubjects
                .map((s) => (s['name'] ?? '').toString())
                .where((name) => name.isNotEmpty)
                .toList();
            final selectedSubjectId = validSubjects.isNotEmpty
                ? _toInt(validSubjects.first['id'])
                : 1;

            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 600),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: GestureDetector(
                      onTap: () => _openTutorProfile(t, profile, validSubjects),
                      child: TutorCard(
                        name:
                            (profile['full_name'] ?? t['name'] ?? 'Sin nombre')
                                .toString(),
                        rating: _toDouble(t['avg_rating']),
                        reviews: _toInt(t['total_reviews']),
                        imageUrl:
                            (profile['image'] ?? AppImages.placeHolderImage)
                                .toString(),
                        tutorId: (t['id'] ?? '').toString(),
                        tutorVideo: profile['intro_video']?.toString(),
                        tagline: profile['tagline']?.toString(),
                        onRejectPressed: () =>
                            _openTutorProfile(t, profile, validSubjects),
                        onAcceptPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => Container(
                              margin: const EdgeInsets.only(top: 60),
                              decoration: const BoxDecoration(
                                color: AppColors.darkBlue,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              child: InstantTutoringScreen(
                                tutorName: (profile['full_name'] ??
                                        'No name available')
                                    .toString(),
                                tutorImage: (profile['image'] ??
                                        AppImages.placeHolderImage)
                                    .toString(),
                                subjects: validSubjects,
                                tutorId: t['id'],
                                subjectId: selectedSubjectId,
                              ),
                            ),
                          );
                        },
                        tutorProfession: validSubjectNames.isNotEmpty
                            ? validSubjectNames.first
                            : 'No especificada',
                        sessionDuration: 'Clases de 20 minutos',
                        isFavoriteInitial: true,
                        onFavoritePressed: (isFavorite) async {
                          if (!isFavorite && mounted) {
                            try {
                              final authProvider = Provider.of<AuthProvider>(
                                  context,
                                  listen: false);

                              final token = authProvider.token;
                              final studentId =
                                  authProvider.userData?['user']?['id'];
                              final tutorId = t['id'];

                              await FavoriteTutorService.removeFavorite(
                                token: token!,
                                studentId: studentId,
                                tutorId: tutorId,
                              );

                              setState(() {
                                _favorites.removeWhere((item) =>
                                    (item['id'] ?? item['user_id'])
                                        .toString() ==
                                    tutorId.toString());
                              });
                            } catch (e) {
                              print(e);
                            }
                          }
                        },
                        subjectsString: validSubjectNames.join(', '),
                        description: (profile['description'] ?? '').toString(),
                        isVerified:
                            t['is_verified'] == true || t['is_verified'] == 1,
                        showStartButton: true,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
