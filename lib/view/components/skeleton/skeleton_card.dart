import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class SkeletonCard extends StatelessWidget {
  final Widget child;

  SkeletonCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.mediumGreyColor, // Color base más oscuro
      highlightColor: AppColors.lightGreyColor, // Color de resplandor más claro
      child: child,
    );
  }
}
