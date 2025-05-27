import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:shimmer/shimmer.dart';

class BillingInformationSkeleton extends StatelessWidget {
  const BillingInformationSkeleton({Key? key}) : super(key: key);

  Widget _buildShimmerBox({required double width, required double height, double? borderRadius}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(borderRadius ?? 0),
        ),
      ),
    );
  }

  Widget _buildShimmerButton(double width) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildShimmerBox(width: double.infinity, height: 50, borderRadius: 12),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildShimmerBox(width: double.infinity, height: 50, borderRadius: 12),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              _buildShimmerBox(width: screenWidth, height: 60, borderRadius: 12),
              SizedBox(height: 15),
              _buildShimmerBox(width: screenWidth, height: 60, borderRadius: 12),
              SizedBox(height: 15),
              _buildShimmerBox(width: screenWidth, height: 60, borderRadius: 12),
              SizedBox(height: 16),
              _buildShimmerBox(width: screenWidth, height: 60, borderRadius: 12),
              SizedBox(height: 16),
              _buildShimmerBox(width: screenWidth, height: 60, borderRadius: 12),
              SizedBox(height: 16),
              _buildShimmerBox(width: screenWidth, height: 60, borderRadius: 12),
              SizedBox(height: 16),
              _buildShimmerBox(width: screenWidth, height: 60, borderRadius: 12),
              SizedBox(height: 16),
              _buildShimmerBox(width: screenWidth, height: 130, borderRadius: 12),
              SizedBox(height: 15),
              Divider(color: Colors.grey[300]),
              SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.only(right: 15, left: 15),
                child: _buildShimmerButton(screenWidth - 30),
              ),
              SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}
