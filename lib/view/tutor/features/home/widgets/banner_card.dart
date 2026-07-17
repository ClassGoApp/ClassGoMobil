import 'package:flutter/material.dart';

enum BannerCirclePosition { topRight, topLeft, bottomRight, bottomLeft }

class BannerCard extends StatelessWidget {
  final List<Color> gradientColors;
  final AlignmentGeometry gradientBegin;
  final AlignmentGeometry gradientEnd;
  final EdgeInsetsGeometry? margin;
  final BannerCirclePosition circlePosition;
  final double circleSize;
  final Color? circleColor;

  final double height;
  final Widget? leading;
  final Widget title;
  final String? description;
  final int? descriptionMaxLines;
  final Widget? extraContent;
  final Widget? button;

  const BannerCard({
    super.key,
    required this.gradientColors,
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
    this.margin = const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
    this.circlePosition = BannerCirclePosition.topRight,
    this.circleSize = 130,
    this.circleColor,
    this.height = 290,
    this.leading,
    required this.title,
    this.description,
    this.descriptionMaxLines,
    this.extraContent,
    this.button,
  });

  double get _halfOffset => -(circleSize / 2);

  BannerCirclePosition get _oppositeCorner {
    switch (circlePosition) {
      case BannerCirclePosition.topRight:
        return BannerCirclePosition.bottomLeft;
      case BannerCirclePosition.topLeft:
        return BannerCirclePosition.bottomRight;
      case BannerCirclePosition.bottomRight:
        return BannerCirclePosition.topLeft;
      case BannerCirclePosition.bottomLeft:
        return BannerCirclePosition.topRight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveCircleColor = circleColor ?? Colors.white.withOpacity(0.15);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: gradientBegin,
          end: gradientEnd,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            _buildCircle(circlePosition, circleSize, effectiveCircleColor),
            _buildCircle(_oppositeCorner, circleSize * 0.35, effectiveCircleColor.withOpacity(0.3)),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                height: height - 48 - (margin?.vertical ?? 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    if (description != null) const SizedBox(height: 16),
                    if (description != null) _buildDescription(),
                    if (extraContent != null && button != null) const Spacer(flex: 1),
                    if (extraContent != null) ...[
                      if (button == null) const SizedBox(height: 24),
                      extraContent!,
                    ],
                    if (extraContent != null && button != null) const Spacer(flex: 1),
                    if (button != null && extraContent == null) const Spacer(),
                    if (button != null)
                      SizedBox(width: double.infinity, child: button),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircle(BannerCirclePosition position, double size, Color color) {
    final half = -(size / 2);
    return Positioned(
      right: position == BannerCirclePosition.topRight || position == BannerCirclePosition.bottomRight ? half : null,
      left: position == BannerCirclePosition.topLeft || position == BannerCirclePosition.bottomLeft ? half : null,
      top: position == BannerCirclePosition.topRight || position == BannerCirclePosition.topLeft ? half : null,
      bottom: position == BannerCirclePosition.bottomRight || position == BannerCirclePosition.bottomLeft ? half : null,
      child: _plainCircle(color, size),
    );
  }

  Widget _plainCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _buildHeader() {
    if (leading != null) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: leading!,
          ),
          const SizedBox(width: 14),
          Expanded(child: title),
        ],
      );
    }
    return title;
  }

  Widget _buildDescription() {
    return Text(
      description!,
      style: TextStyle(
        fontFamily: 'manrope',
        fontSize: 13,
        color: Colors.white.withOpacity(0.85),
        height: 1.4,
        fontWeight: FontWeight.w500,
      ),
      maxLines: descriptionMaxLines,
      overflow: descriptionMaxLines != null ? TextOverflow.ellipsis : null,
    );
  }
}
