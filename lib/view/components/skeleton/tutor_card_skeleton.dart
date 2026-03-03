import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/components/skeleton/skeleton_card.dart';
import 'package:flutter/material.dart';


class TutorCardSkeleton extends StatelessWidget {
  final bool isFullWidth;

  const TutorCardSkeleton({this.isFullWidth = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        width: isFullWidth ? MediaQuery.of(context).size.width : 360,
        margin: EdgeInsets.only(right: isFullWidth ? 0 : 16),
        decoration: BoxDecoration(
          color: AppColors.darkGreyColor, // Cambiado de whiteColor a darkGreyColor
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonCard(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.mediumGreyColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SkeletonCard(
                            child: Container(
                              width: 100,
                              height: 15,
                              color: AppColors.mediumGreyColor,
                            ),
                          ),
                          SizedBox(width: 10),
                          SkeletonCard(
                            child: Container(
                              width: 15,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.mediumGreyColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          SkeletonCard(
                            child: Container(
                              width: 25,
                              height: 15,
                              decoration: BoxDecoration(
                                color: AppColors.mediumGreyColor,
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      SkeletonCard(
                        child: Container(
                          width: 100,
                          height: 15,
                          color: AppColors.mediumGreyColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              SkeletonCard(
                child: Container(
                  width: 300,
                  height: 12,
                  color: AppColors.mediumGreyColor,
                ),
              ),
              SizedBox(height: 8),
              SkeletonCard(
                child: Container(
                  width: 200,
                  height: 12,
                  color: AppColors.mediumGreyColor,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  SkeletonCard(
                    child: Container(
                      width: 16,
                      height: 16,
                      color: AppColors.mediumGreyColor,
                    ),
                  ),
                  SizedBox(width: 5),
                  SkeletonCard(
                    child: Container(
                      width: 120,
                      height: 12,
                      color: AppColors.mediumGreyColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  // Row(
                  //   children: [
                  //     SkeletonCard(
                  //       child: Container(
                  //         width: 16,
                  //         height: 16,
                  //         color: Colors.green[300],
                  //       ),
                  //     ),
                  //     SizedBox(width: 5),
                  //     SkeletonCard(
                  //       child: Container(
                  //         width: 120,
                  //         height: 12,
                  //         color: Colors.green[300],
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // SizedBox(width: 60),
                  // Row(
                  //   children: [
                  //     SkeletonCard(
                  //       child: Container(
                  //         width: 16,
                  //         height: 16,
                  //         color: Colors.red[300],
                  //       ),
                  //     ),
                  //     SizedBox(width: 5),
                  //     SkeletonCard(
                  //       child: Container(
                  //         width: 100,
                  //         height: 12,
                  //         color: Colors.red[300],
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  SkeletonCard(
                    child: Container(
                      width: 16,
                      height: 16,
                      color: AppColors.mediumGreyColor,
                    ),
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: SkeletonCard(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: 12,
                        color: AppColors.mediumGreyColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}





