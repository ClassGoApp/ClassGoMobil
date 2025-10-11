import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import '../components/calendar_connection_widget.dart';

class GoogleIntegrationsScreen extends StatefulWidget {
  @override
  _GoogleIntegrationsScreenState createState() => _GoogleIntegrationsScreenState();
}

class _GoogleIntegrationsScreenState extends State<GoogleIntegrationsScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: Container(
          color: AppColors.primaryGreen,
          child: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: AppBar(
              backgroundColor: AppColors.primaryGreen,
              forceMaterialTransparency: true,
              elevation: 0,
              titleSpacing: 0,
              title: Text(
                'Integraciones de Google',
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: AppColors.whiteColor,
                  fontSize: FontSize.scale(context, 20),
                  fontFamily: 'SF-Pro-Text',
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.normal,
                ),
              ),
              leading: Padding(
                padding: const EdgeInsets.only(top: 3.0),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.arrow_back_ios,
                      size: 20, color: AppColors.whiteColor),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              centerTitle: false,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20),
              
              // Sección de Google Calendar
              CalendarConnectionWidget(),
              
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
