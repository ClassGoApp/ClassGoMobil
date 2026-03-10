import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/student/serch_Tutor/search_tutors_screen.dart';
import 'package:flutter_projects/view/student/reservations/reservations_screen.dart';
import 'package:flutter_projects/view/student/widgets/student_bottom_nav.dart';
import 'package:flutter_projects/view/tutor/dashboard/widgets/dashboard_header.dart';
import 'package:flutter_projects/view/student/profile_screen_student.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';

class DashboardStudent extends StatefulWidget {
  @override
  _DashboardStudentState createState() => _DashboardStudentState();
}

class _DashboardStudentState extends State<DashboardStudent> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: _buildBody(),
      bottomNavigationBar: StudentBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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
        return _buildSubjectsTab();
      case 3:
        return ProfileScreen(showAppBar: false);
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData;
    final String? fullName = userData != null && userData['user'] != null
        ? userData['user']['profile']['full_name']
        : null;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header estilo Tutor con padding top para status bar
          SizedBox(height: MediaQuery.of(context).padding.top + 20),
          DashboardHeader(
            tutorName: fullName ?? 'Estudiante',
            profileImageUrl: userData != null && userData['user'] != null
                ? userData['user']['profile']['image']
                : null,
            rating: 0.0,
            isVerified: false,
            isLoadingImage: false,
            isAvailable: false, // Not used without availability capsule
            onLogoutTap: () {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              authProvider.logout();
            },
            // show rating and verified only for tutors; hide for students
            showRating: false,
            showVerified: false,
          ),
          const SizedBox(height: 32),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _buildQuickActions(),
          ),
          SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _buildRecentBookings(),
          ),
          SizedBox(
              height:
                  24), // Reduced bottom space since nav is now in bottomNavigationBar
        ],
      ),
    );
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
            color: AppColors.blackColor,
          ),
        ),
        SizedBox(height: 16),
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
                setState(() {
                  _selectedIndex = 1;
                });
              },
            ),
            _buildActionCard(
              icon: Icons.menu_book_rounded,
              title: 'Mis Materias',
              subtitle: 'Ver materias',
              color: Colors.orange,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
              },
            ),
            _buildActionCard(
              icon: Icons.person_rounded,
              title: 'Perfil',
              subtitle: 'Ajustes del perfil',
              color: Colors.purple,
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
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
                color: AppColors.blackColor,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reservas Recientes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.blackColor,
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.greyColor,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'No tienes reservas recientes',
                    style: TextStyle(
                      color: AppColors.greyColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              ElevatedButton(
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Buscar Tutores',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
            child: ReservationsContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectsTab() {
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
                  'Mis Materias',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blackColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Aquí verás todas las materias que estás estudiando',
                  style: TextStyle(
                    color: AppColors.greyColor,
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
