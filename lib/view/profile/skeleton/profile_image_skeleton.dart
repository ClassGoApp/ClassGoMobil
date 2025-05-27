import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ProfileImageSkeleton extends StatelessWidget {
  final double radius;
  final Color baseColor;
  final Color highlightColor;

  const ProfileImageSkeleton({
    Key? key,
    required this.radius,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: ClipOval(
          child: Container(
            width: radius * 2,
            height: radius * 2,
            color: Colors.grey[300],
          ),
        ),
      ),
    );
  }
}
