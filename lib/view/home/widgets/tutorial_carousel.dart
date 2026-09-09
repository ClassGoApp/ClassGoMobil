import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';

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
    // Inicializar fade controller en estado "forward" para que sea visible desde el inicio
    _fadeController.forward();
    _scaleController.forward();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        if (_currentPage < 5) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutCubic,
          );
        } else {
          // Reiniciar al primer card
          _pageController.jumpToPage(0);
        }
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
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // --- PAGEVIEW ---
          SizedBox(
            height: 170,
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                _buildTutorialCard(
                  icon: '🚀',
                  title: l10n.learnInFiveSteps,
                  subtitle: l10n.discoverHowToConnect,
                  bgColor: AppColors.brandBlue.withOpacity(0.12),
                  borderColor: AppColors.brandBlue.withOpacity(0.3),
                  isIntro: true,
                ),
                _buildTutorialCard(
                  flutterIcon: Icons.flash_on_rounded,
                  title: l10n.step1TapInstant,
                  subtitle: l10n.findInstantTutoringButton,
                  bgColor: AppColors.brandCyan.withOpacity(0.12),
                  borderColor: AppColors.brandCyan.withOpacity(0.3),
                ),
                _buildTutorialCard(
                  icon: '📚',
                  title: l10n.step2ChooseSubject,
                  subtitle: l10n.selectYourFavoriteSubject,
                  bgColor: Color(0xFFFFA500).withOpacity(0.12),
                  borderColor: Color(0xFFFFA500).withOpacity(0.3),
                ),
                _buildTutorialCard(
                  icon: '👨‍🏫',
                  title: l10n.step3ConnectTutor,
                  subtitle: l10n.browseTutorsAndConnect,
                  bgColor: AppColors.brandOrange.withOpacity(0.12),
                  borderColor: AppColors.brandOrange.withOpacity(0.3),
                ),
                _buildTutorialCard(
                  icon: '📸',
                  title: l10n.step4ResolveDougbts,
                  subtitle: l10n.getInstantAnswers,
                  bgColor: Color(0xFFFF6B6B).withOpacity(0.12),
                  borderColor: Color(0xFFFF6B6B).withOpacity(0.3),
                ),
                _buildTutorialCard(
                  icon: '✨',
                  title: l10n.step5Confirmation,
                  subtitle: l10n.receiveConfirmation,
                  bgColor: AppColors.brandBlue.withOpacity(0.15),
                  borderColor: AppColors.brandBlue.withOpacity(0.3),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- DOTS INDICATORS ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              6,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: _currentPage == index ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentPage == index
                      ? AppColors.brandBlue
                      : AppColors.brandBlue.withOpacity(0.3),
                ),
              ),
            ),
          ),


        ],
      ),
    );
  }

  Widget _buildTutorialCard({
    String? icon,
    IconData? flutterIcon,
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color borderColor,
    bool isIntro = false,
    bool showSignInButton = false,
    VoidCallback? onSignInTap,
  }) {
    return FadeTransition(
      opacity: _fadeController,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1.0).animate(
          CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
        ),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: borderColor.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- ICON/EMOJI ---
              if (icon != null)
                Text(
                  icon,
                  style: const TextStyle(fontSize: 40),
                )
              else if (flutterIcon != null)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.brandOrange,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      flutterIcon,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 6),

              // --- TITLE ---
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandBlue,
                  fontFamily: AppFonts.heading,
                ),
              ),
              const SizedBox(height: 4),

              // --- SUBTITLE ---
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textLightSecondary,
                  height: 1.2,
                  fontFamily: AppFonts.body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
