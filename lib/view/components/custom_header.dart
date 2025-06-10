import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onFilterPressed;
  final Widget? trailingWidget;
  final bool showFilter;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final EdgeInsets padding;

  const CustomHeader({
    Key? key,
    required this.title,
    this.onFilterPressed,
    this.trailingWidget,
    this.showFilter = true,
    this.backgroundColor = AppColors.primaryGreen,
    this.textColor = AppColors.whiteColor,
    this.fontSize = 20,
    this.padding = const EdgeInsets.only(left: 20, right: 10.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: padding,
      child: AppBar(
        backgroundColor: backgroundColor,
        automaticallyImplyLeading: false,
        elevation: 0,
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: FontSize.scale(context, fontSize),
            fontFamily: 'SF-Pro-Text',
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (trailingWidget != null) trailingWidget!,
          if (showFilter)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Container(
                padding: EdgeInsets.all(0),
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: AppColors.navbar,
                  borderRadius: BorderRadius.all(Radius.circular(10))
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: SvgPicture.asset(
                    AppImages.filterIcon,
                    color: AppColors.whiteColor,
                    width: 15,
                    height: 15,
                  ),
                  onPressed: onFilterPressed,
                ),
              ),
            ),
        ],
      ),
    );
  }
} 