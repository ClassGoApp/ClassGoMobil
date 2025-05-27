import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_dropdown.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/bookings/bookings.dart';
import 'package:flutter_projects/view/components/login_required_alert.dart';
import 'package:flutter_projects/view/components/skeleton/tutor_card_skeleton.dart';
import 'package:flutter_projects/view/components/tutor_card.dart';
import 'package:flutter_projects/view/detailPage/detail_screen.dart';
import 'package:flutter_projects/view/profile/profile_screen.dart';
import 'package:flutter_projects/view/tutor/component/filter_turtor_bottom_sheet.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';

class SearchTutorsScreen extends StatefulWidget {
  @override
  State<SearchTutorsScreen> createState() => _SearchTutorsScreenState();
}

class _SearchTutorsScreenState extends State<SearchTutorsScreen> {
  List<Map<String, dynamic>> tutors = [];
  int currentPage = 1;
  int totalPages = 1;
  int totalTutors = 0;
  bool isLoading = false;
  bool isInitialLoading = false;
  bool isRefreshing = false;

  late double screenWidth;
  late double screenHeight;
  List<String> selectedLanguages = [];
  List<String> selectedSubjects = [];
  List<String> subjectGroups = [];
  String? selectedSubjectGroup;

  List<String> subjects = [];

  List<String> languages = [];

  List<Map<String, dynamic>> countries = [];
  int? selectedCountryId;
  String? selectedCountryName;

  int selectedIndex = 0;
  late PageController _pageController;
  String profileImageUrl = '';

  String? _selectedSorting;
  String? sortingValue;
  String? sortBy;

  String? keyword;
  double? maxPrice;
  int? selectedGroupId;
  String? sessionType = 'group';
  List<int>? selectedSubjectIds;
  List<int>? selectedLanguageIds;

  final List<String> sortingOptions = [
    'Más recientes',
    'Más antiguos',
    'Orden de la A-Z',
    'Orden de la Z-A',
  ];

  final Map<String, String> sortingMap = {
    'Más recientes': 'newest',
    'Más antiguos': 'oldest',
    'Orden de la A-Z': 'asc',
    'Orden de la Z-A': 'desc',
  };

