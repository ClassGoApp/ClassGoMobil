import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class AboutMeSection extends StatefulWidget {
  final String description;

  const AboutMeSection({Key? key, required this.description}) : super(key: key);

  @override
  _AboutMeSectionState createState() => _AboutMeSectionState();
}

class _AboutMeSectionState extends State<AboutMeSection> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:AppColors.whiteColor,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'About me',
              style: TextStyle(
                color: AppColors.blackColor,                fontSize: FontSize.scale(context, 18),
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.normal,
                fontFamily: "SF-Pro-Text",
              ),
            ),
            SizedBox(height: 8.0),
            HtmlWidget(
              expanded ? widget.description : _truncateDescription(widget.description),
              textStyle: TextStyle(
                color:  AppColors.greyColor,
                fontSize: FontSize.scale(context, 15),
                fontWeight: FontWeight.w400,
                fontFamily: "SF-Pro-Text",
              ),
              customWidgetBuilder: (element) {
                List<Widget> children = [
                  HtmlWidget(
                    expanded ? widget.description : _truncateDescription(widget.description),
                    textStyle: TextStyle(
                      color:  AppColors.greyColor,
                      fontSize: FontSize.scale(context, 15),
                      fontWeight: FontWeight.w400,
                      fontFamily: "SF-Pro-Text",
                    ),
                  ),
                ];

                if (expanded) {
                  children.add(SizedBox(height: 8.0));
                  children.add(Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          expanded = false;
                        });
                      },
                      child: Text(
                        'See less',
                        style: TextStyle(
                          color: Colors.blue,
                                              fontSize: FontSize.scale(context, 14),
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                          fontFamily: "SF-Pro-Text",
                        ),
                      ),
                    ),
                  ));
                } else {
                  children.add(SizedBox(height: 8.0));
                  children.add(Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          expanded = true;
                        });
                      },
                      child: Text(
                        'See more',
                        style: TextStyle(
                          color: Colors.blue,
                                              fontSize: FontSize.scale(context, 14),
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                          fontFamily: "SF-Pro-Text",
                        ),
                      ),
                    ),
                  ));
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _truncateDescription(String description) {
    const int maxWords = 200;
    if (description.length <= maxWords) {
      return description;
    } else {
      return description.substring(0, maxWords) + '...';
    }
  }
}
