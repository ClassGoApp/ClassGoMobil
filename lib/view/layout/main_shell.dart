import 'package:flutter/material.dart';

import 'package:flutter_projects/view/home/home_screen.dart';
import 'package:flutter_projects/view/tutor/search_tutors_screen.dart';
import 'package:flutter_projects/view/tutor/student_calendar_screen.dart';
import 'package:flutter_projects/view/tutor/student_history_screen.dart';
import 'package:flutter_projects/view/profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late PageController _pageController;

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
    return Scaffold(
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

        selectedItemColor: const Color.fromARGB(255, 251, 133, 0), // 👈 COLOR ACTIVO
        unselectedItemColor: const Color.fromARGB(255, 255, 255, 255), // 👈 COLOR INACTIVO
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
            label: 'Tutoría Ya!'),
          // BottomNavigationBarItem(
          //     icon: Icon(Icons.calendar_month), label: 'Agenda'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
