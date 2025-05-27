import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/tutor/search_tutors_screen.dart';

class ThankYouPage extends StatefulWidget {
  @override
  _ThankYouPageState createState() => _ThankYouPageState();
}

class _ThankYouPageState extends State<ThankYouPage> {
  double _opacity = 0.0;
  double _scale = 0.5;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    Timer(Duration(milliseconds: 500), () {
      setState(() {
        _opacity = 1.0;
        _scale = 1.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Text(
          'Thank You',
          textAlign: TextAlign.start,
          style: TextStyle(
            color: AppColors.blackColor,            fontSize: FontSize.scale(context, 20),
            fontFamily: 'SF-Pro-Text',
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.normal,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              opacity: _opacity,
              duration: Duration(seconds: 1),
              child: AnimatedScale(
                scale: _scale,
                duration: Duration(seconds: 1),
                curve: Curves.easeOutBack,
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.darkGreen,
                  size: 100,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Payment Successful!",
              style: TextStyle(
                fontSize: FontSize.scale(context, 24),
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
                fontFamily: 'SF-Pro-Text',
                fontStyle: FontStyle.normal,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Thank you for purchase.",
              style: TextStyle(
                fontSize: FontSize.scale(context, 16),
                fontWeight: FontWeight.w400,
                color: AppColors.blackColor,
                fontFamily: 'SF-Pro-Text',
                fontStyle: FontStyle.normal,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(right: 15, left: 15),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchTutorsScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  'Continue',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontSize: FontSize.scale(context, 16),
                    color: AppColors.whiteColor,
                    fontFamily: 'SF-Pro-Text',
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.normal,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
