import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/student/serch_Tutor/search_tutors_screen.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';

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
      'key': 'categoryAccounting',
      'image':
          'https://www.classgoapp.com/images/home/Tugo-skin/contabilidad.webp'
    },
    {
      'key': 'categoryChemistry',
      'image': 'https://www.classgoapp.com/images/home/Tugo-skin/quimica.webp'
    },
    {
      'key': 'categoryProgramming',
      'image':
          'https://www.classgoapp.com/images/home/Tugo-skin/programacion.webp'
    },
    {
      'key': 'categoryEnglish',
      'image': 'https://www.classgoapp.com/images/home/Tugo-skin/ingles.webp'
    },
    {
      'key': 'categoryExactSciences',
      'image':
          'https://www.classgoapp.com/images/home/Tugo-skin/matematicas.webp'
    },
    {
      'key': 'categoryMusic',
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            l10n.exploreSubjects,
            style: const TextStyle(
              fontFamily: AppFonts.heading,
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
    final l10n = AppLocalizations.of(context)!;
    final categoryKey = category['key'] as String;
    final categoryTitle = _getCategoryTitle(l10n, categoryKey);
    
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
                categoryTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.heading,
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
                        initialKeyword: categoryTitle,
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
  
  String _getCategoryTitle(AppLocalizations l10n, String key) {
    switch (key) {
      case 'categoryAccounting':
        return l10n.categoryAccounting;
      case 'categoryChemistry':
        return l10n.categoryChemistry;
      case 'categoryProgramming':
        return l10n.categoryProgramming;
      case 'categoryEnglish':
        return l10n.categoryEnglish;
      case 'categoryExactSciences':
        return l10n.categoryExactSciences;
      case 'categoryMusic':
        return l10n.categoryMusic;
      default:
        return '';
    }
  }
}
