import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class TutorCard extends StatelessWidget {
  final dynamic tutor; 
  final String subjectName;
  final VoidCallback onAccept;

  const TutorCard({
    super.key,
    required this.tutor,
    required this.subjectName,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppColors.blackColor.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: tutor.avatarUrl.startsWith('http')
                    ? NetworkImage(tutor.avatarUrl) as ImageProvider
                    : AssetImage(tutor.avatarUrl),
                backgroundColor: AppColors.fadeColor,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tutor.name,
                            style: const TextStyle(
                                fontFamily: 'outfit',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.blackColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (tutor.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified,
                              color: AppColors.brandBlue, size: 16),
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text("Disponible ahora",
                        style: TextStyle(
                            fontFamily: 'manrope', 
                            fontSize: 13,
                            color: AppColors.stateSuccess,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: AppColors.dividerColor)),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  tutor.pricePerHour,
                  style: const TextStyle(
                      fontFamily: 'outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandBlue),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 7,
                child: ElevatedButton(
                  onPressed: onAccept, 
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandCyan,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: const Text("Aceptar",
                      style: TextStyle(
                          fontFamily: 'manrope',
                          color: AppColors.whiteColor,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}