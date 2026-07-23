import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/view/home/home_screen.dart';
import 'package:flutter_projects/view/student/serch_Tutor/search_tutors_screen.dart';
import 'package:flutter_projects/view/tutor/student_calendar_screen.dart';
import 'package:flutter_projects/view/tutor/student_history_screen.dart';
import 'package:flutter_projects/view/profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  static _MainShellState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainShellState>();
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late PageController _pageController;
  
  DateTime? _lastBackPressedTime;
  static const Duration _exitDelay = Duration(seconds: 2);

  void goToHome() {
    setState(() => _currentIndex = 0);
    _pageController.jumpToPage(0);
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        // Si no estamos en Home, navegar a Home
        if (_currentIndex != 0) {
          goToHome();
          return;
        }
        
        // Si estamos en Home, verificar doble tap
        final now = DateTime.now();
        
        if (_lastBackPressedTime == null || 
            now.difference(_lastBackPressedTime!) > _exitDelay) {
          _lastBackPressedTime = now;
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Presiona el botón de retroceso de nuevo para salir'),
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
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            HomeScreen(),
            SearchTutorsScreen(),
            StudentCalendarScreen(),
            StudentHistoryScreen(),
            ProfileScreen(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => (),
          backgroundColor: const Color.fromARGB(255, 251, 133, 0),
          shape: const CircleBorder(),
          child: const Icon(Icons.flash_on, color: Colors.white, size: 30),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color.fromARGB(255, 2, 48, 71),
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor:
              const Color.fromARGB(255, 251, 133, 0), // 👈 COLOR ACTIVO
          unselectedItemColor:
              const Color.fromARGB(255, 255, 255, 255), // 👈 COLOR INACTIVO
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(top: 24),
                child: SizedBox.shrink(),
              ),
              label: 'Tutoría Ya!',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history), 
              label: 'Historial',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}
