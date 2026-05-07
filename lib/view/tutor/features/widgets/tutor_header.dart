import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/tutor/dashboard/widgets/theme_toggle_button.dart';

class TutorHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBackTap;
  final IconData? actionIcon;
  final VoidCallback? onActionTap;

  const TutorHeader({
    Key? key,
    required this.title,
    required this.subtitle,
    this.onBackTap,
    this.actionIcon,
    this.onActionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bgColor = isDark ? const Color.fromARGB(255, 29, 28, 22) : AppColors.brandBlue;

    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(40),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: EdgeInsets.only(top: statusBarHeight + 4, bottom: 20, left: 20, right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            
            Expanded(
              child: Row(
                children: [
                  if (onBackTap != null) ...[
                    _buildGlassButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: onBackTap,
                    ),
                    const SizedBox(width: 16),
                  ] else ...[
                    const SizedBox(width: 13), 
                  ],
                  
                  // Textos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'outfit', 
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 12,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    left: 0,
                                    child: Container(
                                      width: 12, height: 12,
                                      decoration: const BoxDecoration(color: AppColors.brandCyan, shape: BoxShape.circle),
                                    ),
                                  ),
                                  Positioned(
                                    left: 8,
                                    child: Container(
                                      width: 12, height: 12,
                                      decoration: const BoxDecoration(color: AppColors.brandOrange, shape: BoxShape.circle),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                subtitle.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'manrope',
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (actionIcon != null) ...[
                  _buildGlassButton(
                    icon: actionIcon!,
                    onTap: onActionTap,
                  ),
                  const SizedBox(width: 12),
                ],
                
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                  ),
                  child: const ThemeToggleButton(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1), 
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5), 
        ),
        child: Icon(
          icon,
          color: Colors.white.withOpacity(0.9),
          size: 20,
        ),
      ),
    );
  }
}