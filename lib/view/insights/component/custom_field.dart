import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class CustomField extends StatelessWidget {
  final String labelText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const CustomField({
    Key? key,
    required this.labelText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          fontSize: FontSize.scale(context, 16),
          color:  AppColors.greyColor,
          fontFamily: 'SF-Pro-Text',
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.dividerColor,
            width: 1.5,
          ),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.dividerColor,
            width: 1.5,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.dividerColor,
            width: 1.5,
          ),
        ),
        contentPadding: EdgeInsets.only(bottom: 8),
      ),
    );
  }
}
