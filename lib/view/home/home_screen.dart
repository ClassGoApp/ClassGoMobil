import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_projects/helpers/auth_helper.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/home/widgets/categories_carousel.dart';
import 'package:flutter_projects/view/home/widgets/home_drawer.dart';
import 'package:flutter_projects/view/home/widgets/home_header.dart';
import 'package:flutter_projects/view/home/widgets/pet_banner.dart';
import 'package:flutter_projects/view/home/widgets/quick_actions_section.dart';
import 'package:flutter_projects/view/home/widgets/trust_actions_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _cargarDatosEnSegundoPlano();
  }

  Future<void> _cargarDatosEnSegundoPlano() async {
    try {
      // Carga silenciosa
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundLight,
      // 🚨 SOSPECHOSO 1 APAGADO
      drawer: const HomeDrawer(),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // 🚨 SOSPECHOSO 2 APAGADO
          HomeHeader(
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            onProfileTap: () {
              debugPrint("Perfil");
            },
          ),
          
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 25),

                // 🚨 SOSPECHOSO 3 APAGADO
                QuickActionsRow(
                  onInstantTutorTap: () {
                    if (!AuthHelper.requireAuth(context,
                        customTitle: 'Acceso a Tutor al Instante',
                        customMessage:
                            'Para acceder a tutorías instantáneas, necesitas iniciar sesión en tu cuenta.')) {
                      return;
                    }

                    debugPrint(
                        "Usuario verificado. Abrir lógica de Tutor al Instante...");
                  },
                  onScheduleTap: () {
                    if (!AuthHelper.requireAuth(context,
                        customTitle: 'Agendar Tutoría',
                        customMessage:
                            'Para agendar una clase con un tutor, necesitas iniciar sesión.')) {
                      return;
                    }

                    debugPrint("Usuario verificado. Navegando a Agendar...");
                    // Navigator.push(...);
                  },
                  onExploreTap: () {
                    if (!AuthHelper.requireAuth(context,
                        customTitle: 'Explorar Tutores',
                        customMessage:
                            'Para ver perfiles completos y contactar tutores, inicia sesión.')) {
                      return;
                    }
                    debugPrint("Usuario verificado. Navegando a Explorar...");
                    // Navigator.push(...);
                  },
                ),

                const SizedBox(height: 25),
                // 🚨 SOSPECHOSO 4 APAGADO
                const MascotBanner(),

                const SizedBox(height: 35),
                // 🚨 SOSPECHOSO 5 APAGADO
                const CategoriesCarousel(),

                const SizedBox(height: 35),

                const TrustActionsRow(),
                
                const SizedBox(height: 35),
                _placeholderBloque('Lista de Tutores Destacados',
                    height: 180, color: Colors.white),

                const SizedBox(height: 30),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: _placeholderBloque('Banner: Gana dinero enseñando',
                      height: 120, color: AppColors.brandBlue),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderBloque(String titulo,
      {required double height, required Color color}) {
    bool isDark =
        color == AppColors.brandBlue || color == AppColors.brandOrange || color == Colors.red;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Center(
        child: Text(
          titulo,
          style: TextStyle(
              fontFamily: 'outfit',
              color: isDark ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),
      ),
    );
  }
}
