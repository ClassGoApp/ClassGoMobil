import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/student/serch_Tutor/search_tutors_screen.dart';

class CategoriesCarousel extends StatefulWidget {
  const CategoriesCarousel({super.key});

  @override
  State<CategoriesCarousel> createState() => _CategoriesCarouselState();
}

class _CategoriesCarouselState extends State<CategoriesCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'Contabilidad',
      'image':
          'https://www.classgoapp.com/images/home/Tugo-skin/contabilidad.webp'
    },
    {
      'title': 'Química',
      'image': 'https://www.classgoapp.com/images/home/Tugo-skin/quimica.webp'
    },
    {
      'title': 'Programación',
      'image':
          'https://www.classgoapp.com/images/home/Tugo-skin/programacion.webp'
    },
    {
      'title': 'Inglés',
      'image': 'https://www.classgoapp.com/images/home/Tugo-skin/ingles.webp'
    },
    {
      'title': 'Ciencias Exactas',
      'image':
          'https://www.classgoapp.com/images/home/Tugo-skin/matematicas.webp'
    },
    {
      'title': 'Música',
      'image': 'https://www.classgoapp.com/images/home/Tugo-skin/musica.webp'
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
              setState(() => _currentPage = page);
            },
            itemCount: _categories.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return _buildPosterCard(
                  isActive: index == _currentPage,
                  category: _categories[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPosterCard(
      {required bool isActive, required Map<String, dynamic> category}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(
        top: isActive ? 0 : 10,
        bottom: isActive ? 20 : 40,
        left: 10,
        right: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: AppColors.cardLight,
            )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Imagen
            Image.network(
              category['image'],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.brandBlue,
                  child: const Center(
                    child: Icon(Icons.image,
                        color: Color.fromARGB(0, 143, 9, 9), size: 40),
                  ),
                );
              },
            ),

            // 2. Gradiente inferior para proteger el texto
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),

            Positioned(
              bottom: 20,
              left: 12,
              right: 12,
              child: Text(
                category['title'] ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'outfit',
                  fontSize: isActive ? 22 : 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),

            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchTutorsScreen(
                        initialKeyword: category['title'],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
