import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:flutter_projects/view/components/main_header.dart';
import 'dart:async';

class SearchTutorsScreen extends StatefulWidget {
  final String? initialKeyword;

  const SearchTutorsScreen({
    Key? key,
    this.initialKeyword,
  }) : super(key: key);

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
  late ScrollController _scrollController;

  final GlobalKey _searchFilterContentKey = GlobalKey();
  double _initialSearchFilterHeight = 0.0;
  double _opacity = 1.0; // Añadido para controlar la opacidad
  double _lastScrollOffset = 0.0; // Para rastrear la dirección del scroll
  
  // Opacidades separadas para cada elemento
  double _searchOpacity = 1.0;
  double _counterOpacity = 1.0;
  double _filtersOpacity = 1.0;

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

  String? keyword;
  double? maxPrice;
  int? selectedGroupId;
  String? sessionType = 'group';
  List<int>? selectedSubjectIds;
  List<int>? selectedLanguageIds;
  String? _selectedSortOption;
  final List<String> _sortOptions = ['Más relevantes', 'Precio (asc)', 'Precio (desc)', 'Calificación'];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    print('DEBUG en initState: widget.initialKeyword = ${widget.initialKeyword}');
    keyword = widget.initialKeyword;
    _searchController.text = keyword ?? '';
    fetchInitialTutors(
      maxPrice: maxPrice,
      country: selectedCountryId,
      groupId: selectedGroupId,
      sessionType: sessionType,
      subjectIds: selectedSubjectIds,
      languageIds: selectedLanguageIds,
    );
    fetchSubjects();
    fetchLanguages();
    fetchSubjectGroups();
    fetchCountries();

