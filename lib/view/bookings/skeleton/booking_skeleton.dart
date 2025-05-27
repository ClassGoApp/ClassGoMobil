import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:shimmer/shimmer.dart';

class BookingScreenSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        _buildDateSelectorSkeleton(),
        SizedBox(height: 20),
        Expanded(
            child:_buildBookingTableSkeleton(hasBookings: true)
        ),
      ],
    );
  }

  Widget _buildDateSelectorSkeleton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Shimmer.fromColors(
            baseColor: AppColors.whiteColor,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 40,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Shimmer.fromColors(
            baseColor: AppColors.whiteColor,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 40,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBookingTableSkeleton({required bool hasBookings}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        border: Border(
          top: BorderSide(color: AppColors.dividerColor, width: 1),
          bottom: BorderSide(color: AppColors.dividerColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 11.0),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 40,
                    height: 10,
                    color: Colors.grey[300],
                  ),
                ),
              ),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  width: 1,
                  height: 50,
                  color: AppColors.dividerColor,
                ),
              ),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 150,
                  height: 10,
                  color: Colors.grey[300],
                ),
              ),
            ],
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.dividerColor,
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(right: 20.0),
              itemCount: 24,
              itemBuilder: (context, index) {
                final hasBookingForThisSlot = index % 3 == 0 && hasBookings;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 10,
                        ),
                        Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 50,
                            height: 10,
                            color: Colors.grey[300],
                          ),
                        ),
                        SizedBox(width: 12),
                        Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 1,
                            height: 60,
                            color: AppColors.dividerColor,
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: hasBookingForThisSlot
                              ? Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: 300,
                              height: 40,
                              padding:
                              EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: AppColors.whiteColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  height: 50,
                                  color: Colors.grey[300],
                                ),
                              ),
                            ),
                          )
                              : SizedBox(height: 60),
                        ),
                      ],
                    ),
                    Container(
                      width: double.infinity,
                      color: AppColors.dividerColor,
                      height: 1,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}
