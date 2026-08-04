import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class AnimatedActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color themeColor;
  final VoidCallback onTap;
  final double? iconSize;
  final double? elevation;

  const AnimatedActionCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.themeColor,
    required this.onTap,
    this.iconSize = 40,
    this.elevation = 8,
  }) : super(key: key);

  @override
  State<AnimatedActionCard> createState() => _AnimatedActionCardState();
}

class _AnimatedActionCardState extends State<AnimatedActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
        },
        onExit: (_) {
          setState(() => _isHovered = false);
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: _isHovered
                  ? widget.themeColor.withOpacity(0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered
                    ? widget.themeColor.withOpacity(0.3)
                    : AppColors.dividerLight,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? widget.themeColor.withOpacity(0.15)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: _isHovered ? 12 : 8,
                  offset: _isHovered
                      ? const Offset(0, 6)
                      : const Offset(0, 4),
                  spreadRadius: _isHovered ? 1 : 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(20),
                splashColor: widget.themeColor.withOpacity(0.1),
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.themeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.themeColor,
                          size: widget.iconSize,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: AppFonts.heading,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandBlue,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: AppFonts.body,
                          fontSize: 12,
                          color: AppColors.textLightSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
