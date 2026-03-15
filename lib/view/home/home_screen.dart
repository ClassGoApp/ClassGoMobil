import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/home/widgets/home_drawer.dart';
import 'package:flutter_projects/view/home/widgets/home_header.dart';
import 'package:flutter_projects/view/home/widgets/menu_option_widget.dart';
import 'package:flutter_projects/view/home/widgets/social_button.dart';
import 'package:flutter_projects/view/home/widgets/start_journey_card.dart';

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
      drawer: const HomeDrawer(),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
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

                // Tutorias al instante
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: _placeholderBloque('Botón Naranja: Tutor al Instante',
                      height: 110, color: AppColors.brandOrange),
                ),

                const SizedBox(height: 30),

                // Top Tutores
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Top Tutores',
                        style: TextStyle(
                            fontFamily: 'outfit',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandBlue),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Ver todos',
                            style: TextStyle(
                                fontFamily: 'manrope',
                                color: AppColors.brandCyan,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                _placeholderBloque('Lista de Tutores Destacados',
                    height: 180, color: Colors.white),

                const SizedBox(height: 30),

                // Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: _placeholderBloque('Banner: Gana dinero enseñando',
                      height: 120, color: AppColors.brandBlue),
                ),
                const SizedBox(height: 20),
                MenuOptionWidget(
                    icon: Icons.ice_skating_outlined,
                    label: "diego",
                    onTap: () {}),
                const SizedBox(height: 20),
                SocialButton(
                    platform: "Tiktok",
                    url: "https:/tiktok.com",
                    icon: Icons.tiktok),
                SocialButton(
                    platform: "Tiktok",
                    url: "https:/tiktok.com",
                    icon: Icons.facebook_rounded),
                const SizedBox(height: 20),
                StartJourneyCard(),
                const SizedBox(height: 20),

                const SizedBox(height: 30),

                // CATEGORÍAS (Deslizable horizontal)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Explorar Categorías',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF113644)),
                  ),
                ),
                const SizedBox(height: 15),
                _placeholderBloque('Slider de Categorías (Matemáticas, etc)',
                    height: 140, color: Colors.white),

                const SizedBox(height: 30),

                // TUTORES DESTACADOS
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Tutores Destacados',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF113644)),
                  ),
                ),
                const SizedBox(height: 15),
                // const TutorListPreview(),
                _placeholderBloque('Lista de Tutores Destacados',
                    height: 250, color: Colors.white),

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
        color == AppColors.brandBlue || color == AppColors.brandOrange;
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
