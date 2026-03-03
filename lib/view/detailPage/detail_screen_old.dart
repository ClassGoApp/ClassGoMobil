import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/provider/connectivity_provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/components/internet_alert.dart';
import 'package:flutter_projects/view/components/login_required_alert.dart';
import 'package:flutter_projects/view/detailPage/component/skeleton/detail_page_skeleton.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import '../../provider/auth_provider.dart';
import '../bookSession/book_session.dart';
import '../components/certification_card.dart';
import '../components/education_card.dart';
import '../components/experience_card.dart';
import '../components/student_card.dart';
import '../student/student_reviews.dart';
import 'package:chewie/chewie.dart';
import '../tutor/tutor_profile_screen.dart';

class TutorDetailScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  final Map<String, dynamic> tutor;
  TutorDetailScreen({required this.profile, required this.tutor});

  @override
  _TutorDetailScreenState createState() => _TutorDetailScreenState();
}

class _TutorDetailScreenState extends State<TutorDetailScreen> {
  late double screenHeight;
  int selectedIndex = 0;
  bool isLoading = false;
  late double screenWidth;
  List<DateTime> dateList = [];
  List<String> dayList = [];
  ScrollController _scrollController = ScrollController();
  Map<String, dynamic> sessionData = {};
  ChewieController? _chewieController;
  bool _isBuffering = true;
  late VideoPlayerController _videoController;

  Map<String, dynamic>? tutorDetails;
  String? videoUrl;
  Map<String, dynamic>? studentReviews;
  int currentPage = 1;

  bool isExpanded = false;

