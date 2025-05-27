import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:shimmer/shimmer.dart';

class InsightScreenSkeleton extends StatelessWidget {
  const InsightScreenSkeleton({Key? key}) : super(key: key);

  Widget _buildShimmerBox({
    required double width,
    required double height,
    double borderRadius = 0,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(borderRadius),
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

  Widget _buildEarningCardSkeleton() {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildShimmerCircle(size: 50),
          const SizedBox(height: 16),
          _buildShimmerBox(width: 60, height: 16),
          const SizedBox(height: 8),
          _buildShimmerBox(width: 80, height: 12),
        ],
      ),
    );
  }

  Widget _buildWalletBalanceSkeleton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
        color:  AppColors.whiteColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildShimmerCircle(size: 20),
                  const SizedBox(width: 10),
                  _buildShimmerBox(width: 100, height: 16),
                ],
              ),
              _buildShimmerBox(width: 80, height: 16),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildRowSkeleton(),
          ),
        ],
      ),
    );
  }

  Widget _buildRowSkeleton() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Icon(
              Icons.attach_money,
              color: Colors.grey[400],
              size: 24,
            ),
          ),
        ),
        Expanded(
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 50,
              color: Colors.grey[300],
            ),
          ),
        ),
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20.0),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(10.0),
                bottomRight: Radius.circular(10.0),
              ),
            ),
            child: Icon(
              Icons.arrow_forward,
              color: Colors.grey[400],
              size: 24,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildTextSectionSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildShimmerBox(width: 120, height: 16),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildPayoutMethodSkeleton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth * 0.45,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
       color: AppColors.whiteColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 3,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildShimmerBox(width:50, height: screenWidth * 0.13,borderRadius: 8),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildShimmerCircle(size: 20),
              const SizedBox(width: 5),
              _buildShimmerBox(width: 30, height: 12),
            ],
          ),
          const SizedBox(height: 10),
          _buildShimmerBox(width: screenWidth * 0.25, height: 12),
          const SizedBox(height: 10),
          _buildShimmerBox(width: screenWidth * 0.3, height: 30,borderRadius: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    itemBuilder: (context, index) =>
                        _buildEarningCardSkeleton(),
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextSectionSkeleton(),
                const SizedBox(height: 10),
                Shimmer.fromColors(
                  baseColor: AppColors.whiteColor,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey[300]!,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextSectionSkeleton(),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(
                        3, (index) => _buildPayoutMethodSkeleton(context)),
                  ),
                ),
                const SizedBox(height: 170),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildWalletBalanceSkeleton(context),
          ),
        ],
      ),
    );
  }
}
