import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EducationCard extends StatelessWidget {
  final String position;
  final String institute;
  final String location;
  final String duration;
  final String description;
  final bool showDivider;

  EducationCard({
    required this.position,
    required this.institute,
    required this.location,
    required this.duration,
    required this.description,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final isExpanded = ValueNotifier<bool>(false);
    final words = description.split(RegExp(r'\s+'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          position,
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            color: AppColors.darkBlue,
            fontSize: FontSize.scale(context, 14),
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.normal,
            fontFamily: "SF-Pro-Text",
          ),
        ),
        SizedBox(height: 4),
        Row(
          children: [
            SvgPicture.asset(
              AppImages.bookEducationIcon,
              width: 16,
              height: 16,
              color: AppColors.greyColor,
            ),
            SizedBox(width: 5),
            Text(
              institute,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: AppColors.darkBlue,
                fontSize: FontSize.scale(context, 13),
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.normal,
                fontFamily: "SF-Pro-Text",
              ),
            )
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            SvgPicture.asset(
              AppImages.locationIcon,
              width: 16,
              height: 16,
              color: AppColors.greyColor,
            ),
            SizedBox(width: 5),
            Text(
              location,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: AppColors.darkBlue,
                fontSize: FontSize.scale(context, 13),
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.normal,
                fontFamily: "SF-Pro-Text",
              ),
            ),
          ],
        ),
        SizedBox(height: 8),

        Row(
          children: [
            SvgPicture.asset(
              AppImages.bookingCalender,
              width: 16,
              height: 16,
              color: AppColors.greyColor,
            ),
            SizedBox(width: 5),
            Text(
              duration,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: AppColors.darkBlue,
                fontSize: FontSize.scale(context, 13),
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.normal,
                fontFamily: "SF-Pro-Text",
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        ValueListenableBuilder<bool>(
          valueListenable: isExpanded,
          builder: (context, expanded, child) {
            String displayedText = expanded || words.length <= 20
                ? description
                : words.take(20).join(' ') + '...';

            return RichText(
              text: TextSpan(
                style: TextStyle(
                  color: AppColors.darkBlue,
                  fontSize: FontSize.scale(context, 14),
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal,
                  fontFamily: "SF-Pro-Text",
                ),
                children: [
                  TextSpan(
                    text: displayedText,
                  ),
                  if (words.length > 20)
                    TextSpan(
                      text: expanded ? ' See less' : ' See more',
                      style: TextStyle(
                        color: AppColors.darkBlue,
                        fontSize: FontSize.scale(context, 14),
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                        fontFamily: "SF-Pro-Text",
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          isExpanded.value = !expanded;
                        },
                    ),
                ],
              ),
            );
          },
        ),
        if (showDivider)
          Divider(
            color: AppColors.dividerColor,
          ),
        SizedBox(height: 8),
      ],
    );
  }
}
