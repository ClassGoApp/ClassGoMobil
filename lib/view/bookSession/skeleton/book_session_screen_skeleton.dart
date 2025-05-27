import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:shimmer/shimmer.dart';

class BookSessionSkeleton extends StatelessWidget {
  const BookSessionSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildSessionListSkeleton()),
      ],
    );
  }

  Widget _buildSessionListSkeleton() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!, width: 1.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(width: 200, height: 16),
                SizedBox(height: 8),
                _buildShimmerBox(width: 150, height: 16),
                SizedBox(height: 15),
                Row(
                  children: [
                    _buildShimmerIcon(),
                    SizedBox(width: 4),
                    _buildShimmerBox(width: 100, height: 14),
                    SizedBox(width: 80),
                    _buildShimmerIcon(),
                    SizedBox(width: 5),
                    _buildShimmerBox(width: 100, height: 14),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    _buildShimmerIcon(),
                    SizedBox(width: 5),
                    _buildShimmerBox(width: 140, height: 14),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildShimmerButton(),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildShimmerButton(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({required double width, required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        color: Colors.grey[300],
      ),
    );
  }

  Widget _buildShimmerButton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 35,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _buildShimmerIcon() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class DateSelectorSkeleton extends StatelessWidget {
  const DateSelectorSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(width: 2, color: Colors.grey[300]!),
        ),
      ),
      child: ListView.builder(
        key: const PageStorageKey('dateSkeletonKey'),
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  ShimmerBox(width: 60, height: 16),
                  const SizedBox(height: 4),
                  ShimmerBox(width: 40, height: 14),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerBox({required this.width, required this.height, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        color: Colors.grey[300],
      ),
    );
  }
}
