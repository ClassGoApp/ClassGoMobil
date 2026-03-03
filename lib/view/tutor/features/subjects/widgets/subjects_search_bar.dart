import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

const String kFontFamily = 'outfit'; 

class SubjectsSearchBar extends StatelessWidget {
  final TextEditingController controller;

  const SubjectsSearchBar({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF16181D) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: isDark ? Colors.white : AppColors.brandBlue, fontWeight: FontWeight.w600, fontFamily: kFontFamily),
        decoration: InputDecoration(
          hintText: "Encuentra tu próxima especialidad...",
          hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey[400], fontWeight: FontWeight.normal, fontFamily: kFontFamily),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.brandCyan, size: 22),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        ),
      ),
    );
  }
}