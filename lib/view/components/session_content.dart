import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class SectionContent extends StatefulWidget {
  final String content;

  SectionContent({required this.content});

  @override
  _SectionContentState createState() => _SectionContentState();
}

class _SectionContentState extends State<SectionContent> {
  bool _isExpanded = false;

  bool _containsBulletPoints(String content) {
    return content.contains("•") ||
        content.contains("- ") ||
        content.contains("1.") ||
        content.contains("a.");
  }

  @override
  Widget build(BuildContext context) {
    final String fullContent = widget.content;
    final String previewContent =
        fullContent.length > 120 ? fullContent.substring(0, 120) : fullContent;

    bool isBulletPointContent = _containsBulletPoints(fullContent);

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: AppColors.greyColor,
          fontSize: FontSize.scale(context, 14),
          fontFamily: 'SF-Pro-Text',
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
        children: [
          TextSpan(
            text: _isExpanded || isBulletPointContent
                ? fullContent
                : previewContent,
          ),
          if (fullContent.length > 100 && !isBulletPointContent)
            TextSpan(
              text: _isExpanded ? ' see less' : 'see more',
              style: TextStyle(
                color: AppColors.greyColor,
                fontSize: FontSize.scale(context, 13),
                fontFamily: 'SF-Pro-Text',
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.normal,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
            ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.greyColor,
          fontSize: FontSize.scale(context, 16),
          fontFamily: 'SF-Pro-Text',
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.normal,
        ),
      ),
    );
  }
}
