import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

class InternetAlertDialog extends StatelessWidget {
  final VoidCallback onRetry;

  const InternetAlertDialog({Key? key, required this.onRetry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.blackColor.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.only(top: 24, left: 16, right: 16,bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.lightPinkColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SvgPicture.asset(
                  AppImages.internetRequired,
                  width: 30,
                  height: 30,
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              "Internet Disconnected!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.blackColor,
                fontSize: FontSize.scale(context, 16),
                fontWeight: FontWeight.w400,
                fontFamily: "SF-Pro-Text",
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 1.0, bottom: 20.0),
              child: Text(
                "Oops! It looks like something went wrong.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.greyColor.withOpacity(0.7),
                  fontSize: FontSize.scale(context, 14),
                  fontWeight: FontWeight.w500,
                  fontFamily: "SF-Pro-Text",
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onRetry,
                child: Text(
                  "Retry",
                  style: TextStyle(
                    color: AppColors.whiteColor,
                    fontSize: FontSize.scale(context, 14),
                    fontWeight: FontWeight.w500,
                    fontFamily: "SF-Pro-Text",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

  }
}