  void _onSortSelected(String value) {
    setState(() {
      _selectedSorting = value;
      sortBy = sortingMap[value];
    });
    fetchInitialTutors(sortBy: sortBy);
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    fetchInitialTutors();
    fetchSubjects();
    fetchLanguages();
    fetchSubjectGroups();
    fetchCountries();

    _pageController = PageController(initialPage: selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData;
    profileImageUrl = userData?['user']?['profile']?['image'] ?? '';
    precacheImage(NetworkImage(profileImageUrl), context);
  }

  Future<void> fetchSubjects() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getSubjects(token);

      if (response.containsKey('data') && response['data'] is List) {
        setState(() {
          subjects = (response['data'] as List<dynamic>)
              .map((subject) => subject['name'].toString())
              .toList();
        });
      }
    } catch (error) {}
  }

  Future<void> fetchCountries() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getCountries(token);
      final countriesData = response['data'];

      setState(() {
        countries = countriesData.map<Map<String, dynamic>>((country) {
          return {
            'id': country['id'],
            'name': country['name'],
          };
        }).toList();
      });
    } catch (e) {}
  }

  Future<void> fetchLanguages() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getLanguages(token);

      if (response.containsKey('data') && response['data'] is List) {
        setState(() {
          languages = (response['data'] as List<dynamic>)
              .map((language) => language['name'].toString())
              .toList();
        });
      }
    } catch (error) {}
  }

  Future<void> fetchSubjectGroups() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getSubjectsGroup(token);

      if (response.containsKey('data') && response['data'] is List) {
        setState(() {
          subjectGroups = (response['data'] as List<dynamic>)
              .map((group) => group['name'].toString())
              .toList();
        });
      }
    } catch (error) {}
  }

  bool get isAuthenticated {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.token != null;
  }

  Future<void> fetchInitialTutors({
    String? sortBy,
    String? keyword,
    double? maxPrice,
    int? country,
    int? groupId,
    String? sessionType,
    List<int>? subjectIds,
    List<int>? languageIds,
    bool isRefresh = false,
  }) async {
    if (!isRefresh) {
      setState(() {
        isInitialLoading = true;
      });
    } else {
      setState(() {
        isRefreshing = false;
      });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await findTutors(
        token,
        page: currentPage,
        perPage: 5,
        sortBy: sortBy,
        keyword: keyword,
        maxPrice: maxPrice,
        country: country,
        groupId: groupId,
        sessionType: sessionType,
        subjectIds: subjectIds,
        languageIds: languageIds,
      );

      if (response.containsKey('data') && response['data']['list'] is List) {
        setState(() {
          tutors = (response['data']['list'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
          currentPage = response['data']['pagination']['currentPage'];
          totalPages = response['data']['pagination']['totalPages'];
          totalTutors = response['data']['pagination']['total'];
        });
      }
    } catch (e) {
    } finally {
      setState(() {
        isInitialLoading = false;
        isRefreshing = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      currentPage = 1;
    });

    await fetchInitialTutors(isRefresh: true);
  }

  Future<void> loadMoreTutors() async {
    if (currentPage < totalPages && !isLoading) {
      setState(() {
        isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token;

        final response =
            await findTutors(token, page: currentPage + 1, perPage: 5);

        if (response.containsKey('data') && response['data']['list'] is List) {
          setState(() {
            tutors.addAll((response['data']['list'] as List)
                .map((item) => item as Map<String, dynamic>)
                .toList());
            currentPage = response['data']['pagination']['currentPage'];
            totalPages = response['data']['pagination']['totalPages'];
            totalTutors = response['data']['pagination']['total'];
          });
        }
      } catch (e) {
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null && index != 0) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: "Es necesario el Logeo!",
            content: "Necesitas estar logeado para ingresar",
            buttonText: "Ir al Login",
            buttonAction: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          );
        },
      );
      return;
    }

    /*if (index == 1) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: "No diponible",
            content: "Funcionalidad en desarrollo",
            buttonText: "Ir a login",
            buttonAction: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          );
        },
      );
      return;
    }
     */

    setState(() {
      selectedIndex = index;
    });

    _pageController.jumpToPage(index);
  }

  void openFilterBottomSheet() async {
    if (subjects.isEmpty) await fetchSubjects();
    if (languages.isEmpty) await fetchLanguages();
    if (countries.isEmpty) await fetchCountries();
    if (subjectGroups.isEmpty) await fetchSubjectGroups();

    showModalBottomSheet(
      backgroundColor: AppColors.sheetBackgroundColor,
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterBottomSheet(
        subjects: subjects,
        languages: languages,
        location: countries,
        subjectGroups: subjectGroups,
        selectedSubjectGroup: selectedSubjectGroup,
        selectedCountryId: selectedCountryId,
        keyword: keyword,
        maxPrice: maxPrice,
        sessionType: null,
        subjectIds: selectedSubjectIds,
        languageIds: selectedLanguageIds,
        onCountrySelected: (int countryId) {
          setState(() {
            selectedCountryId = countryId;
          });
        },
        onSubjectGroupSelected: (selectedGroup) {
          setState(() {
            selectedSubjectGroup = selectedGroup;
          });
        },
        onApplyFilters: ({
          String? keyword,
          double? maxPrice,
          int? country,
          int? groupId,
          String? sessionType,
          List<int>? subjectIds,
          List<int>? languageIds,
        }) {
          setState(() {
            this.keyword = keyword;
            this.maxPrice = maxPrice;
            this.selectedCountryId = country;
            this.selectedGroupId = groupId;
            this.sessionType = sessionType;
            this.selectedSubjectIds = subjectIds;
            this.selectedLanguageIds = languageIds;
          });
          fetchInitialTutors(
            keyword: keyword,
            maxPrice: maxPrice,
            country: country,
            groupId: groupId,
            sessionType: sessionType,
            subjectIds: subjectIds,
            languageIds: languageIds,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    final authProvider = Provider.of<AuthProvider>(context);
    final token = authProvider.token;

    Widget buildProfileIcon() {
      final isSelected = selectedIndex == 2;
      return Container(
        padding: EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.greyColor : Colors.transparent,
            width: isSelected ? 2.0 : 0.0,
          ),
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: token == null || profileImageUrl.isEmpty
            ? SvgPicture.asset(
                AppImages.userIcon,
                width: 20,
                height: 20,
                color: AppColors.greyColor,
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: Image.network(
                  profileImageUrl,
                  width: 25,
                  height: 25,
                  fit: BoxFit.cover,
                ),
              ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (isLoading) {
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.primaryGreen,
        body: Column(
          children: [
            if (selectedIndex == 0)
              Column(
                children: [
                  Container(
                    color: AppColors.primaryGreen,
                    padding: EdgeInsets.only(left: 20, right: 10.0),
                    child: AppBar(
                      backgroundColor: AppColors.primaryGreen,
                      automaticallyImplyLeading: false,
                      elevation: 0,
                      titleSpacing: 0,
                      centerTitle: false,
                      title: Text(
                        'Tutores',
                        style: TextStyle(
                          color: AppColors.whiteColor,
                          fontSize: FontSize.scale(context, 20),
                          fontFamily: 'SF-Pro-Text',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      actions: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Container(
                            padding: EdgeInsets.all(0),
                            width: 35,
                            height:35,
                            decoration: BoxDecoration(
                              color: AppColors.navbar,
                              borderRadius: BorderRadius.all(Radius.circular(10))
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: SvgPicture.asset(
                                AppImages.filterIcon,
                                color: AppColors.whiteColor,
                                width: 15,
                                height: 15,
                              ),
                              onPressed: () {
                                openFilterBottomSheet();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0,left : 10,bottom: 5),
                    child: Container(
                      decoration: BoxDecoration(
                          color: AppColors.navbar,
                        borderRadius: BorderRadius.circular(15)

                      ),

                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: _gradeSelector(),
                      ),
                    ),
                  ),
                ],
              ),
            Expanded(
              child: GestureDetector(
                onHorizontalDragUpdate: (_) {},
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    isInitialLoading
                        ? ListView.builder(
                            padding: EdgeInsets.symmetric(vertical: 2.0),
                            itemCount: 5,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10.0),
                                child: TutorCardSkeleton(isFullWidth: true),
                              );
                            },
                          )
                        : tutors.isEmpty
                            ? Center(
                                child: Text(
                                  "No tutors available",
                                  style: TextStyle(
                                    fontSize: FontSize.scale(context, 18),
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.greyColor,
                                    fontFamily: 'SF-Pro-Text',
                                  ),
                                ),
                              )
                            : NotificationListener<ScrollNotification>(
                                onNotification:
                                    (ScrollNotification scrollInfo) {
                                  if (scrollInfo.metrics.pixels ==
                                      scrollInfo.metrics.maxScrollExtent) {
                                    loadMoreTutors();
                                  }
                                  return true;
                                },
                                child: RefreshIndicator(
                                  onRefresh: _onRefresh,
                                  color: AppColors.primaryGreen,
                                  child: ListView.builder(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 2.0),
                                    itemCount:
                                        tutors.length + (isLoading ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == tutors.length) {
                                        return Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: CircularProgressIndicator(
                                              color: AppColors.primaryGreen,
                                              strokeWidth: 2.0,
                                            ),
                                          ),
                                        );
                                      }

                                      final tutor = tutors[index] ?? {};
                                      final profile = (tutor['profile'] is Map) ? tutor['profile'] : {};
                                      final country = (tutor['country'] is Map) ? tutor['country'] : {};
                                      final languages = (tutor['languages'] is List) ? tutor['languages'] : [];
                                      final subjects = (tutor['subjects'] is List) ? tutor['subjects'] : [];

                                      // Validación para saber si la API respondió mal
                                      if (tutor.isEmpty) {
                                        return Center(
                                          child: Text(
                                            "No hay tutores disponibles o hubo un error con la respuesta de la API.",
                                            style: TextStyle(
                                              fontSize: FontSize.scale(context, 18),
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.greyColor,
                                              fontFamily: 'SF-Pro-Text',
                                            ),
                                          ),
                                        );
                                      }

                                      return Padding(
                                        padding:
                                            const EdgeInsets.symmetric(vertical: 10.0),
                                        child: GestureDetector(
                                          onTap: () {
                                            if (profile != null &&
                                                profile is Map<String, dynamic>) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      TutorDetailScreen(
                                                          profile: profile, tutor: tutor,),
                                                ),
                                              );
                                            }
                                          },
                                          child: TutorCard(
                                            tutorId: tutor['id'] ?? '',
                                            name: profile['full_name'] ?? 'No name available',
                                            price: tutor['min_price'] != null
                                                ? '\$${tutor['min_price'].toString()}'
                                                : 'N/A',
                                            filledStar: (tutor['avg_rating'] != null &&
                                                (tutor['avg_rating'] is String
                                                    ? double.tryParse(tutor['avg_rating']) == 5.0
                                                    : (tutor['avg_rating'] is num && tutor['avg_rating'].toDouble() == 5.0))),
                                            description: subjects.isNotEmpty
                                                ? subjects
                                                    .where((subject) => subject != null && subject is Map && subject['name'] != null)
                                                    .map((subject) => subject['name'])
                                                    .join(', ')
                                                : 'No hay materias disponibles',
                                            rating: tutor['avg_rating'] != null
                                                ? (tutor['avg_rating'] is String
                                                    ? double.tryParse(tutor['avg_rating']) ?? 0.0
                                                    : (tutor['avg_rating'] is num ? tutor['avg_rating'].toDouble() : 0.0))
                                                : 0.0,
                                            reviews: '${tutor['total_reviews'] ?? 0}',
                                            activeStudents: '${tutor['active_students'] ?? 0}',
                                            sessions: '${tutor['sessions'] ?? 'N/A'}',
                                            languages: languages.isNotEmpty
                                                ? languages
                                                    .where((lang) => lang != null && lang is Map && lang['name'] != null)
                                                    .map((lang) => lang['name'])
                                                    .join(', ')
                                                : 'No hay idiomas disponibles',
                                            image: profile['image'] ?? AppImages.placeHolderImage,
                                            countryFlag: country['short_code'] != null
                                                ? 'https://flagcdn.com/w20/${country['short_code'].toLowerCase()}.png'
                                                : '',
                                            verificationIcon:
                                                profile['verified_at'] != null
                                                    ? AppImages.active
                                                    : '',
                                            onlineIndicator:
                                                tutor['is_online'] == true
                                                    ? AppImages.onlineIndicator
                                                    : '',
                                            isFullWidth: true,
                                            languagesText: true,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                    BookingScreen(
                      onBackPressed: () {
                        _pageController.jumpToPage(0);
                      },
                    ),
                    ProfileScreen(),
                  ],
                ),
              ),
            )
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: AppColors.navbar,
          currentIndex: selectedIndex,
          onTap: _onItemTapped,
          unselectedItemColor: AppColors.whiteColor,
          selectedItemColor: AppColors.whiteColor,
          selectedLabelStyle: TextStyle(
              color: AppColors.whiteColor,
              fontSize: FontSize.scale(context, 12),
              fontFamily: 'SF-Pro-Text',
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.normal),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: selectedIndex == 0
                  ? SvgPicture.asset(AppImages.searchBottomFilled,
                      width: 20, height: 20)
                  : SvgPicture.asset(AppImages.search, width: 20, height: 20,color: AppColors.whiteColor,),
              label: 'Buscar',
            ),
            BottomNavigationBarItem(
              icon: selectedIndex == 1
                  ? SvgPicture.asset(AppImages.calenderIcon,
                      width: 20, height: 20)
                  : SvgPicture.asset(AppImages.bookingIcon,
                      color: AppColors.whiteColor, width: 20, height: 20,),
              label: 'Reservar',
            ),
            BottomNavigationBarItem(
              icon: buildProfileIcon(),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  bool get wantKeepAlive => true;

  Widget _gradeSelector() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${tutors.length} Tutores',
                style: TextStyle(
                  fontFamily: 'SF-Pro-Text',
                  fontWeight: FontWeight.w500,
                  fontSize: FontSize.scale(context, 14),
                  fontStyle: FontStyle.normal,
                  color: AppColors.whiteColor,
                ),
              ),
              CustomDropdown(
                hint: "Elige uno",
                selectedValue: _selectedSorting,
                items: sortingOptions,
                onSelected: _onSortSelected,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
