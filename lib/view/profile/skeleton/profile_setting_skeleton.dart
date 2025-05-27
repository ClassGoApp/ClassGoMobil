import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:shimmer/shimmer.dart';

class ProfileSettingsSkeleton extends StatelessWidget {
  const ProfileSettingsSkeleton({Key? key}) : super(key: key);

  Widget _buildShimmerBox({required double width, required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildShimmerCircle({required double size}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[300],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(width: 100, height: 10),
                SizedBox(height: 10),
                _buildSkeletonContainer(screenWidth),
                SizedBox(height: 10),
                _buildSkeletonContainer(screenWidth),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                        child: _buildShimmerBox(
                            width: screenWidth / 2 - 20, height: 50)),
                    SizedBox(width: 10),
                    Expanded(
                        child: _buildShimmerBox(
                            width: screenWidth / 2 - 20, height: 50)),
                  ],
                ),
                SizedBox(height: 15),
                _buildShimmerBox(width: screenWidth, height: 50),
                SizedBox(height: 16),
                _buildShimmerBox(width: 150, height: 20),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGenderSkeleton(),
                    _buildGenderSkeleton(),
                    _buildGenderSkeleton(),
                  ],
                ),
                SizedBox(height: 16),
                _buildShimmerBox(width: screenWidth, height: 50),
                SizedBox(height: 16),
                _buildShimmerBox(width: screenWidth, height: 50),
                SizedBox(height: 16),
                _buildShimmerBox(width: screenWidth, height: 50),
                SizedBox(height: 16),
                _buildShimmerBox(width: screenWidth, height: 50),
                SizedBox(height: 16),
                _buildShimmerBox(width: screenWidth, height: 50),
                SizedBox(height: 16),
                _buildShimmerBox(width: screenWidth, height: 50),
                SizedBox(height: 16),
                _buildShimmerBox(width: screenWidth, height: 50),
                SizedBox(height: 16),
                _buildShimmerBox(width: screenWidth, height: 100),
                SizedBox(height: 15),
                Divider(color: Colors.grey[300]),
                SizedBox(height: 20),
                _buildShimmerBox(width: screenWidth, height: 50),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonContainer(double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      width: screenWidth,
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildShimmerCircle(size: 50),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerBox(width: 120, height: 16),
              SizedBox(height: 8),
              _buildShimmerBox(width: 200, height: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSkeleton() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildShimmerCircle(size: 24),
        SizedBox(width: 8),
        _buildShimmerBox(width: 70, height: 16),
      ],
    );
  }
}
