import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/view/home/home_screen.dart';
import 'package:flutter_projects/provider/connectivity_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/components/internet_alert.dart';
import 'package:flutter_projects/view/components/education_card.dart';
import 'package:flutter_projects/view/components/experience_card.dart';
import 'package:flutter_projects/view/components/certification_card.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_projects/view/student/student_reviews.dart';
import 'package:flutter_projects/view/detailPage/component/skeleton/detail_page_skeleton.dart';
// import 'package:flutter_projects/view/detailPage/widgets/tutor_video_section.dart';
// import 'package:flutter_projects/view/detailPage/widgets/tutor_info_section.dart';
import 'package:flutter_projects/view/detailPage/component/html_description.dart';
import 'package:flutter_projects/view/bookSession/book_session.dart';
import 'package:flutter_projects/api_structure/api_service.dart' as api;
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';

class TutorDetailScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  final Map<String, dynamic> tutor;

  const TutorDetailScreen({
    Key? key,
    required this.profile,
    required this.tutor,
  }) : super(key: key);

  @override
  State<TutorDetailScreen> createState() => _TutorDetailScreenState();
}

class _TutorDetailScreenState extends State<TutorDetailScreen> {
  Map<String, dynamic>? tutorDetails;
  Map<String, dynamic>? tutorEducation;
  Map<String, dynamic>? tutorExperience;
  Map<String, dynamic>? tutorCertification;
  Map<String, dynamic>? studentReviews;
  bool isLoading = true;
  String? error;
  late double screenHeight;
  late double screenWidth;
  List<DateTime> dateList = [];
  List<String> dayList = [];
  int selectedIndex = 0;
  ScrollController _scrollController = ScrollController();
  bool isExpanded = false;
  bool _isBuffering = true;

  @override
  void initState() {
    super.initState();
    _fetchTutorDetails();
  }

  Future<void> _fetchTutorDetails() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final slug = widget.tutor['slug'] ?? '';

      final fetchedDetails = await api.getTutors(token, slug);

