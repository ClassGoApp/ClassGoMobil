import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class CategoriesCarousel extends StatefulWidget {
  const CategoriesCarousel({super.key});

  @override
  State<CategoriesCarousel> createState() => _CategoriesCarouselState();
}

class _CategoriesCarouselState extends State<CategoriesCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  // 🚨 AHORA USAMOS ASSETS LOCALES O ICONOS
  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'Contabilidad', 
      'localImage': 'assets/images/categories/contabilidad.png', // Cuando la tengas, pones la ruta aquí
      'icon': Icons.calculate_rounded,
      'color': const Color(0xFF4A90E2)
    },
    {
      'title': 'Química', 
      'localImage': 'assets/images/categories/quimica.png',
      'icon': Icons.science_rounded,
      'color': const Color(0xFF50E3C2)
    },
    {
      'title': 'Programación', 
      'localImage': 'assets/images/categories/programacion.png',
      'icon': Icons.terminal_rounded,
      'color': const Color(0xFF9013FE)
    },
    {
      'title': 'Inglés', 
      'localImage': 'assets/images/categories/ingles.png',
      'icon': Icons.language_rounded,
      'color': const Color(0xFFF5A623)
    },
    {
      'title': 'Ciencias Exactas', 
      'localImage': 'assets/images/categories/matematicas.png',
      'icon': Icons.functions_rounded,
      'color': const Color(0xFFE1145C)
    },
    {
      'title': 'Música', 
      'localImage': 'assets/images/categories/musica.png',
      'icon': Icons.music_note_rounded,
      'color': const Color(0xFF8B572A)
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.70, initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Explorar Materias',
            style: TextStyle(
              fontFamily: 'outfit',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.brandBlue,
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 340, 
          child: PageView.builder(
            clipBehavior: Clip.none,
            controller: _pageController,
            onPageChanged: (int page) {
              if (_currentPage != page) {
                setState(() => _currentPage = page);
              }
            },
            itemCount: _categories.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return _buildPosterCard(
                isActive: index == _currentPage, 
                category: _categories[index],
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPosterCard({required bool isActive, required Map<String, dynamic> category, required int index}) {
    final double topMargin = isActive ? 0 : 20.0;
    final double bottomMargin = isActive ? 10 : 30.0;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(top: topMargin, bottom: bottomMargin, left: 10, right: 10),
      child: Container(
        decoration: BoxDecoration(
          // Si no hay imagen, usamos el color base de la categoría
          color: category['color'], 
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: (category['color'] as Color).withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. EL FONDO (Icono gigante de placeholder mientras pones tus imágenes)
              Center(
                child: Icon(
                  category['icon'], 
                  size: 100, 
                  color: Colors.white.withOpacity(0.2) // Un efecto de agua (watermark)
                ),
              ),

              // NOTA PARA DIEGO: Cuando ya tengas las imágenes descargadas,
              // Descomenta este bloque de abajo y borrarás el Center de arriba.
              /*
              Image.asset(
                category['localImage'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
              */
              
              // 2. Gradiente inferior
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.5),
                    ],
                    stops: const [0.4, 0.7, 1.0],
                  ),
                ),
              ),
              
              // 3. Título Animado
              Positioned(
                bottom: 25,
                left: 15,
                right: 15,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'outfit',
                    fontSize: isActive ? 24 : 18, 
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  child: Text(category['title'] ?? ''),
                ),
              ),

              // 4. Tap
              Material(
                color: Colors.transparent,
                child: InkWell(
                  splashColor: Colors.white.withOpacity(0.2),
                  onTap: () {
                    if (!isActive) {
                      _pageController.animateToPage(index, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                    } else {
                      debugPrint("Abrir materia: ${category['title']}");
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}