    _pageController = PageController(initialPage: selectedIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_searchFilterContentKey.currentContext != null) {
        setState(() {
          _initialSearchFilterHeight = _searchFilterContentKey.currentContext!.size!.height;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
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

  @override
  void didUpdateWidget(covariant SearchTutorsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialKeyword != oldWidget.initialKeyword) {
      setState(() {
        keyword = widget.initialKeyword;
      });
      print('DEBUG en didUpdateWidget: widget.initialKeyword = ${widget.initialKeyword}, this.keyword = ${this.keyword}');
      fetchInitialTutors();
    }
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
    double? maxPrice,
    int? country,
    int? groupId,
    String? sessionType,
    List<int>? subjectIds,
    List<int>? languageIds,
    bool isRefresh = false,
  }) async {
    print('DEBUG en fetchInitialTutors: keyword = $keyword');
    if (!isRefresh) {
      setState(() {
        isInitialLoading = true;
      });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      print('DEBUG - Llamando a la API para la página inicial');
      final response = await getVerifiedTutors(
        token,
        page: 1,
        perPage: 10,
        keyword: this.keyword,
        maxPrice: maxPrice,
        country: country,
        groupId: groupId,
        sessionType: sessionType,
        subjectId: null,
        languageIds: languageIds,
      );

      if (response.containsKey('data') && response['data'] is Map) {
        final data = response['data'];
        if (data.containsKey('list') && data['list'] is List) {
          final tutorsList = data['list'] as List;
          print('DEBUG - API devolvió ${tutorsList.length} tutores para la página inicial');
          
          setState(() {
            if (isRefresh) {
              tutors = tutorsList.map((tutor) => tutor as Map<String, dynamic>).toList();
            } else {
              tutors = tutorsList.map((tutor) => tutor as Map<String, dynamic>).toList();
            }
            final paginationData = data['pagination'] is Map ? data['pagination'] : {};
            totalTutors = paginationData['total'] ?? 0;
            totalPages = paginationData['totalPages'] ?? 1;
            currentPage = 1;
            print('DEBUG - Paginación inicial: Total tutores: $totalTutors, Total páginas: $totalPages, Tutores cargados: ${tutors.length}');
          });
        }
      }
    } catch (e) {
      print('Error fetching tutors: $e');
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
    print('DEBUG - Intentando cargar más tutores. Página actual: $currentPage, Total páginas: $totalPages, Tutores actuales: ${tutors.length}');
    
    if (!isLoading && tutors.length < 100) {
      setState(() {
        isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token;

        print('DEBUG - Llamando a la API para la página ${currentPage + 1}');
        final response = await getVerifiedTutors(
          token, 
          page: currentPage + 1, 
          perPage: 10,
          keyword: this.keyword,
          maxPrice: maxPrice,
          country: selectedCountryId,
          groupId: selectedGroupId,
          sessionType: sessionType,
          subjectId: null,
          languageIds: selectedLanguageIds,
        );

        if (response.containsKey('data') && response['data'] is Map) {
          final data = response['data'];
          if (data.containsKey('list') && data['list'] is List) {
            final tutorsList = data['list'] as List;
            print('DEBUG - API devolvió ${tutorsList.length} tutores para la página ${currentPage + 1}');
            
            if (tutorsList.isNotEmpty) {
              setState(() {
                tutors.addAll(tutorsList.map((item) => item as Map<String, dynamic>).toList());
                final paginationData = data['pagination'] is Map ? data['pagination'] : {};
                currentPage = paginationData['currentPage'] ?? currentPage + 1;
                totalPages = paginationData['totalPages'] ?? totalPages;
                totalTutors = paginationData['total'] ?? totalTutors;
                print('DEBUG - Tutores cargados exitosamente. Nuevo total: ${tutors.length} de $totalTutors');
              });
            } else {
              print('DEBUG - No se encontraron más tutores en la página ${currentPage + 1}');
            }
          }
        }
      } catch (e) {
        print('Error loading more tutors: $e');
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      print('DEBUG - No se cargaron más tutores. Condiciones: !isLoading: ${!isLoading}, tutors.length < 100: ${tutors.length < 100}');
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
        keyword: this.keyword,
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
            maxPrice: maxPrice,
            country: country,
            groupId: groupId,
            sessionType: sessionType,
            languageIds: languageIds,
          );
        },
      ),
    );
  }

  void _scrollListener() {
    // Lógica para ocultar filtros al hacer scroll
    final offset = _scrollController.offset;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    
    // Detectar dirección del scroll
    final isScrollingUp = offset < _lastScrollOffset;
    final isScrollingDown = offset > _lastScrollOffset;
    
    // Calcular la velocidad del scroll para ajustar la animación
    final scrollDelta = (_lastScrollOffset - offset).abs();
    final animationSpeed = (scrollDelta * 0.08).clamp(0.03, 0.15); // Velocidad ajustada
    
    // Calcular las opacidades basadas en el scroll
    double newSearchOpacity = _searchOpacity;
    double newCounterOpacity = _counterOpacity;
    double newFiltersOpacity = _filtersOpacity;
    
    if (isScrollingUp) {
      // Al hacer scroll hacia arriba, mostrar secuencialmente con deslizamiento
      // Primero el buscador
      newSearchOpacity = (_searchOpacity + animationSpeed).clamp(0.0, 1.0);
      
      // Luego el contador (cuando el buscador esté casi visible)
      if (_searchOpacity > 0.2) {
        newCounterOpacity = (_counterOpacity + animationSpeed).clamp(0.0, 1.0);
      }
      
      // Finalmente los filtros (cuando el contador esté casi visible)
      if (_counterOpacity > 0.2) {
        newFiltersOpacity = (_filtersOpacity + animationSpeed).clamp(0.0, 1.0);
      }
      
    } else if (isScrollingDown && offset > 0) {
      // Al hacer scroll hacia abajo, ocultar todos juntos gradualmente
      final baseOpacity = (1 - (offset / 150)).clamp(0.0, 1.0);
      newSearchOpacity = baseOpacity;
      newCounterOpacity = baseOpacity;
      newFiltersOpacity = baseOpacity;
    } else if (offset <= 0) {
      // En la parte superior, mostrar completamente
      newSearchOpacity = 1.0;
      newCounterOpacity = 1.0;
      newFiltersOpacity = 1.0;
    }
    
    // Solo actualizar si alguna opacidad cambió significativamente
    bool needsUpdate = false;
    if ((_searchOpacity - newSearchOpacity).abs() > 0.01) {
      _searchOpacity = newSearchOpacity;
      needsUpdate = true;
    }
    if ((_counterOpacity - newCounterOpacity).abs() > 0.01) {
      _counterOpacity = newCounterOpacity;
      needsUpdate = true;
    }
    if ((_filtersOpacity - newFiltersOpacity).abs() > 0.01) {
      _filtersOpacity = newFiltersOpacity;
      needsUpdate = true;
    }
    
    if (needsUpdate) {
      setState(() {});
    }
    
    // Actualizar la posición del scroll anterior
    _lastScrollOffset = offset;
    
    // Lógica para cargar más tutores
    if (offset >= maxScrollExtent * 0.8) {
      print('DEBUG - Scroll alcanzó el 80% del final (en ListView.builder)');
      loadMoreTutors();
    }
  }

  Widget _buildFiltrosYBuscador() {
    // Alturas aproximadas de cada sección (ajusta según tu UI real)
    const double searchHeight = 60.0;
    const double counterHeight = 35.0;
    const double filtersHeight = 60.0;
    const double verticalPadding = 10.0;

    // Calcula la altura total visible según las opacidades
    double totalHeight =
        (searchHeight * _searchOpacity) +
        (counterHeight * _counterOpacity) +
        (filtersHeight * _filtersOpacity) +
        verticalPadding;

    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      curve: Curves.ease,
      height: totalHeight > 10 ? totalHeight : 0,
      child: Opacity(
        opacity: (_searchOpacity + _counterOpacity + _filtersOpacity) / 3,
        child: Container(
          color: AppColors.primaryGreen,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Buscador
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: searchHeight * _searchOpacity,
                transform: Matrix4.translationValues(0, _searchOpacity < 1.0 ? -50 * (1 - _searchOpacity) : 0, 0),
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 200),
                  opacity: _searchOpacity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
                    child: TextField(
                      controller: _searchController,
                      cursorColor: AppColors.greyColor,
                      onChanged: (value) {
                        setState(() {
                          keyword = value;
                          currentPage = 1;
                          tutors.clear();
                        });
                        fetchInitialTutors();
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar Tutor...',
                        hintStyle: AppTextStyles.body.copyWith(color: AppColors.lightGreyColor),
                        contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
                        prefixIcon: Icon(Icons.search, color: AppColors.lightGreyColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.navbar,
                      ),
                      style: AppTextStyles.body.copyWith(color: AppColors.whiteColor),
                    ),
                  ),
                ),
              ),
              // Contador de tutores
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: counterHeight * _counterOpacity,
                transform: Matrix4.translationValues(0, _counterOpacity < 1.0 ? -50 * (1 - _counterOpacity) : 0, 0),
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 200),
                  opacity: _counterOpacity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${totalTutors} Tutores',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.whiteColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Filtros
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: filtersHeight * _filtersOpacity,
                transform: Matrix4.translationValues(0, _filtersOpacity < 1.0 ? -50 * (1 - _filtersOpacity) : 0, 0),
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 200),
                  opacity: _filtersOpacity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            decoration: BoxDecoration(
                              color: AppColors.navbar,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSortOption,
                                hint: Text('Ordenar por: Elige uno', style: AppTextStyles.body.copyWith(color: AppColors.whiteColor)),
                                icon: Icon(Icons.arrow_drop_down, color: AppColors.whiteColor),
                                dropdownColor: AppColors.navbar,
                                style: AppTextStyles.body.copyWith(color: AppColors.whiteColor),
                                isExpanded: true,
                                items: _sortOptions.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    _selectedSortOption = newValue;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.navbar,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: IconButton(
                            icon: SvgPicture.asset(
                              AppImages.filterIcon,
                              color: AppColors.whiteColor,
                            ),
                            onPressed: openFilterBottomSheet,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutoresList() {
    if (isInitialLoading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: TutorCardSkeleton(isFullWidth: true),
          );
        },
      );
    } else if (tutors.isEmpty) {
      return Center(
        child: Text(
          "No tutors available",
          style: TextStyle(
            fontSize: FontSize.scale(context, 18),
            fontWeight: FontWeight.w500,
            color: AppColors.greyColor,
            fontFamily: 'SF-Pro-Text',
          ),
        ),
      );
    } else {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primaryGreen,
        child: ListView.builder(
          controller: _scrollController, // Usar el mismo scrollController
          itemCount: tutors.length + (isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == tutors.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final tutor = tutors[index];
            final profile = tutor['profile'] as Map<String, dynamic>;
            final subjects = tutor['subjects'] as List;
            final validSubjects = subjects
                .where((subject) => subject['status'] == 'active' && subject['deleted_at'] == null)
                .map((subject) => subject['name'] as String)
                .toList();
            print('DEBUG - Materias válidas: $validSubjects');
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
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
                  name: profile['full_name'] ?? 'No name available',
                  rating: tutor['avg_rating'] != null
                      ? (tutor['avg_rating'] is String
                          ? double.tryParse(tutor['avg_rating']) ?? 0.0
                          : (tutor['avg_rating'] is num ? tutor['avg_rating'].toDouble() : 0.0))
                      : 0.0,
                  reviews: int.tryParse('${tutor['total_reviews'] ?? 0}') ?? 0,
                  imageUrl: profile['image'] ?? AppImages.placeHolderImage,
                  onRejectPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ver Perfil de ${profile['full_name'] ?? 'Tutor'}')),
                    );
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
                  onAcceptPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Reservar con ${profile['full_name'] ?? 'Tutor'}')),
                    );
                  },
                  tutorProfession: validSubjects.isNotEmpty ? validSubjects.first : 'Profesión no disponible',
                  sessionDuration: 'Clases de 20 minutos',
                  isFavoriteInitial: tutor['is_favorite'] ?? false,
                  onFavoritePressed: (isFavorite) {
                    print('Tutor ${profile['full_name'] ?? ''} es favorito: $isFavorite');
                  },
                  description: validSubjects.join(', '),
                  isVerified: true,
                ),
              ),
            );
          },
        ),
      );
    }
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
            MainHeader(
              onMenuPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              onProfilePressed: () {
                _onItemTapped(2);
              },
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                children: [
                  Column( // Cambiado de NotificationListener a Column
                    children: [
                      _buildFiltrosYBuscador(),
                      Expanded(
                        child: _buildTutoresList(),
                      ),
                    ],
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
}
