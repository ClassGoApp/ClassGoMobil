import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/detailPage/component/skeleton/detail_page_skeleton.dart';
import '../components/student_card.dart';

class StudentReviewsScreen extends StatefulWidget {
  final int initialPage;
  final Future<Map<String, dynamic>> Function(int page)? fetchReviews;

  StudentReviewsScreen({
    required this.initialPage,
    this.fetchReviews,
  });

  @override
  _StudentReviewsScreenState createState() => _StudentReviewsScreenState();
}

class _StudentReviewsScreenState extends State<StudentReviewsScreen> {
  List<dynamic> studentReviews = [];
  bool isLoadingMore = false;
  bool isInitialLoading = true;
  bool hasMoreItems = true;
  int currentPage = 1;
  int totalPages = 1;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    currentPage = widget.initialPage;
    _loadInitialReviews();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMoreItems) {
      _fetchMoreReviews();
    }
  }

  Future<void> _loadInitialReviews() async {
    setState(() {
      isInitialLoading = true;
    });

    try {
      if (widget.fetchReviews != null) {
        final response = await widget.fetchReviews!(currentPage);
        setState(() {
          studentReviews = response['data']['list'];
          if (response['data']['pagination'] != null) {
            totalPages = response['data']['pagination']['totalPages'];
            currentPage = response['data']['pagination']['currentPage'];
          }
          isInitialLoading = false;
          hasMoreItems = currentPage < totalPages;
        });
      } else {
        setState(() {
          isInitialLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isInitialLoading = false;
      });
    }
  }

  Future<void> _fetchMoreReviews() async {
    if (isLoadingMore ||
        currentPage >= totalPages ||
        widget.fetchReviews == null) {
      return;
    }

    setState(() {
      isLoadingMore = true;
    });

    try {
      final newReviewsResponse = await widget.fetchReviews!(currentPage + 1);
      setState(() {
        currentPage++;
        studentReviews.addAll(newReviewsResponse['data']['list']);
        hasMoreItems = currentPage < totalPages;
        isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80.0),
        child: Container(
          color: AppColors.primaryGreen,
          child: Padding(
            padding: const EdgeInsets.only(top: 14.0),
            child: AppBar(
              forceMaterialTransparency: true,
              centerTitle: false,
              backgroundColor: AppColors.whiteColor,
              elevation: 0,
              titleSpacing: 0,
              title: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Reviews',
                    style: TextStyle(
                      color: AppColors.whiteColor,
                      fontSize: FontSize.scale(context, 20),
                      fontFamily: 'SF-Pro-Text',
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                  SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      text: '${studentReviews.length} ',
                      style: TextStyle(
                        fontFamily: 'SF-Pro-Text',
                        fontWeight: FontWeight.w600,
                        fontSize: FontSize.scale(context, 13),
                        fontStyle: FontStyle.normal,
                        color: AppColors.whiteColor,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: 'result(s) found',
                          style: TextStyle(
                            fontFamily: 'SF-Pro-Text',
                            fontWeight: FontWeight.w400,
                            fontSize: FontSize.scale(context, 13),
                            fontStyle: FontStyle.normal,
                            color: AppColors.whiteColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              leading: Padding(
                padding: const EdgeInsets.only(top: 3.0),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.arrow_back_ios,
                      size: 20, color: AppColors.whiteColor),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      body: isInitialLoading
          ? StudentReviewsSectionSkeleton(isFullWidth: true)
          : widget.fetchReviews == null
              ? Center(
                  child: Text(
                    "No reviews available",
                    style: TextStyle(
                      color: AppColors.greyColor,
                      fontSize: FontSize.scale(context, 16),
                      fontFamily: 'SF-Pro-Text',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(top: 5),
                  controller: _scrollController,
                  itemCount: studentReviews.length + (isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == studentReviews.length && isLoadingMore) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      );
                    }

                    final review = studentReviews[index];
                    final profile = review['profile'];
                    final country = review['country'];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0,horizontal: 10),
                      child: StudentCard(
                        name: profile['short_name'],
                        date: review['created_at'],
                        description: review['comment'],
                        rating: review['rating'].toDouble(),
                        image: profile['image'],
                        isFullWidth: true,
                      ),
                    );
                  },
                ),
    );
  }
}
