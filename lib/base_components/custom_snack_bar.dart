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

  static void show(BuildContext context, String message, {bool isSuccess = true}) {
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
