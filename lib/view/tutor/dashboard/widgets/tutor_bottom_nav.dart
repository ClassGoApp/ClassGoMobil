import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class TutorBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const TutorBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme =Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final backgroundColor = isDark 
        ? AppColors.cardDark
        : AppColors.brandBlue;
    
    return SafeArea(
      child: Container(
        height: 76, 
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
        color: backgroundColor,
          borderRadius: BorderRadius.circular(40), 
          border: isDark ? Border.all(color: Colors.white.withOpacity(0.1), width: 1) : null,
          boxShadow: [
            if(!isDark)
              BoxShadow(
                color: AppColors.brandBlue.withOpacity(0.4),
                blurRadius: 25,
                offset: const Offset(0, 1),
              )
            else 
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 5)
              ),       
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _AnimatedNavItem(
              icon: Icons.home_rounded,
              label: "INICIO",
              isSelected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _AnimatedNavItem(
              icon: Icons.calendar_today_rounded, 
              label: "AGENDA",
              isSelected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _AnimatedNavItem(
              icon: Icons.menu_book_rounded,
              label: "MATERIAS",
              isSelected: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _AnimatedNavItem(
              icon: Icons.person_rounded, 
              label: "PERFIL",
              isSelected: currentIndex == 3,
              onTap: () => onTap(3),
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
        width: 65,
        height: 76,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ÍCONO QUE "SALTA"
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.fastOutSlowIn,
              top: isSelected ? 12 : 26, 
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: isSelected ? [BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 10)]
                      : [], 
                ),
                child: Icon(
                  icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 26,
                ),
              ),
            ),

            // ÍCONO QUE "SALTA"
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

            // PUNTO INDICADOR CYAN
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