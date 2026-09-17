import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';

class TutorialCarousel extends StatefulWidget {
  const TutorialCarousel({super.key});

  @override
  State<TutorialCarousel> createState() => _TutorialCarouselState();
}

class _TutorialCarouselState extends State<TutorialCarousel>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Timer _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeController.forward();
    _scaleController.forward();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted && _pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer.cancel();
    _pageController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _fadeController.forward(from: 0.0);
    _scaleController.forward(from: 0.0);
    
    // Si llegamos al último item duplicado (index 6), volver al primero sin animación
    if (page == 6) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- TÍTULO Y DESCRIPCIÓN SUPERIOR ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.learnInFiveSteps,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.brandBlue,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.discoverHowToConnect,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textLightSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // --- CARRUSEL DE IMÁGENES/ICONOS ---
        SizedBox(
          height: 200,
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              _buildTutorialImage(
                icon: '🚀',
                title: l10n.learnInFiveSteps,
                subtitle: l10n.discoverHowToConnect,
                bgColor: AppColors.brandBlue.withOpacity(0.08),
                borderColor: AppColors.brandBlue.withOpacity(0.2),
              ),
              _buildTutorialImage(
                icon: '⚡',
                title: l10n.step1TapInstant,
                subtitle: l10n.findInstantTutoringButton,
                bgColor: AppColors.brandCyan.withOpacity(0.08),
                borderColor: AppColors.brandCyan.withOpacity(0.2),
              ),
              _buildTutorialImage(
                icon: '📚',
                title: l10n.step2ChooseSubject,
                subtitle: l10n.selectYourFavoriteSubject,
                bgColor: const Color(0xFFFFA500).withOpacity(0.08),
                borderColor: const Color(0xFFFFA500).withOpacity(0.2),
              ),
              _buildTutorialImage(
                icon: '👨‍🏫',
                title: l10n.step3ConnectTutor,
                subtitle: l10n.browseTutorsAndConnect,
                bgColor: AppColors.brandOrange.withOpacity(0.08),
                borderColor: AppColors.brandOrange.withOpacity(0.2),
              ),
              _buildTutorialImage(
                icon: '📸',
                title: l10n.step4ResolveDougbts,
                subtitle: l10n.getInstantAnswers,
                bgColor: const Color(0xFFFF6B6B).withOpacity(0.08),
                borderColor: const Color(0xFFFF6B6B).withOpacity(0.2),
              ),
              _buildTutorialImage(
                icon: '✨',
                title: l10n.step5Confirmation,
                subtitle: l10n.receiveConfirmation,
                bgColor: AppColors.brandBlue.withOpacity(0.08),
                borderColor: AppColors.brandBlue.withOpacity(0.2),
              ),
              // Repetir el primer item para crear efecto de loop infinito
              _buildTutorialImage(
                icon: '🚀',
                title: l10n.learnInFiveSteps,
                subtitle: l10n.discoverHowToConnect,
                bgColor: AppColors.brandBlue.withOpacity(0.08),
                borderColor: AppColors.brandBlue.withOpacity(0.2),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // --- DOTS INDICATORS ---
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              6,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: (_currentPage % 6) == index ? 24 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: (_currentPage % 6) == index
                      ? AppColors.brandBlue
                      : AppColors.brandBlue.withOpacity(0.25),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTutorialImage({
    required String icon,
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color borderColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeController,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1.0).animate(
          CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 12),

              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.brandBlue,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // --- SUBTÍTULO ---
              Flexible(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textLightSecondary,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
