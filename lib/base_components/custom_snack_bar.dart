import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class CustomToast extends StatelessWidget {
  final String message;
  final bool isSuccess;
  final bool isWarning;

  const CustomToast({
    Key? key,
    required this.message,
    this.isSuccess = true,
    this.isWarning = false,
  }) : super(key: key);

  static void show(BuildContext context, String message, {bool isSuccess = true, bool isWarning = false}) {
    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) return;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100.0,
        left: 16.0,
        right: 16.0,
        child: CustomToast(
          message: message,
          isSuccess: isSuccess,
          isWarning: isWarning,
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    IconData iconData;

    if (isWarning) {
      iconColor = AppColors.brandOrange;
      iconData = Icons.info_outline_rounded;
    } else if (isSuccess) {
      iconColor = Colors.green;
      iconData = Icons.check_circle;
    } else {
      iconColor = AppColors.redColor;
      iconData = Icons.cancel;
    }

    return SafeArea(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                iconData,
                color: iconColor,
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