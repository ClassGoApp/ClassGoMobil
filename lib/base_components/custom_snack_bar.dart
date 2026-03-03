import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class CustomToast extends StatelessWidget {
  final String message;
  final bool isSuccess;

  const CustomToast({
    Key? key,
    required this.message,
    required this.isSuccess,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.cancel,
                color: isSuccess ? Colors.green : AppColors.redColor,
                size: 30.0,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  message,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                      fontFamily: 'SF-Pro-Text',
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.normal,
                      fontSize: FontSize.scale(context, 14),
                      color: AppColors.greyColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
