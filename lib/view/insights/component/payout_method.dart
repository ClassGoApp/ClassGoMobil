import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class PayoutMethodCard extends StatelessWidget {
  final int index;
  final String imagePath;
  final String title;
  final String amount;
  final String buttonTitle;
  final Function(int) onCardTap;
  final Function(int, String) onButtonTap;
  final int? selectedCardIndex;
  final bool isActive;

  const PayoutMethodCard({
    Key? key,
    required this.index,
    required this.imagePath,
    required this.title,
    required this.amount,
    required this.buttonTitle,
    required this.onCardTap,
    required this.onButtonTap,
    required this.selectedCardIndex,
    required this.isActive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final borderColor = isActive || (index == selectedCardIndex)
        ? AppColors.blackColor
        : AppColors.whiteColor;

    return GestureDetector(
      onTap: () {
        onCardTap(index);
      },
      child: Container(
        width: screenWidth * 0.45,
        padding: EdgeInsets.only(top: 12.0),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 3,
                blurRadius: 5),
          ],
          borderRadius: BorderRadius.circular(18),
          color: AppColors.whiteColor,
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: MediaQuery.of(context).size.width * 0.4,
              height: MediaQuery.of(context).size.width * 0.13,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 12),
            Text(
              amount,
              style: TextStyle(
                fontSize: FontSize.scale(context, 16),
                color: AppColors.blackColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: FontSize.scale(context, 12),
                color: AppColors.greyColor,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isActive)
                  Transform.scale(
                    scale: 0.92,
                    child: Radio(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      value: true,
                      groupValue: isActive || (index == selectedCardIndex),
                      onChanged: (value) {
                        onCardTap(index);
                      },
                      activeColor: AppColors.blackColor,
                      fillColor: WidgetStateProperty.all(
                        borderColor == AppColors.blackColor
                            ? AppColors.primaryGreen
                            : Colors.grey,
                      ),
                    ),
                  ),
                if (isActive)
                  Padding(
                    padding: EdgeInsets.only(left: 0),
                    child: Text(
                      'Make Default Method',
                      style: TextStyle(
                        fontSize: FontSize.scale(context, 12),
                        color: AppColors.blackColor.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                if (buttonTitle == 'Remove Account') {}
                onButtonTap(index, buttonTitle);
              },
              style: buttonTitle == 'Remove Account'
                  ? OutlinedButton.styleFrom(
                      backgroundColor: AppColors.redBackgroundColor,
                      side: BorderSide(
                        color: AppColors.redBorderColor,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 30),
                    )
                  : OutlinedButton.styleFrom(
                      backgroundColor: AppColors.whiteColor,
                      side: BorderSide(
                        color: AppColors.greyColor,
                        width: 0.1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 30),
                    ),
              child: Text(
                buttonTitle,
                style: TextStyle(
                  fontSize: FontSize.scale(context, 12),
                  color: buttonTitle == 'Remove Account'
                      ? AppColors.redColor
                      : AppColors.greyColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  ChartData(this.x, this.y);
  final int x;
  final double y;
}
