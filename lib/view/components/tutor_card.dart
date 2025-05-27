import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../provider/auth_provider.dart';

class TutorCard extends StatefulWidget {
  final String name;
  final String price;
  final String description;
  final double rating;
  final String reviews;
  final String activeStudents;
  final String sessions;
  final String languages;
  final String image;
  final String countryFlag;
  final String verificationIcon;
  final String onlineIndicator;
  final bool languagesText;
  final bool filledStar;
  final bool hourRate;
  final bool isFullWidth;
  final int tutorId;

  TutorCard({
    required this.tutorId,
    required this.name,
    required this.price,
    required this.description,
    required this.rating,
    required this.reviews,
    required this.activeStudents,
    required this.sessions,
    required this.languages,
    required this.image,
    required this.countryFlag,
    required this.verificationIcon,
    required this.onlineIndicator,
    this.languagesText = false,
    this.filledStar = false,
    this.hourRate = true,
    this.isFullWidth = false,
  });

  @override
  State<TutorCard> createState() => _TutorCardState();
}

class _TutorCardState extends State<TutorCard> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    final String truncatedDescription = widget.description.length > 52
        ? '${widget.description.substring(0, 52)}...'
        : widget.description;

    String displayLanguages =
        widget.languages.isNotEmpty ? widget.languages : 'No languages listed';

    String profileImageUrl =
        authProvider.userData?['user']['profile']['image'] ?? '';

    Widget displayImage() {
      return widget.image.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: widget.image,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (context, url) => SizedBox(
                width: 60,
                height: 60,
              ),
              errorWidget: (context, url, error) {
                return profileImageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: profileImageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => SizedBox(
                          width: 60,
                          height: 60,
                          child: Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: AppColors.primaryGreen),
                          ),
                        ),
                        errorWidget: (context, url, error) => SvgPicture.asset(
                          AppImages.personOutline,
                          width: 60,
                          height: 60,
                          alignment: Alignment.center,
                        ),
                      )
                    : SvgPicture.asset(
                        AppImages.personOutline,
                        width: 60,
                        height: 60,
                        alignment: Alignment.center,
                      );
              },
            )
          : profileImageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: profileImageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => SizedBox(
                    width: 60,
                    height: 60,
                    child: Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2.0, color: AppColors.primaryGreen),
                    ),
                  ),
                  errorWidget: (context, url, error) => SvgPicture.asset(
                    AppImages.personOutline,
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                  ),
                )
              : SvgPicture.asset(
                  AppImages.personOutline,
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        width: widget.isFullWidth
            ? MediaQuery.of(context).size.width
            : MediaQuery.of(context).size.width * 0.9,
        margin: EdgeInsets.only(right: widget.isFullWidth ? 0 : 16),
        decoration: widget.isFullWidth
            ? BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [],
              )
            : BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.greyColor.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: displayImage(),
                      ),
                      if (widget.onlineIndicator.isNotEmpty)
                        Positioned(
                          bottom: -10,
                          left: 22,
                          child: Image.asset(
                            widget.onlineIndicator,
                            width: 16,
                            height: 16,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.4,
                            child: Text(
                              widget.name,
                              textAlign: TextAlign.start,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.navbar,
                                fontSize: FontSize.scale(context, 18),
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.normal,
                                fontFamily: "SF-Pro-Text",
                              ),
                            ),
                          ),
                          SizedBox(width: 2),
                          if (widget.verificationIcon.isNotEmpty)
                            Icon(
                              Icons.verified,
                              color: AppColors.navbar,
                              size: 16,
                            ),
                          SizedBox(width: 2),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          text: 'A partir de ',
                          style: TextStyle(
                            color: AppColors.greyColor,
                            fontSize: FontSize.scale(context, 14),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontFamily: "SF-Pro-Text",
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: widget.price,
                              style: TextStyle(
                                color: AppColors.blackColor,
                                fontSize: FontSize.scale(context, 16),
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                                fontFamily: "SF-Pro-Text",
                              ),
                            ),
                            TextSpan(
                              text: '/hr',
                              style: TextStyle(
                                color: AppColors.greyColor,
                                fontSize: FontSize.scale(context, 14),
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                                fontFamily: "SF-Pro-Text",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                truncatedDescription,
                style: TextStyle(
                    color: AppColors.blackColor,
                    fontSize: FontSize.scale(context, 14),
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.normal,
                    fontFamily: "SF-Pro-Text"),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  SvgPicture.asset(
                    widget.filledStar ? AppImages.filledStar : AppImages.star,
                    color:
                        widget.filledStar ? AppColors.navbar : AppColors.navbar,
                    width: 16,
                    height: 16,
                  ),
                  SizedBox(width: 5),
                  Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: '${widget.rating}',
                          style: TextStyle(
                            color: AppColors.greyColor,
                            fontSize: FontSize.scale(context, 14),
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.normal,
                            fontFamily: "SF-Pro-Text",
                          ),
                        ),
                        TextSpan(
                          text: '/5.0 (${widget.reviews} reseñas)',
                          style: TextStyle(
                            color: AppColors.greyColor.withOpacity(0.7),
                            fontSize: FontSize.scale(context, 14),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontFamily: "SF-Pro-Text",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(
                        AppImages.userIcon,
                        width: 14,
                        height: 14,
                        color: AppColors.navbar,
                      ),
                      SizedBox(width: 5),
                      Text.rich(
                        TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                              text: '${widget.activeStudents}',
                              style: TextStyle(
                                color: AppColors.greyColor,
                                fontSize: FontSize.scale(context, 14),
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                                fontFamily: "SF-Pro-Text",
                              ),
                            ),
                            TextSpan(
                              text: ' Estudiantes activos',
                              style: TextStyle(
                                color: AppColors.blackColor,
                                fontSize: FontSize.scale(context, 14),
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                                fontFamily: "SF-Pro-Text",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Row(
                    children: [
                      SvgPicture.asset(
                        AppImages.sessions,
                        width: 14,
                        height: 14,
                        color: AppColors.navbar,
                      ),
                      SizedBox(width: 5),
                      Text.rich(
                        TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                              text: '${widget.sessions} ',
                              style: TextStyle(
                                color: AppColors.greyColor,
                                fontSize: FontSize.scale(context, 14),
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                                fontFamily: "SF-Pro-Text",
                              ),
                            ),
                            TextSpan(
                              text: 'Sesiones',
                              style: TextStyle(
                                color: AppColors.greyColor.withOpacity(0.7),
                                fontSize: FontSize.scale(context, 14),
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                                fontFamily: "SF-Pro-Text",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  SvgPicture.asset(
                    AppImages.language,
                    width: 14,
                    height: 14,
                    color: AppColors.navbar,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          if (widget.languagesText)
                            TextSpan(
                              text: 'Idiomas: ',
                              style: TextStyle(
                                color: AppColors.greyColor,
                                fontSize: FontSize.scale(context, 14),
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.normal,
                                fontFamily: "SF-Pro-Text",
                              ),
                            ),
                          TextSpan(
                            text: displayLanguages,
                            style: TextStyle(
                              color: AppColors.greyColor.withOpacity(0.7),
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                              fontFamily: "SF-Pro-Text",
                            ),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
