import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SessionDetailRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  SessionDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    String capitalizedValue =
        value.isNotEmpty ? value[0].toUpperCase() + value.substring(1) : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          SvgPicture.asset(
            icon,
            width: 35,
            height: 35,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.greyColor,
                fontSize: FontSize.scale(context, 14),
                fontFamily: 'SF-Pro-Text',
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.normal,
              ),
            ),
          ),
          Text(
            capitalizedValue,
            style: TextStyle(
              color: AppColors.greyColor,
              fontSize: FontSize.scale(context, 14),
              fontFamily: 'SF-Pro-Text',
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}
