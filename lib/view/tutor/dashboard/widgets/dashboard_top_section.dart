import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/styles/app_styles.dart';

// WIDGETS HIJOS
import 'package:flutter_projects/view/tutor/dashboard/widgets/dashboard_header.dart';
import 'package:flutter_projects/view/tutor/dashboard/widgets/availability_capsule.dart';

class DashboardTopSection extends StatelessWidget {
  // Datos
  final String tutorName;
  final String? profileImageUrl;
  final double rating;
  
  // Estados
  final bool isLoadingImage;
  final bool isAvailable;
  
  // Acciones
  final VoidCallback onLogoutTap;
  final Function(bool) onAvailabilityToggle;

  const DashboardTopSection({
    Key? key,
    required this.tutorName,
    this.profileImageUrl,
    required this.rating,
    this.isLoadingImage = false,
    required this.isAvailable,
    required this.onLogoutTap,
    required this.onAvailabilityToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark 
        ? AppColors.headerDark 
        : AppColors.headerLight;

    // Altura del Notch (Cámara frontal)
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent, 
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: statusBarHeight + 15, 
              bottom: 75,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: !isDark 
                  ? [
                      BoxShadow(
                        color: backgroundColor.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ] 
                  : null,
            ),
            
            child: Theme(
              data: ThemeData.dark().copyWith(
                scaffoldBackgroundColor: backgroundColor,
              ), 
              child: DashboardHeader(
                tutorName: tutorName,
                profileImageUrl: profileImageUrl,
                rating: rating,
                isVerified: true,
                isLoadingImage: isLoadingImage,
                isAvailable: isAvailable,
                onLogoutTap: onLogoutTap,
              ),
            ),
          ),

          // B. Availability Capsule 
          Positioned(
            bottom: -35,
            left: 5,
            right: 5,
            child: AvailabilityCapsule(
              isAvailable: isAvailable,
              onTap: () async {
                if (isAvailable) {
                   await HapticFeedback.lightImpact();
                } else {
                   await HapticFeedback.heavyImpact();
                }
                
                onAvailabilityToggle(!isAvailable);
              },
            ),
          ),
        ],
      ),
    );
  }
}