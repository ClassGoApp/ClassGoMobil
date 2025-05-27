import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StudentCard extends StatelessWidget {
  final String name;
  final String date;
  final String description;
  final double rating;
  final String image;
  final bool isFullWidth;

  StudentCard({
    required this.name,
    required this.date,
    required this.description,
    required this.rating,
    required this.image,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isFullWidth ? MediaQuery.of(context).size.width : 350,
      margin: EdgeInsets.only(right: isFullWidth ? 0 : 16),
      decoration: isFullWidth
          ? BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackColor,
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
            )
          : BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blackColor,
                  spreadRadius: 2,
                  blurRadius: 2,
                ),
              ],
            ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            image,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              textScaler: TextScaler.noScaling,
                              style: TextStyle(
                                color: AppColors.blackColor,
                                fontSize: FontSize.scale(context, 14),
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                                fontFamily: "SF-Pro-Text",
                              ),
                            ),
                            SizedBox(
                              width: 5.0,
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          date,
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                            color: AppColors.blackColor,
                            fontSize: FontSize.scale(context, 12),
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.normal,
                            fontFamily: "SF-Pro-Text",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    for (int i = 0; i < rating.toInt(); i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 2.0),
                        child: SvgPicture.asset(
                          AppImages.filledStar,
                          width: 18,
                          height: 18,
                        ),
                      ),
                    SizedBox(width: 10),
                    Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          TextSpan(
                            text: '$rating',
                            style: TextStyle(
                              color: AppColors.greyColor,
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                              fontFamily: "SF-Pro-Text",
                            ),
                          ),
                          TextSpan(
                            text: '/5.0',
                            style: TextStyle(
                              color: AppColors.greyColor,
                              fontSize: FontSize.scale(context, 13),
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                              fontFamily: "SF-Pro-Text",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  description,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    color: AppColors.greyColor,
                    fontSize: FontSize.scale(context, 14),
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.normal,
                    fontFamily: "SF-Pro-Text",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