  void _initializeChewie(String videoUrl) async {
    _videoController = VideoPlayerController.network(videoUrl);
    await _videoController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.primaryGreen,
        handleColor: AppColors.whiteColor,
        backgroundColor: AppColors.greyColor,
      ),
      showControls: true,
      showControlsOnInitialize: true,
    );

    setState(() {
      _isBuffering = false;
    });
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildVideoSection() {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: AspectRatio(
        aspectRatio: _chewieController != null &&
                _chewieController!.videoPlayerController.value.isInitialized
            ? _chewieController!.videoPlayerController.value.aspectRatio
            : 16 / 9,
        child: _isBuffering
            ? _buildShimmerPlaceholder()
            : Chewie(controller: _chewieController!),
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Map<String, dynamic>? tutorEducation;

  Future<void> fetchTutorDetails(String slug) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final fetchedDetails = await getTutors(token, slug);
      setState(() {
        tutorDetails = fetchedDetails;
        videoUrl = fetchedDetails['data']['profile']['intro_video'];

        if (videoUrl != null && videoUrl!.isNotEmpty) {
          _initializeChewie(videoUrl!);
        }
      });
    } catch (e) {}
  }

  Future<void> fetchTutorEducation(int tutorId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final fetchedEducation = await getTutorsEducation(token, tutorId);
      setState(() {
        tutorEducation = fetchedEducation;
      });
    } catch (e) {}
  }

  Future<void> fetchTutorExperience(int tutorId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final fetchedExperience = await getTutorsExperience(token, tutorId);
      setState(() {
        tutorExperience = fetchedExperience;
      });
    } catch (e) {}
  }

  Future<void> fetchTutorCertification(int tutorId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final fetchedCertification = await getTutorsCertification(token, tutorId);
      setState(() {
        tutorCertification = fetchedCertification;
      });
    } catch (e) {}
  }

  Future<void> _fetchTutorAvailableSlots(int tutorId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    try {
      setState(() {
        isLoading = true;
      });

      final response = await getTutorAvailableSlots(token!, tutorId.toString());
      print(response);

      DateTime startDate = DateTime.now();
      DateTime endDate = startDate.add(Duration(days: 10));
      _generateDateAndDayList(startDate, endDate);

      Map<String, dynamic> formattedSessionData = {};

      response.forEach((groupName, subjects) {
        subjects.forEach((subjectName, subjectData) {
          List<dynamic> slots = subjectData["slots"];

          for (var slot in slots) {
            DateTime slotDate = DateTime.parse(slot["start_time"].trim());
            String formattedDate = DateFormat('dd MMM yyyy').format(slotDate);

            if (!formattedSessionData.containsKey(formattedDate)) {
              formattedSessionData[formattedDate] = [];
            }

            // Extraer datos correctamente
            formattedSessionData[formattedDate].add({
              "id": slot["id"],
              "start_time": slot["start_time"].trim(),
              "end_time": slot["end_time"],
              "spaces": slot["spaces"],
              "session_fee": slot["session_fee"],
              "total_booked": slot["total_booked"],
              "description": slot["description"] ?? "Sin descripción",
              "students": slot["students"],
              "formatted_time_range":
                  "${DateFormat('hh:mm a').format(DateTime.parse(slot["start_time"].trim()))} - ${DateFormat('hh:mm a').format(DateTime.parse(slot["end_time"].trim()))}",
              "subject": subjectData["info"]["subject"],
              "group": groupName,
            });
          }
        });
      });

      setState(() {
        sessionData = formattedSessionData;
      });

      // Buscar la primera fecha con sesiones disponibles
      int firstAvailableIndex = -1;
      DateTime? firstAvailableDate;

      for (int i = 0; i < dateList.length; i++) {
        String dateKey = DateFormat('dd MMM yyyy').format(dateList[i]);
        if (sessionData.containsKey(dateKey)) {
          firstAvailableIndex = i;
          firstAvailableDate = dateList[i];
          break;
        }
      }

      if (firstAvailableIndex != -1 && firstAvailableDate != null) {
        setState(() {
          selectedIndex = firstAvailableIndex;
        });
        await _fetchSessionsForSelectedDate(firstAvailableDate);
      }
    } catch (e) {
      print("Error fetching tutor available slots: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchSessionsForSelectedDate(DateTime date) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    try {
      setState(() {
        isLoading = true;
      });

      final response =
          await getTutorAvailableSlots(token!, widget.tutor['id'].toString());

      setState(() {
        sessionData = response['data'];
      });
    } catch (e) {
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _generateDateAndDayList(DateTime startDate, DateTime endDate) {
    List<DateTime> dates = [];
    List<String> days = [];

    for (var date = startDate;
        date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        date = date.add(Duration(days: 1))) {
      dates.add(date);
      days.add(DateFormat('EEE').format(date));
    }

    setState(() {
      dateList = dates;
      dayList = days;
    });
  }

  Future<void> fetchStudentReviews(int tutorId, {int page = 1}) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final fetchedReviews =
          await getStudentReviews(token, tutorId, page: page);

      setState(() {
        studentReviews = fetchedReviews;
      });
    } catch (e) {}
  }

  Map<String, dynamic>? tutorExperience;

  Map<String, dynamic>? tutorCertification;

  @override
  void initState() {
    super.initState();
    fetchTutorDetails(widget.profile['slug']);
    _fetchTutorAvailableSlots(widget.tutor['id']);
    fetchTutorEducation(widget.profile['id']);
    //
    // fetchTutorExperience(widget.profile['id']);
    //
    // fetchTutorCertification(widget.profile['id']);

    fetchStudentReviews(widget.profile['id'], page: currentPage);
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
                        Navigator.of(context).pop();
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

  Widget _buildAboutMeSection(Map<String, dynamic> tutorDetails) {
    if (tutorDetails['data']['profile']['description'] == null) {
      return AboutMeSectionSkeleton();
    }

    final description = tutorDetails['data']['profile']['description'] ??
        'No description available.';
    final words = description.split(RegExp(r'\s+'));
    final isExpanded = ValueNotifier<bool>(false);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
        color: AppColors.whiteColor,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sobre mí',
                style: TextStyle(
                  color: AppColors.navbar,
                  fontSize: FontSize.scale(context, 18),
                  fontWeight: FontWeight.w600,
                  fontFamily: "SF-Pro-Text",
                ),
              ),
              SizedBox(height: 10.0),
              ValueListenableBuilder<bool>(
                valueListenable: isExpanded,
                builder: (context, expanded, child) {
                  String displayedText;
                  bool showSeeMore = words.length > 20;

                  if (expanded || !showSeeMore) {
                    displayedText = description;
                  } else {
                    displayedText =
                        description.split(' ').take(20).join(' ') + '... ';
                  }

                  return RichText(
                    text: TextSpan(
                      children: [
                        WidgetSpan(
                          child: HtmlWidget(
                            displayedText,
                            textStyle: TextStyle(
                              color: AppColors.greyColor,
                              fontSize: FontSize.scale(context, 15),
                              fontWeight: FontWeight.w400,
                              fontFamily: "SF-Pro-Text",
                            ),
                          ),
                        ),
                        if (showSeeMore)
                          TextSpan(
                            text: expanded ? ' Ver más ' : ' Ver menos',
                            style: TextStyle(
                              color: AppColors.blackColor,
                              fontSize: FontSize.scale(context, 15),
                              fontWeight: FontWeight.w600,
                              fontFamily: "SF-Pro-Text",
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                isExpanded.value = !expanded;
                              },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEducationSection(List<Map<String, dynamic>> educationData) {
    if (educationData.isEmpty) {
      return Container();
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Education',
              style: TextStyle(
                color: AppColors.blackColor,
                fontSize: FontSize.scale(context, 18),
                fontWeight: FontWeight.w600,
                fontFamily: "SF-Pro-Text",
              ),
            ),
            SizedBox(height: 10),
            ...educationData.asMap().entries.map((entry) {
              final index = entry.key;
              final education = entry.value;
              final showDivider = index < educationData.length - 1;

              final startDate = education['start_date'];
              final endDate =
                  education['ongoing'] == 1 ? 'Current' : education['end_date'];

              return EducationCard(
                position: education['course_title'],
                institute: education['institute_name'],
                location:
                    '${education['city']}, ${education['country']['name']}',
                duration: '$startDate - $endDate',
                description: education['description'],
                showDivider: showDivider,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceSection(List<Map<String, dynamic>> experienceData) {
    if (experienceData.isEmpty) {
      return ExperienceSectionSkeleton();
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Experience',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: AppColors.blackColor,
                fontSize: FontSize.scale(context, 18),
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.normal,
                fontFamily: "SF-Pro-Text",
              ),
            ),
            SizedBox(height: 10),
            ...experienceData.map((experience) {
              final String position =
                  experience['title']?.toString() ?? 'Unknown Title';
              final String institute =
                  experience['company']?.toString() ?? 'Unknown Institute';
              final String employmentType =
                  experience['employment_type']?.toString() ?? 'Unknown Type';
              final String location =
                  experience['location']?.toString() ?? 'Unknown Location';
              final String startDate =
                  experience['start_date']?.toString() ?? 'Unknown Start Date';
              final String endDate =
                  experience['end_date']?.toString() ?? 'Unknown End Date';
              final String description =
                  experience['description']?.toString() ??
                      'No Description Available';

              return ExperienceCard(
                position: position,
                institute: institute,
                employmentType: employmentType,
                location: location,
                duration: "$startDate - $endDate",
                description: description,
                showDivider: experience != experienceData.last,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationSection(
      List<Map<String, dynamic>> certificationData) {
    if (certificationData.isEmpty) {
      return CertificationSectionSkeleton();
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Certification',
              style: TextStyle(
                color: AppColors.blackColor,
                fontSize: FontSize.scale(context, 18),
                fontWeight: FontWeight.w600,
                fontFamily: "SF-Pro-Text",
              ),
            ),
            SizedBox(height: 10),
            ...certificationData.map((certification) {
              return CertificateCard(
                imagePath: certification['image'] ?? "",
                position: certification['title'],
                institute: certification['institute_name'],
                issued: "Issued: ${certification['issue_date']}",
                duration: "Expiry: ${certification['expiry_date']}",
                description: certification['description'],
                showDivider: certification != certificationData.last,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // Widget _buildStudentReviewsSection() {
  //   if (studentReviews == null || studentReviews!['data']['list'] == null) {
  //     return StudentReviewsSectionSkeleton();
  //   }
  //   return Padding(
  //     padding: const EdgeInsets.all(8.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text(
  //               'Student Reviews',
  //               style: TextStyle(
  //                 color: AppColors.blackColor,
  //                 fontSize: FontSize.scale(context, 16),
  //                 fontWeight: FontWeight.w600,
  //                 fontStyle: FontStyle.normal,
  //                 fontFamily: "SF-Pro-Text",
  //               ),
  //             ),
  //             Padding(
  //               padding: const EdgeInsets.only(right: 8.0),
  //               child: TextButton(
  //                 onPressed: () {
  //                   final authProvider =
  //                       Provider.of<AuthProvider>(context, listen: false);
  //                   final token = authProvider.token;
  //
  //                   Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                       builder: (context) => StudentReviewsScreen(
  //                         initialPage: 1,
  //                         fetchReviews: (page) async {
  //                           return await getStudentReviews(
  //                             token,
  //                             widget.profile['id'],
  //                             page: page,
  //                           );
  //                         },
  //                       ),
  //                     ),
  //                   );
  //                 },
  //                 child: Text(
  //                   'Explore all',
  //                   style: TextStyle(
  //                     color: AppColors.greyColor,
  //                     fontSize: FontSize.scale(context, 14),
  //                     fontWeight: FontWeight.w400,
  //                     fontStyle: FontStyle.normal,
  //                     fontFamily: "SF-Pro-Text",
  //                   ),
  //                 ),
  //               ),
  //             )
  //           ],
  //         ),
  //         SizedBox(height: 10),
  //         SingleChildScrollView(
  //           scrollDirection: Axis.horizontal,
  //           child: Row(
  //             children: List.generate(
  //               studentReviews != null
  //                   ? studentReviews!['data']['list'].length
  //                   : 0,
  //               (index) {
  //                 final review = studentReviews!['data']['list'][index];
  //                 final profile = review['profile'];
  //                 final country = review['country'];
  //
  //                 return ConstrainedBox(
  //                   constraints: BoxConstraints(minWidth: 150),
  //                   child: IntrinsicHeight(
  //                     child: StudentCard(
  //                       name: profile['short_name'],
  //                       date: review['created_at'],
  //                       description: review['comment'],
  //                       rating: review['rating'].toDouble(),
  //                       image: profile['image'],
  //                     ),
  //                   ),
  //                 );
  //               },
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildBottomButton() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    return ElevatedButton(
      onPressed: () {
        if (token == null) {
          _showLoginRequiredDialog();
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TutorProfileScreen(
                tutorId:
                    tutorDetails?['data']?['profile']?['id']?.toString() ?? '',
                tutorName:
                    tutorDetails?['data']?['profile']?['full_name'] ?? '',
                tutorImage: tutorDetails?['data']?['profile']?['image'] ?? '',
                tutorVideo:
                    tutorDetails?['data']?['profile']?['intro_video'] ?? '',
                description:
                    tutorDetails?['data']?['profile']?['description'] ?? '',
                rating: tutorDetails?['data']?['avg_rating'] is num
                    ? (tutorDetails?['data']?['avg_rating'] as num).toDouble()
                    : double.tryParse(
                            '${tutorDetails?['data']?['avg_rating'] ?? 0.0}') ??
                        0.0,
                subjects: (tutorDetails?['data']?['profile']?['subjects']
                            as List<dynamic>?)
                        ?.map((e) => e['name']?.toString() ?? '')
                        .toList() ??
                    [],
                completedCourses: int.tryParse(
                        '${tutorDetails?['data']?['profile']?['completed_courses_count'] ?? 0}') ??
                    0,
              ),
            ),
          );
        }
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.orangeprimary;
          }
          return AppColors.orangeprimary;
        }),
        padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(vertical: 12, horizontal: 16)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Solicitar una sesión',
            style: TextStyle(
              color: AppColors.whiteColor,
              fontSize: FontSize.scale(context, 16),
              fontFamily: 'SF-Pro-Text',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: "Es necesario el Logeo!",
          content: "Necesitas estar logeado para ingresar",
          buttonText: "Ir al Login",
          buttonAction: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          },
        );
      },
    );
  }
}
