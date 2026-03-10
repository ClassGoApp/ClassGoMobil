import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/student/reservations/widgets/booking_modal.dart';

class ConfirmBookingModal extends StatelessWidget {
  final String tutorName;
  final String tutorImage;
  final List<String> subjects;
  final int tutorId;
  final int subjectId;
  final String? tagline;

  const ConfirmBookingModal({
    Key? key,
    required this.tutorName,
    required this.tutorImage,
    required this.subjects,
    required this.tutorId,
    required this.subjectId,
    this.tagline = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: AppColors.darkBlue,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: BookingModal(
        tutorName: tutorName,
        tutorImage: tutorImage,
        subjects: subjects,
        tagline: tagline,
        tutorId: tutorId,
        subjectId: subjectId,
      ),
    );
  }
}