      setState(() {
        tutorDetails = fetchedDetails;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _onBookSession() {
    if (tutorDetails == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookSessionScreen(
          tutorProfile: widget.profile,
          tutor: widget.tutor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    List<dynamic> reviews = studentReviews?["data"]["list"] ?? [];
    Map<int, int> ratingCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var review in reviews) {
      int rating = review["rating"];
      ratingCounts[rating] = ratingCounts[rating]! + 1;
    }
    int totalRatings = reviews.length;
    double averageRating = totalRatings > 0
        ? reviews.map((r) => r["rating"]).reduce((a, b) => a + b) / totalRatings
        : 0;

    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, _) {
        if (!connectivityProvider.isConnected) {
          return Scaffold(
            backgroundColor: AppColors.backgroundColor,
            body: Center(
              child: InternetAlertDialog(
                onRetry: () async {
                  await connectivityProvider.checkInitialConnection();
                },
              ),
            ),
          );
        }

        return WillPopScope(
          onWillPop: () async {
            return !_isBuffering;
          },
          child: Scaffold(
              backgroundColor: AppColors.primaryGreen,
              appBar: AppBar(
                forceMaterialTransparency: true,
                backgroundColor: AppColors.dividerColor,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 10.0, bottom: 10.0),
                  child: Container(
                    width: 50.0,
                    height: 50.0,
                    padding: EdgeInsets.only(left: 10.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      splashColor: Colors.transparent,
                      icon: Icon(Icons.arrow_back_ios,
                          color: AppColors.whiteColor, size: 20),
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => HomeScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                ),
              ),
              body: tutorDetails != null
                  ? SafeArea(
                      bottom: Theme.of(context).platform == TargetPlatform.iOS
                          ? false
                          : true,
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildVideoSection(),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    _buildProfileSection(tutorDetails!),
                                    SizedBox(height: 10.0),
                                    _buildAboutMeSection(tutorDetails!),

                                    SizedBox(height: 10.0),
                                    if (tutorEducation != null)
                                      _buildEducationSection(
                                          List<Map<String, dynamic>>.from(
                                              tutorEducation!['data'] ?? '')),
                                    SizedBox(height: 10.0),
                                    if (tutorExperience != null)
                                      _buildExperienceSection(
                                          List<Map<String, dynamic>>.from(
                                              tutorExperience!['data'] ?? '')),
                                    SizedBox(height: 10.0),
                                    if (tutorCertification != null)
                                      _buildCertificationSection(
                                          List<Map<String, dynamic>>.from(
                                              tutorCertification!['data'] ??
                                                  '')),
                                    Text(
                                      'Reservar Sesión',
                                      style: TextStyle(
                                        color: AppColors.whiteColor,
                                        fontSize: FontSize.scale(context, 20),
                                        fontFamily: 'SF-Pro-Text',
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FontStyle.normal,
                                      ),
                                    ),
                                    _buildDateSelector(),
                                    _buildBottomButton(),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      "Reseñas de estudiantes",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        final authProvider =
                                            Provider.of<AuthProvider>(context,
                                                listen: false);
                                        final token = authProvider.token;

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                StudentReviewsScreen(
                                              initialPage: 1,
                                              fetchReviews: (page) async {
                                                return await getStudentReviews(
                                                  token,
                                                  widget.profile['id'],
                                                  page: page,
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                      child: Center(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: AppColors.blurprimary,
                                            border: Border.all(
                                                color: Colors.white,
                                                width: 0.5),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    averageRating
                                                        .toStringAsFixed(1),
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 32,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  SizedBox(width: 8),
                                                  RatingBarIndicator(
                                                    rating: averageRating,
                                                    itemCount: 5,
                                                    itemSize: 24.0,
                                                    itemBuilder: (context, _) =>
                                                        Icon(Icons.star,
                                                            color:
                                                                Colors.amber),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                "Residencia en $totalRatings calificaciones",
                                                style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 14),
                                              ),
                                              SizedBox(height: 16),
                                              Column(
                                                children:
                                                    [5, 4, 3, 2, 1].map((star) {
                                                  double percentage =
                                                      totalRatings > 0
                                                          ? (ratingCounts[
                                                                      star]! /
                                                                  totalRatings) *
                                                              100
                                                          : 0;
                                                  return Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text("$star.0",
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white)),
                                                      SizedBox(
                                                        width: 20,
                                                      ),
                                                      Expanded(
                                                        child:
                                                            LinearProgressIndicator(
                                                          value:
                                                              percentage / 100,
                                                          backgroundColor:
                                                              Colors.white24,
                                                          color: Colors.amber,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 20,
                                                      ),
                                                      Text(
                                                          " ${ratingCounts[star]}",
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white)),
                                                    ],
                                                  );
                                                }).toList(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // SizedBox(height: 16.0),
                                    // if (studentReviews != null &&
                                    //     studentReviews!['data'] != null &&
                                    //     studentReviews!['data']['list'] != null &&
                                    //     studentReviews!['data']['list']
                                    //         .isNotEmpty)
                                    //   _buildStudentReviewsSection(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // tutorDetails != null
                          //     ? _buildBottomButton()
                          //     : BottomButtonSkeleton(),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                VideoSectionSkeleton(),
                                ProfileSectionSkeleton(),
                                SizedBox(height: 10),
                                AboutMeSectionSkeleton(),
                                SizedBox(height: 10),
                                EducationSectionSkeleton(),
                                SizedBox(height: 10),
                                ExperienceSectionSkeleton(),
                                SizedBox(height: 10),
                                CertificationSectionSkeleton(),
                                SizedBox(height: 10),
                                StudentReviewsSectionSkeleton(),
                                SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                        BottomButtonSkeleton(),
                      ],
                    )),
        );
      },
    );
  }

  Widget _buildDateSelector() {
    if (dateList.isEmpty || dayList.isEmpty) {
      return Container(
        height: 80,
        child: Center(
          child: Text('No dates available'),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final offset = selectedIndex * 100.0;
        final maxScrollExtent = _scrollController.position.maxScrollExtent;
        if (offset <= maxScrollExtent) {
          _scrollController.jumpTo(offset);
        } else {
          _scrollController.jumpTo(maxScrollExtent);
        }
      }
    });

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
      ),
      child: ListView.builder(
        key: PageStorageKey('dateListKey'),
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: dateList.length,
        itemBuilder: (context, index) {
          bool isSelected = selectedIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedIndex = index;
              });
              _fetchSessionsForSelectedDate(dateList[index]);
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.navbar.withOpacity(0.8)
                      : AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                child: Column(
                  children: [
                    Text(
                      DateFormat('dd MMM').format(dateList[index]),
                      style: TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: FontSize.scale(context, 17),
                        fontFamily: 'SF-Pro-Text',
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      dayList[index],
                      style: TextStyle(
                        color: AppColors.whiteColor,
                        fontSize: FontSize.scale(context, 16),
                        fontFamily: 'SF-Pro-Text',
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileSection(Map<String, dynamic> tutorDetails) {
    final profile = tutorDetails['data']['profile'];
    final fullName = profile['full_name'];
    final imageUrl = profile['image'];
    final minPrice = tutorDetails['data']['min_price'];
    final sessions = tutorDetails['data']['sessions'];
    final activeStudents = tutorDetails['data']['active_students'];
    final totalReviews = tutorDetails['data']['total_reviews'];
    final languages = tutorDetails['data']['languages'];
    final subjects = tutorDetails['data']['subjects'];
    final online = tutorDetails['data']['is_online'];
    final country = tutorDetails['data']['country'] ?? {};
    final countryShortCode = country['short_code'] ?? 'default';
    final active = tutorDetails['data']['email_verified_at'] ?? {};
    final rating = tutorDetails['data']['avg_rating'];
    final formattedRating = (rating != null)
        ? double.parse(rating.toString()).toStringAsFixed(1)
        : '0.0';
    final countryFlagUrl =
        'https://flagcdn.com/w20/${countryShortCode.toLowerCase()}.png';

    int visibleSubjectsCount = isExpanded ? subjects.length : 2;
    int remainingSubjectsCount = subjects.length - visibleSubjectsCount;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String profileImageUrl =
        authProvider.userData?['user']['profile']['image'] ?? '';

    Widget displayProfileImage() {
      Widget _buildShimmerSkeleton() {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }

      Widget buildImage(String url) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isLoading = true;

            return Stack(
              children: [
                if (isLoading) _buildShimmerSkeleton(),
                Image.network(
                  url,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      Future.microtask(() => setState(() => isLoading = false));
                      return child;
                    }
                    return const SizedBox();
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return SvgPicture.asset(
                      AppImages.placeHolder,
                      fit: BoxFit.cover,
                      width: 60,
                      height: 60,
                      color: AppColors.greyColor,
                    );
                  },
                ),
              ],
            );
          },
        );
      }

      if (imageUrl.isNotEmpty) {
        return buildImage(imageUrl);
      } else if (profileImageUrl.isNotEmpty) {
        return buildImage(profileImageUrl);
      } else {
        return SvgPicture.asset(
          AppImages.placeHolder,
          fit: BoxFit.cover,
          width: 60,
          height: 60,
          color: AppColors.greyColor,
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20,
            ),
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: displayProfileImage(),
                    ),
                    Positioned(
                      bottom: -10,
                      left: 22,
                      child: online == true
                          ? Image.asset(
                              AppImages.onlineIndicator,
                              width: 16,
                              height: 16,
                            )
                          : Container(),
                    ),
                  ],
                ),
                SizedBox(width: 10.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          fullName,
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                            color: AppColors.navbar,
                            fontSize: FontSize.scale(context, 18),
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.normal,
                            fontFamily: "SF-Pro-Text",
                          ),
                        ),
                        active != null
                            ? Icon(Icons.verified,
                                size: 16, color: AppColors.navbar)
                            : SizedBox(width: 10),
                      ],
                    ),
                    SizedBox(height: 4),
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
                            text: '\$$minPrice',
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
              '${subjects.take(3).map((sub) => sub['name']).join(" , ")}',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: AppColors.blackColor,
                fontSize: FontSize.scale(context, 14),
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.normal,
                fontFamily: "SF-Pro-Text",
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                SvgPicture.asset(
                  formattedRating == '5.0'
                      ? AppImages.filledStar
                      : AppImages.star,
                  color: AppColors.navbar,
                  width: 16,
                  height: 16,
                ),
                SizedBox(width: 5),
                Text.rich(
                  TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                        text: formattedRating,
                        style: TextStyle(
                          color: AppColors.greyColor,
                          fontSize: FontSize.scale(context, 14),
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                          fontFamily: "SF-Pro-Text",
                        ),
                      ),
                      TextSpan(
                        text: '/5.0 ($totalReviews reseñas)',
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
                        text: '$activeStudents',
                        style: TextStyle(
                          color: AppColors.greyColor,
                          fontSize: FontSize.scale(context, 14),
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                          fontFamily: "SF-Pro-Text",
                        ),
                      ),
                      TextSpan(
                        text: ' Estudiantes Activos',
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
                SvgPicture.asset(
                  AppImages.sessions,
                  width: 14,
                  height: 14,
                  color: AppColors.navbar,
                ),
                SizedBox(width: 8),
                Text.rich(
                  TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                        text: '$sessions ',
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
            SizedBox(height: 10),
            Row(
              children: [
                SvgPicture.asset(
                  AppImages.bookEducationIcon,
                  color: AppColors.navbar,
                  width: 14,
                  height: 14,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Enseño ',
                          style: TextStyle(
                            color: AppColors.greyColor,
                            fontSize: FontSize.scale(context, 14),
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.normal,
                            fontFamily: "SF-Pro-Text",
                          ),
                        ),
                        if (subjects != null && subjects!.isNotEmpty)
                          for (int i = 0;
                              i < subjects!.length && i < visibleSubjectsCount;
                              i++)
                            TextSpan(
                              text:
                                  '${subjects![i]['name']}${i < visibleSubjectsCount - 1 ? ', ' : ''} ',
                              style: TextStyle(
                                color: AppColors.greyColor.withOpacity(0.7),
                                fontSize: FontSize.scale(context, 14),
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                                fontFamily: "SF-Pro-Text",
                              ),
                            ),
                        if (subjects.length > 2)
                          TextSpan(
                            text: '  ',
                            style: TextStyle(
                              fontSize: FontSize.scale(context, 14),
                            ),
                          ),
                        if (subjects.length > 2)
                          TextSpan(
                            text: isExpanded
                                ? 'show less'
                                : '+$remainingSubjectsCount show more',
                            style: TextStyle(
                              color: AppColors.greyColor.withOpacity(0.9),
                              fontSize: FontSize.scale(context, 14),
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.normal,
                              fontFamily: "SF-Pro-Text",
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                setState(() {
                                  isExpanded = !isExpanded;
                                });
                              },
                          ),
                      ],
                    ),
                  ),
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
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Idiomas',
                          style: TextStyle(
                            color: AppColors.greyColor,
                            fontSize: FontSize.scale(context, 14),
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.normal,
                            fontFamily: "SF-Pro-Text",
                          ),
                        ),
                        TextSpan(
                          text:
                              ' ${languages.map((lang) => lang['name']).join(", ")}',
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
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (tutorDetails == null) return _buildErrorWidget();

    final data = tutorDetails!['data'] ?? {};
    final profile = data['profile'] ?? {};
    final videoUrl = profile['intro_video'];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección de video - Temporalmente deshabilitada
          // TutorVideoSection(
          //   videoUrl: videoUrl,
          //   isLoading: isLoading,
          // ),

          // Sección de información del tutor - Temporalmente deshabilitada
          // TutorInfoSection(
          //   tutorDetails: data,
          //   onBookSession: _onBookSession,
          // ),

          SizedBox(height: 16),

          // Sección de descripción
          if (profile['description'] != null &&
              profile['description'].isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sobre mí',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blackColor,
                    ),
                  ),
                  SizedBox(height: 12),
                  AboutMeSection(
                    description: profile['description'],
                  ),
                ],
              ),
            ),

          SizedBox(height: 100), // Espacio para el bottom bar
        ],
      ),
    );
  }

  Widget _buildVideoSection() {
    return Container(
      height: 200,
      color: Colors.black,
      child: Center(
        child: Icon(Icons.play_circle_outline, size: 64, color: Colors.white),
      ),
    );
  }

  Widget _buildAboutMeSection(Map<String, dynamic> tutorDetails) {
    final profile = tutorDetails['data']?['profile'] ?? {};
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sobre mí',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.blackColor,
            ),
          ),
          SizedBox(height: 12),
          Text(
            profile['description'] ?? 'Sin descripción',
            style: TextStyle(color: AppColors.blackColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationSection(List<Map<String, dynamic>> educationData) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Educación',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.blackColor,
            ),
          ),
          SizedBox(height: 12),
          ...educationData.map((edu) => EducationCard(
            position: edu['degree'] ?? '',
            institute: edu['institute'] ?? '',
            location: edu['location'] ?? '',
            duration: edu['duration'] ?? '',
            description: edu['description'] ?? '',
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildExperienceSection(List<Map<String, dynamic>> experienceData) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Experiencia',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.blackColor,
            ),
          ),
          SizedBox(height: 12),
          ...experienceData.map((exp) => ExperienceCard(
            position: exp['position'] ?? '',
            institute: exp['company'] ?? '',
            employmentType: exp['employment_type'] ?? '',
            location: exp['location'] ?? '',
            duration: exp['duration'] ?? '',
            description: exp['description'] ?? '',
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildCertificationSection(List<Map<String, dynamic>> certificationData) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Certificaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.blackColor,
            ),
          ),
          SizedBox(height: 12),
          ...certificationData.map((cert) => CertificateCard(
            imagePath: cert['image'] ?? '',
            position: cert['name'] ?? '',
            institute: cert['organization'] ?? '',
            duration: cert['duration'] ?? '',
            issued: cert['issued_date'] ?? '',
            description: cert['description'] ?? '',
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _onBookSession,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          minimumSize: Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Reservar Sesión',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.whiteColor,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.redColor),
          SizedBox(height: 16),
          Text(
            'Error cargando los detalles del tutor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.whiteColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            error ?? 'Error desconocido',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.greyColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            child: Text('Volver'),
          ),
        ],
      ),
    );
  }

  void _fetchSessionsForSelectedDate(DateTime date) {
    // Implementación pendiente - placeholder
    setState(() {});
  }

  Widget VideoSectionSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 200,
        color: Colors.white,
      ),
    );
  }

  Widget ProfileSectionSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 150,
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget AboutMeSectionSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 100,
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget EducationSectionSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 120,
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget ExperienceSectionSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 120,
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget CertificationSectionSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 120,
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget StudentReviewsSectionSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 200,
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget BottomButtonSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 50,
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
