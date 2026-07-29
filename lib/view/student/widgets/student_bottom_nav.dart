import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/styles/app_styles.dart';

import '../instant_tutoring/instant_tutoring_screen.dart'
    show InstantTutoringScreen;

class StudentBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onCenterTap;
  final String homeLabel;
  final String scheduleLabel;
  final String favoritesLabel;
  final String profileLabel;

  const StudentBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.onCenterTap,
    this.homeLabel = "HOME",
    this.scheduleLabel = "SCHEDULE",
    this.favoritesLabel = "FAVORITES",
    this.profileLabel = "PROFILE",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? AppColors.cardDark : AppColors.brandBlue;

    return SafeArea(
      child: Container(
        height: 76,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(40),
          border: isDark
              ? Border.all(color: Colors.white.withOpacity(0.1), width: 1)
              : null,
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: AppColors.brandBlue.withOpacity(0.4),
                blurRadius: 25,
                offset: const Offset(0, 1),
              )
            else
              BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Center(
                child: _AnimatedNavItem(
                  icon: Icons.home_rounded,
                  label: homeLabel,
                  isSelected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: _AnimatedNavItem(
                  icon: Icons.calendar_today_rounded,
                  label: scheduleLabel,
                  isSelected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
              ),
            ),

            // Large center button
            Expanded(
              child: Center(
                child: _CenterNavButton(
                  isSelected: currentIndex == 2,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (onCenterTap != null) {
                      onCenterTap!();
                      return;
                    }

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const InstantTutoringScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),

            Expanded(
              child: Center(
                child: _AnimatedNavItem(
                  icon: Icons.favorite,
                  label: favoritesLabel,
                  isSelected: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: _AnimatedNavItem(
                  icon: Icons.person_rounded,
                  label: profileLabel,
                  isSelected: currentIndex == 4,
                  onTap: () => onTap(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterNavButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CenterNavButton({required this.onTap, super.key, required bool isSelected});

  @override
  State<_CenterNavButton> createState() => _CenterNavButtonState();
}

class _CenterNavButtonState extends State<_CenterNavButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 78,
        height: 76,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final progress = _controller.value;
                final scale = 1.0 + (progress * 0.45);
                final opacity = (1.0 - progress) * 0.55;

                return IgnorePointer(
                  child: Transform.translate(
                    offset: const Offset(0, -18),
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color.fromRGBO(251, 133, 0, 1),
                              width: 5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Transform.translate(
              offset: const Offset(0, -18),
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(251, 133, 0, 1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.62),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.flash_on_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimatedNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Colors.white;
    final inactiveColor = Colors.white.withOpacity(0.4);
    const dotColor = AppColors.brandCyan;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: 76,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Icon that "jumps"
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.fastOutSlowIn,
              top: isSelected ? 12 : 26,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 10)
                        ]
                      : [],
                ),
                child: Icon(
                  icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 26,
                ),
              ),
            ),

            // Label text
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              bottom: isSelected ? 22 : 10,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.0,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontFamily: 'manrope',
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),

            // Cyan indicator dot
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.bounceInOut,
              bottom: isSelected ? 14 : 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isSelected ? 5 : 0,
                height: isSelected ? 5 : 0,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: dotColor.withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : [],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
