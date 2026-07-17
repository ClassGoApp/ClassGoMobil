import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/student/instant_tutoring/instant_tutoring_screen.dart';
import 'package:flutter_projects/view/student/serch_Tutor/search_tutors_screen.dart';
import 'package:flutter_projects/view/student/reservations/reservations_screen.dart';
import 'package:flutter_projects/view/student/reservations/services/reservations_service.dart';
import 'package:flutter_projects/view/student/widgets/student_bottom_nav.dart';
import 'package:flutter_projects/view/tutor/dashboard/widgets/dashboard_header.dart';
import 'package:flutter_projects/view/student/profile_screen_student.dart';
import 'package:flutter_projects/view/student/favorite_tutor/favorite_tutors_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/view/student/services/profile_service.dart';
import 'package:flutter_projects/view/tutor/features/home/widgets/banner_terms_section.dart';
import 'package:intl/intl.dart';

class DashboardStudent extends StatefulWidget {
  @override
  _DashboardStudentState createState() => _DashboardStudentState();
}

class _DashboardStudentState extends State<DashboardStudent> {
  int _selectedIndex = 0;
  String? profileImageUrl;
  List<ReservationItem> _recentReservations = [];
  bool _isLoadingRecentReservations = true;
  DateTime? _targetBookingDate;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final int? userId = authProvider.userId;
      if (userId != null) {
        try {
          final img = await ProfileService.fetchProfileImage(userId);
          if (mounted) setState(() => profileImageUrl = img);
        } catch (_) {}
      }

      if (mounted) {
        await _loadRecentReservations();
      }
    });
  }

  void changeTab(int index) {
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  }

  void _openBookingAgenda(DateTime? date) {
    setState(() {
      _targetBookingDate = date ?? DateTime.now();
    });
    changeTab(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildHomeTab(), // Index 0
            _buildBookingsTab(), // Index 1
            const InstantTutoringScreen(), // Index 2
            FavoriteTutorsScreen(
              showBottomNav: false,
              isSelected: _selectedIndex == 3,
            ), // Index 3
            const ProfileScreen(showAppBar: false), // Index 4
          ],
        ),
        bottomNavigationBar: StudentBottomNav(
          currentIndex: _selectedIndex,
          onTap: (index) {
            changeTab(index);
          },
          onCenterTap: () {
            changeTab(2);
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildBookingsTab();
      case 2:
        return FavoriteTutorsScreen(showBottomNav: false);
      case 3:
        return ProfileScreen(showAppBar: false);
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;

    final String? fullName = userData != null &&
            userData['user'] != null &&
            userData['user']['profile'] != null
        ? userData['user']['profile']['full_name']
        : null;

    final hasAcceptedTerms = userData?['user']?['terms_accepted'] == true;

    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top + 20),
        DashboardHeader(
          tutorName: fullName ?? 'Estudiante',
          profileImageUrl: profileImageUrl ??
              (userData != null &&
                      userData['user'] != null &&
                      userData['user']['profile'] != null
                  ? userData['user']['profile']['image']
                  : null),
          textColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : AppColors.blackColor,
          rating: 0.0,
          isVerified: false,
          isLoadingImage: false,
          isAvailable: false,
          onLogoutTap: () {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            authProvider.logout();
          },
          showRating: false,
          showVerified: false,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!hasAcceptedTerms) ...[
                  const SizedBox(height: 5),
                  const Align(
                    alignment: Alignment.topCenter,
                    child: BannerTermsSection(role: 'student'),
                  ),
                  const SizedBox(height: 8),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildQuickActions(),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildRecentBookings(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadRecentReservations() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final userId = authProvider.userId;

    if (token == null || userId == null) {
      if (mounted) {
        setState(() {
          _recentReservations = [];
          _isLoadingRecentReservations = false;
        });
      }
      return;
    }
    try {
      final reservations =
          await ReservationsService.fetchUserReservations(token, userId);
      if (!mounted) return;

      setState(() {
        _recentReservations = ReservationsService.filterRecentReservations(
          reservations,
          now: DateTime.now(),
        );
        _isLoadingRecentReservations = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _recentReservations = [];
          _isLoadingRecentReservations = false;
        });
      }
    }
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppColors.blackColor,
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.95,
          children: [
            _buildActionCard(
              icon: Icons.search,
              title: 'Buscar Tutores',
              subtitle: 'Encuentra expertos',
              color: AppColors.primaryGreen,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchTutorsScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              icon: Icons.calendar_today,
              title: 'Mis Reservas',
              subtitle: 'Ver sesiones',
              color: AppColors.lightBlueColor,
              onTap: () {
                changeTab(1);
              },
            ),
            _buildActionCard(
              icon: Icons.favorite,
              title: 'Favoritos',
              subtitle: 'Tutores favoritos',
              color: const Color.fromARGB(255, 255, 100, 88),
              onTap: () {
                changeTab(3);
              },
            ),
            _buildActionCard(
              icon: Icons.person_rounded,
              title: 'Perfil',
              subtitle: 'Ajustes del perfil',
              color: Colors.purple,
              onTap: () {
                changeTab(4);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
          ],
          border: isDark ? Border.all(color: Colors.white10) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color ?? AppColors.blackColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.greyColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookings() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reservas Recientes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.blackColor,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingRecentReservations)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
          )
        else if (_recentReservations.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
              border: isDark ? Border.all(color: Colors.white10) : null,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 48,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(height: 12),
                Text(
                  'No tienes reservas recientes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.blackColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Reserva una tutoría para ver tu historial aquí.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : AppColors.greyColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 48,
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
                )
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
              border: isDark ? Border.all(color: Colors.white10) : null,
            ),
            child: Column(
              children: _recentReservations.map((reservation) {
                final start = reservation.start;
                final formattedDate = start != null
                    ? DateFormat('dd MMM', 'es').format(start)
                    : 'Sin fecha';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: InkWell(
                    onTap: () => _openBookingAgenda(reservation.start),
                    borderRadius: BorderRadius.circular(10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.primaryGreen,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reservation.subjectName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.blackColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$formattedDate • ${reservation.status}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white54
                                      : AppColors.greyColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildBookingsTab() {
    // Usar el contenido reutilizable de Reservas (sin Scaffold ni bottom nav)
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top + 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ReservationsContent(initialDate: _targetBookingDate),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectsTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top + 20),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 64,
                  color: AppColors.greyColor,
                ),
                SizedBox(height: 16),
                Text(
                  'Favoritos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color ??
                        AppColors.blackColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Aquí verás todas las materias que estás estudiando',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : AppColors.greyColor,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
