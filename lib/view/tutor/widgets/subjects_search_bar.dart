import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';

const String kFontFamily = 'outfit'; 

class SubjectsSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onClear;

  const SubjectsSearchBar({Key? key, required this.controller, this.onClear})
      : super(key: key);

  @override
  State<SubjectsSearchBar> createState() => _SubjectsSearchBarState();
}

class _SubjectsSearchBarState extends State<SubjectsSearchBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
    _hasText = widget.controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
  }

  void _handleTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF16181D) : Colors.white;
    final l10n = AppLocalizations.of(context)!;

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
        controller: widget.controller,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.brandBlue,
          fontWeight: FontWeight.w600,
          fontFamily: kFontFamily,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: l10n.addSubjectHint,
          hintStyle: TextStyle(
            color: isDark ? Colors.white30 : Colors.grey[400],
            fontWeight: FontWeight.normal,
            fontFamily: kFontFamily,
          ),
          border: InputBorder.none,
          prefixIcon:
              Icon(Icons.search_rounded, color: AppColors.brandCyan, size: 26),
          suffixIcon: _hasText
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: isDark ? Colors.white54 : Colors.grey[500]),
                  onPressed: () {
                    widget.controller.clear();
                    widget.onClear?.call();
                  },
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        ),
      ),
    );
  }
}