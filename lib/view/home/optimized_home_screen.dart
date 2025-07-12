import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/home/widgets/home_header.dart';
import 'package:flutter_projects/view/home/widgets/search_bar_widget.dart';
import 'package:flutter_projects/view/home/widgets/menu_option_widget.dart';
import 'package:flutter_projects/view/home/widgets/featured_tutors_section.dart';
import 'package:flutter_projects/provider/home_provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/tutor/search_tutors_screen.dart';
import 'package:flutter_projects/view/tutor/instant_tutoring_screen.dart';
import 'package:flutter_projects/view/profile/profile_screen.dart';

class OptimizedHomeScreen extends StatefulWidget {
  final bool forceRefresh;
  final bool showVerificationSuccess;
  final String? verificationMessage;

  const OptimizedHomeScreen({
    Key? key,
    this.forceRefresh = false,
    this.showVerificationSuccess = false,
    this.verificationMessage,
  }) : super(key: key);

  @override
  State<OptimizedHomeScreen> createState() => _OptimizedHomeScreenState();
}

class _OptimizedHomeScreenState extends State<OptimizedHomeScreen> {
  bool _isLeftDrawerOpen = false;
  bool _isCustomDrawerOpen = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await homeProvider.refreshAll(authProvider.token);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Iniciar Sesión'),
        content: Text('Necesitas iniciar sesión para acceder a esta función.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            child: Text('Iniciar Sesión'),
          ),
        ],
      ),
    );
  }

  void _navigateToSearch() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token == null) {
      _showLoginRequiredDialog(context);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchTutorsScreen(),
      ),
    );
  }

  void _navigateToInstantTutoring() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token == null) {
      _showLoginRequiredDialog(context);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstantTutoringScreen(),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_pattern.png',
              fit: BoxFit.cover,
            ),
          ),
          // Main content
          SafeArea(
            child: Consumer<HomeProvider>(
              builder: (context, homeProvider, child) {
                return RefreshIndicator(
                  onRefresh: () => homeProvider.refreshAll(
                    Provider.of<AuthProvider>(context, listen: false).token,
                  ),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        HomeHeader(
                          onMenuTap: () {
                            setState(() {
                              _isLeftDrawerOpen = !_isLeftDrawerOpen;
                              _isCustomDrawerOpen = false;
                            });
                          },
                          onProfileTap: () {
                            setState(() {
                              _isCustomDrawerOpen = !_isCustomDrawerOpen;
                              _isLeftDrawerOpen = false;
                            });
                          },
                          isLeftDrawerOpen: _isLeftDrawerOpen,
                          isCustomDrawerOpen: _isCustomDrawerOpen,
                        ),

                        // Main content
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10),
                              Text(
                                'Aprende con\nTutorías en Línea',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(height: 24),

                              // Search Bar
                              SearchBarWidget(
                                onTap: _navigateToSearch,
                              ),
                              SizedBox(height: 24),

                              // Menu Options
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  MenuOptionWidget(
                                    icon: Icons.flash_on,
                                    label: 'Tutor\nal Instante',
                                    onTap: _navigateToInstantTutoring,
                                  ),
                                  MenuOptionWidget(
                                    icon: Icons.search,
                                    label: 'Buscar\nTutores',
                                    onTap: _navigateToSearch,
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),

                              // Featured Tutors Section
                              FeaturedTutorsSection(
                                tutors: homeProvider.featuredTutors,
                                isLoading: homeProvider.isLoadingTutors,
                                onTutorTap: () {
                                  // Navigate to tutor profile
                                },
                                scrollController: _scrollController,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
