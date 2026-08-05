import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_projects/view/tutor/features/home/widgets/solicitud_flexible_card.dart';
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
import 'package:flutter_projects/provider/locale_provider.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:flutter_projects/view/student/services/profile_service.dart';
import 'package:flutter_projects/view/tutor/features/home/widgets/banner_terms_section.dart';
import 'package:intl/intl.dart';

import 'package:flutter_projects/view/components/animated_action_card.dart';
import 'package:flutter_projects/view/components/pulsing_book_icon.dart';

class DashboardStudent extends StatefulWidget {
  @override
  _DashboardStudentState createState() => _DashboardStudentState();
}

class _DashboardStudentState extends State<DashboardStudent>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  String? profileImageUrl;
  List<ReservationItem> _recentReservations = [];
  List<Map<String, dynamic>> _pendingFlexibleRequests = [];
  bool _isLoadingRecentReservations = true;
  DateTime? _targetBookingDate;
  late PageController _pageController;
  
  // Variables para el doble tap para salir
  DateTime? _lastBackPressedTime;
  static const Duration _exitDelay = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
        await _loadPendingFlexibleRequestsFromStorage();
      }
    });
  }

  Future<void> _loadPendingFlexibleRequestsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final jsonStr = prefs.getString('cached_pending_flexible_requests');
      print(
          '🔍 [DashboardStudent] Leyendo cached_pending_flexible_requests. Valor: $jsonStr');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        if (mounted) {
          setState(() {
            _pendingFlexibleRequests = decoded
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _pendingFlexibleRequests = [];
          });
        }
      }
    } catch (e) {
      print('Error cargando solicitudes flexibles en estudiante: $e');
    }
  }

  Future<void> _removePendingFlexibleRequest(
      Map<String, dynamic> itemData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final jsonStr = prefs.getString('cached_pending_flexible_requests');
      List<dynamic> list = [];
      if (jsonStr != null && jsonStr.isNotEmpty) {
        try {
          list = jsonDecode(jsonStr);
        } catch (_) {}
      }

      var decodificado = itemData['data_tutor'];
      String? targetToken;
      if (decodificado != null) {
        if (decodificado is String) {
          try {
            var p = jsonDecode(decodificado);
            if (p is String) p = jsonDecode(p);
            decodificado = p;
          } catch (_) {}
        }
        if (decodificado is Map) {
          targetToken = decodificado['token']?.toString() ??
              decodificado['accept_token']?.toString();
        }
      }
      targetToken ??=
          itemData['token']?.toString() ?? itemData['accept_token']?.toString();

      if (targetToken != null && targetToken.isNotEmpty) {
        list.removeWhere((item) {
          if (item is Map) {
            var d = item['data_tutor'];
            String? t;
            if (d != null) {
              if (d is String) {
                try {
                  var p = jsonDecode(d);
                  if (p is String) p = jsonDecode(p);
                  d = p;
                } catch (_) {}
              }
              if (d is Map) {
                t = d['token']?.toString() ?? d['accept_token']?.toString();
              }
            }
            t ??=
                item['token']?.toString() ?? item['accept_token']?.toString();
            return t == targetToken;
          }
          return false;
        });
      } else {
        list.remove(itemData);
      }

      await prefs.setString(
          'cached_pending_flexible_requests', jsonEncode(list));
      await _loadPendingFlexibleRequestsFromStorage();
    } catch (e) {
      print('Error removiendo solicitud flexible en estudiante: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      print(
          '📱 [DashboardStudent] App reanudada desde segundo plano. Refrescando reservas y solicitudes...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadRecentReservations();
          _loadPendingFlexibleRequestsFromStorage();
        }
      });
    }
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
    final localeProvider = Provider.of<LocaleProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Theme(
      data: AppTheme.studentLightTheme, // Aplicar tema específico para estudiante
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          // Si no estamos en Home (índice 0), navegar a Home
          if (_selectedIndex != 0) {
            setState(() => _selectedIndex = 0);
            _pageController.jumpToPage(0);
            return;
          }
          
          // Si estamos en Home, verificar doble tap
          final now = DateTime.now();
          
          if (_lastBackPressedTime == null || 
              now.difference(_lastBackPressedTime!) > _exitDelay) {
            _lastBackPressedTime = now;
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.pressBackAgainToExit),
                  duration: Duration(seconds: 2),
                ),
              );
            }
            return;
          }
          
          // Doble tap detectado - cerrar la app
          if (Platform.isAndroid || Platform.isIOS) {
            exit(0);
          } else {
            SystemNavigator.pop();
          }
        },
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light
          ),
          child: Scaffold(
          backgroundColor: AppColors.studentBackgroundLight,
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildHomeTab(Theme.of(context)), // Index 0
              _buildBookingsTab(), // Index 1
              const InstantTutoringScreen(), // Index 2
              _buildFavoritesTab(), // Index 3
              _buildProfileTab(), // Index 4
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
            homeLabel: l10n.homeNavigation,
            scheduleLabel: l10n.scheduleNavigation,
            favoritesLabel: l10n.favorites_nav,
            profileLabel: l10n.profile_nav,
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab(theme);
      case 1:
        return _buildBookingsTab();
      case 2:
        return FavoriteTutorsScreen(showBottomNav: false);
      case 3:
        return ProfileScreen(showAppBar: false);
      default:
        return _buildHomeTab(theme);
    }
  }

  Widget _buildHomeTab(ThemeData theme) {
    final authProvider = Provider.of<AuthProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final userData = authProvider.userData;

    final String? fullName = userData != null &&
            userData['user'] != null &&
            userData['user']['profile'] != null
        ? userData['user']['profile']['full_name']
        : null;

    final hasAcceptedTerms = userData?['user']?['terms_accepted'] == true;
    final currentLocale = localeProvider.locale?.languageCode ?? 'es';

    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: statusBarHeight + 15,
            left: 20,
            right: 20,
            bottom: 25,
          ),
          decoration: BoxDecoration(
            color: AppColors.studentHeaderBlue, // Azul marino para header
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.studentHeaderBlue.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: DashboardHeader(
            tutorName: fullName ?? l10n.defaultStudentName,
            profileImageUrl: profileImageUrl ??
                (userData != null &&
                        userData['user'] != null &&
                        userData['user']['profile'] != null
                    ? userData['user']['profile']['image']
                    : null),
            textColor: Colors.white,
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
                if (_pendingFlexibleRequests.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  ..._pendingFlexibleRequests.map(
                    (data) => SolicitudFlexibleCard(
                      data: data,
                      onClose: () => _removePendingFlexibleRequest(data),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildQuickActions(l10n, theme),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildRecentBookings(l10n, theme),
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

  Widget _buildQuickActions(AppLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickActions,
          style: theme.textTheme.titleLarge?.copyWith(
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
          childAspectRatio: 1.1,
          children: [
            AnimatedActionCard(
              icon: Icons.search,
              title: l10n.searchTutors,
              subtitle: l10n.findExperts,
              themeColor: AppColors.primaryGreen,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchTutorsScreen(),
                  ),
                );
              },
            ),
            AnimatedActionCard(
              icon: Icons.calendar_today,
              title: l10n.myBookings,
              subtitle: l10n.viewSessions,
              themeColor: AppColors.lightBlueColor,
              onTap: () {
                changeTab(1);
              },
            ),
            AnimatedActionCard(
              icon: Icons.favorite,
              title: l10n.favorites,
              subtitle: l10n.favoriteTutors,
              themeColor: AppColors.favoriteRed,
              onTap: () {
                changeTab(3);
              },
            ),
            AnimatedActionCard(
              icon: Icons.person_rounded,
              title: l10n.profile,
              subtitle: l10n.profileSettings,
              themeColor: AppColors.profilePurple,
              onTap: () {
                changeTab(4);
              },
            ),
          ],
        ),
      ],
    );
  }



  Widget _buildRecentBookings(AppLocalizations l10n, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recentBookings,
          style: theme.textTheme.titleLarge?.copyWith(
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
                SizedBox(height: 12),
                Text(
                  l10n.searchTutors,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.blackColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.noRecentBookings,
                  style: theme.textTheme.bodyMedium?.copyWith(
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
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.blackColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$formattedDate • ${reservation.status}',
                                style: theme.textTheme.bodyMedium?.copyWith(
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Column(
      children: [
        // Header azul marino
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: statusBarHeight + 15,
            left: 20,
            right: 20,
            bottom: 25,
          ),
          decoration: BoxDecoration(
            color: AppColors.headerLight,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.headerLight.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Text(
            l10n.reservations,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'outfit',
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 20, left: 16.0, right: 16.0),
            child: ReservationsContent(initialDate: _targetBookingDate),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectsTab(AppLocalizations l10n) {
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
                  l10n.subjectsTabTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.textTheme.titleLarge?.color ??
                          AppColors.blackColor),
                ),
                SizedBox(height: 8),
                Text(
                  l10n.subjectsTabSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
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

  Widget _buildFavoritesTab() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        // Header azul marino
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: statusBarHeight + 15,
            left: 20,
            right: 20,
            bottom: 25,
          ),
          decoration: BoxDecoration(
            color: AppColors.headerLight,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.headerLight.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Text(
            l10n.favoriteTutors,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'outfit',
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FavoriteTutorsContent(isSelected: _selectedIndex == 3),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        // Header azul marino
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: statusBarHeight + 15,
            left: 20,
            right: 20,
            bottom: 25,
          ),
          decoration: BoxDecoration(
            color: AppColors.headerLight,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.headerLight.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Row(
            children: [
              PulsingBookIcon(
                color: Colors.white,
                size: 28,
                duration: const Duration(milliseconds: 1500),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.myProfile,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'outfit',
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ProfileScreen(showAppBar: false),
        ),
      ],
    );
  }
}
