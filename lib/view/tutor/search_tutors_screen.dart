import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/helpers/slide_up_route.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/components/login_required_alert.dart';
import 'package:flutter_projects/view/components/skeleton/tutor_card_skeleton.dart';
import 'package:flutter_projects/view/components/tutor_card.dart';
import 'package:flutter_projects/view/profile/profile_screen.dart';
import 'package:flutter_projects/view/tutor/component/filter_turtor_bottom_sheet.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/view/tutor/tutor_profile_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_projects/view/tutor/instant_tutoring_screen.dart';
import 'package:flutter_projects/view/tutor/student_calendar_screen.dart';
import 'package:flutter_projects/view/tutor/student_history_screen.dart';
import 'package:flutter_projects/view/components/main_header.dart';
// removed unused imports

class SearchTutorsScreen extends StatefulWidget {
  final String? initialKeyword;
  final int? initialSubjectId;
  final String initialMode;
  final int? initialPage;

  const SearchTutorsScreen({
    Key? key,
    this.initialKeyword,
    this.initialSubjectId,
    this.initialMode = 'agendar',
    this.initialPage,
  }) : super(key: key);

  @override
  State<SearchTutorsScreen> createState() => _SearchTutorsScreenState();
}

class _SearchTutorsScreenState extends State<SearchTutorsScreen> {
  final FocusNode _searchFocusNode = FocusNode(); // 1. Crear el FocusNode
  List<Map<String, dynamic>> tutors = [];
  int currentPage = 1;
  int totalPages = 1;
  int totalTutors = 0;
  bool isLoading = false;
  bool isInitialLoading = false;
  bool isRefreshing = false;
  late ScrollController _scrollController;

  final GlobalKey _searchFilterContentKey = GlobalKey();
  // double _initialSearchFilterHeight = 0.0; // unused
  // double _opacity = 1.0; // unused
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
  String? tutorName;
  double? maxPrice;
  int? selectedGroupId;
  String? sessionType;
  List<int>? selectedLanguageIds;
  int? selectedSubjectId;
  String? _selectedSortOption;
  final List<String> _sortOptions = [
    'Nombre (A-Z)',
    'Nombre (Z-A)',
    'Materia (A-Z)',
    'Materia (Z-A)'
  ];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  int? _minCourses;
  double? _minRating;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Mapa para asociar id de tutor con su imagen de alta resolución
  Map<int, String> highResTutorImages = {};

  bool _showBottomBar =
      true; // Controla la visibilidad de la barra de navegación
  // double _bottomBarOffset = 0.0; // unused

  late String selectedMode;

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (keyword != value) {
        setState(() {
          keyword = value;
          currentPage = 1;
          tutors.clear();
          isInitialLoading = true;
        });
        fetchInitialTutors();
      }
    });
  }

  String _getFirstValidSubject(List subjects) {
    final validSubjects = subjects
        .where((s) => s['status'] == 'active' && s['deleted_at'] == null)
        .map((s) => s['name'] as String)
        .toList();
    return validSubjects.isNotEmpty ? validSubjects.first : '';
  }

  void _sortTutors(String? sortOption) {
    if (sortOption == null) return;

    setState(() {
      tutors.sort((a, b) {
        switch (sortOption) {
          case 'Nombre (A-Z)':
            return (a['profile']['full_name'] as String)
                .compareTo(b['profile']['full_name'] as String);
          case 'Nombre (Z-A)':
            return (b['profile']['full_name'] as String)
                .compareTo(a['profile']['full_name'] as String);
          case 'Materia (A-Z)':
            final aSubject = _getFirstValidSubject(a['subjects'] as List);
            final bSubject = _getFirstValidSubject(b['subjects'] as List);
            return aSubject.compareTo(bSubject);
          case 'Materia (Z-A)':
            final aSubject = _getFirstValidSubject(a['subjects'] as List);
            final bSubject = _getFirstValidSubject(b['subjects'] as List);
            return bSubject.compareTo(aSubject);
          default:
            return 0;
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    print(
        'DEBUG en initState: widget.initialKeyword = ${widget.initialKeyword}');
    keyword = widget.initialKeyword;
    selectedSubjectId = widget.initialSubjectId;
    selectedMode = widget.initialMode;
    _searchController.text = keyword ?? '';
    fetchHighResTutorImages();
    fetchInitialTutors(
      maxPrice: maxPrice,
      country: selectedCountryId,
      groupId: selectedGroupId,
      sessionType: sessionType,
      subjectId: selectedSubjectId,
      languageIds: selectedLanguageIds,
      tutorName: tutorName,
      minCourses: _minCourses,
      minRating: _minRating,
    );
    fetchSubjects();
    fetchLanguages();
    fetchSubjectGroups();
    fetchCountries();

    // Si se proporciona una página inicial, usarla
    if (widget.initialPage != null) {
      selectedIndex = widget.initialPage!;
    }
    _pageController = PageController(initialPage: selectedIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Medición de altura no utilizada actualmente
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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
    if (widget.initialKeyword != oldWidget.initialKeyword ||
        widget.initialSubjectId != oldWidget.initialSubjectId) {
      setState(() {
        keyword = widget.initialKeyword;
        selectedSubjectId = widget.initialSubjectId;
      });
      print(
          'DEBUG en didUpdateWidget: widget.initialKeyword = ${widget.initialKeyword}, widget.initialSubjectId = ${widget.initialSubjectId}');
      fetchInitialTutors(
        maxPrice: maxPrice,
        country: selectedCountryId,
        groupId: selectedGroupId,
        sessionType: sessionType,
        subjectId: widget.initialSubjectId,
        languageIds: selectedLanguageIds,
        tutorName: tutorName,
        minCourses: _minCourses,
        minRating: _minRating,
      );
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
    List<int>? languageIds,
    int? subjectId,
    String? tutorName,
    int? minCourses,
    double? minRating,
  }) async {
    if (isLoading) return;
    setState(() {
      isInitialLoading = true;
      if (tutors.isEmpty) {
        isInitialLoading = true;
      }
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      print('DEBUG - Llamando a la API ${selectedMode == 'instantanea' ? 'availableTutors' : 'verifiedTutors'} para la página inicial');
      print('DEBUG - keyword (materia): $keyword');
      print('DEBUG - Modo seleccionado: $selectedMode');
      
            final response = selectedMode == 'instantanea' 
          ? await getAvailableTutors(
              token,
              page: currentPage,
              keyword: keyword, // Usar keyword para buscar por materia
              tutorName: tutorName, // Usar tutorName para buscar por nombre del tutor
              maxPrice: maxPrice,
              country: country,
              groupId: groupId,
              sessionType: sessionType,
              subjectId: subjectId,
              languageIds: languageIds,
              minCourses: minCourses ?? _minCourses,
              minRating: minRating ?? _minRating,
            )
          : await getVerifiedTutors(
              token,
              page: currentPage,
              keyword: keyword, // Usar keyword para buscar por materia
              tutorName: tutorName, // Usar tutorName para buscar por nombre del tutor
              maxPrice: maxPrice,
              country: country,
              groupId: groupId,
              sessionType: sessionType,
              subjectId: subjectId,
              languageIds: languageIds,
              minCourses: minCourses ?? _minCourses,
              minRating: minRating ?? _minRating,
            );

      print('DEBUG - Response completa: $response');

      // Verificar diferentes estructuras posibles de la respuesta
      List<dynamic> fetchedTutors = [];

      if (response['data'] != null) {
        if (response['data'] is List) {
          // Si data es directamente una lista
          fetchedTutors = response['data'] as List<dynamic>;
          print(
              'DEBUG - Data es directamente una lista con ${fetchedTutors.length} tutores');
        } else if (response['data'] is Map &&
            response['data']['data'] is List) {
          // Si data es un objeto con una propiedad data que es una lista
          fetchedTutors = response['data']['data'] as List<dynamic>;
          print(
              'DEBUG - Data está en response[\'data\'][\'data\'] con ${fetchedTutors.length} tutores');
        } else if (response['data'] is Map &&
            response['data']['list'] is List) {
          // Si data es un objeto con una propiedad list que es una lista
          fetchedTutors = response['data']['list'] as List<dynamic>;
          print(
              'DEBUG - Data está en response[\'data\'][\'list\'] con ${fetchedTutors.length} tutores');
        }
      }

      if (fetchedTutors.isNotEmpty) {
        print(
            'DEBUG - API devolvió ${fetchedTutors.length} tutores para la página inicial');

        // Log para ver la estructura del primer tutor
        print(
            'DEBUG - Estructura del primer tutor: ${fetchedTutors.first.keys.toList()}');
        if (fetchedTutors.first.containsKey('profile')) {
          print(
              'DEBUG - Profile keys: ${fetchedTutors.first['profile'].keys.toList()}');
        }
        if (fetchedTutors.first.containsKey('subjects')) {
          print(
              'DEBUG - Subjects count: ${fetchedTutors.first['subjects'].length}');
        }

        setState(() {
          tutors = fetchedTutors
              .map((tutor) => tutor as Map<String, dynamic>)
              .toList();

          // Manejar paginación
          int total = 0;
          int totalPages = 1;

          if (response['data'] is Map) {
            final paginationData =
                response['data']['pagination'] ?? response['data'];
            total = paginationData['total'] ?? fetchedTutors.length;
            totalPages = paginationData['totalPages'] ?? 1;
          }

          this.totalTutors = total;
          this.totalPages = totalPages;
          currentPage = 1;
          print(
              'DEBUG - Paginación inicial: Total tutores: $totalTutors, Total páginas: $totalPages, Tutores cargados: ${tutors.length}');
        });
      } else {
        print('DEBUG - No se encontraron tutores en la respuesta');
        print('DEBUG - response[\'data\']: ${response['data']}');
        if (response['data'] != null && response['data'] is Map) {
          print('DEBUG - Data keys: ${response['data'].keys.toList()}');
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
      isRefreshing = true;
      currentPage = 1;
      tutors.clear();
    });
    await fetchInitialTutors();
    setState(() {
      isRefreshing = false;
    });
  }

  void _loadMoreTutors() async {
    print(
        'DEBUG - Intentando cargar más tutores. Página actual: $currentPage, Total páginas: $totalPages, Tutores actuales: ${tutors.length}');

    if (!isLoading && tutors.length < 100) {
      setState(() {
        isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token;

        print(
            'DEBUG - Llamando a la API ${selectedMode == 'instantanea' ? 'availableTutors' : 'verifiedTutors'} para la página ${currentPage + 1}');
                final response = selectedMode == 'instantanea'
            ? await getAvailableTutors(
                token,
                page: currentPage + 1,
                perPage: 10,
                keyword: keyword, // Usar keyword para buscar por materia
                tutorName:
                    tutorName, // Usar tutorName para buscar por nombre del tutor
                maxPrice: maxPrice,
                country: selectedCountryId,
                groupId: selectedGroupId,
                sessionType: sessionType,
                subjectId: selectedSubjectId,
                languageIds: selectedLanguageIds,
                minCourses: _minCourses,
                minRating: _minRating,
              )
            : await getVerifiedTutors(
                token,
                page: currentPage + 1,
                perPage: 10,
                keyword: keyword, // Usar keyword para buscar por materia
                tutorName:
                    tutorName, // Usar tutorName para buscar por nombre del tutor
                maxPrice: maxPrice,
                country: selectedCountryId,
                groupId: selectedGroupId,
                sessionType: sessionType,
                subjectId: selectedSubjectId,
                languageIds: selectedLanguageIds,
                minCourses: _minCourses,
                minRating: _minRating,
              );

        if (response.containsKey('data') && response['data'] is Map) {
          final data = response['data'];
          List<dynamic> tutorsList = [];

          if (data.containsKey('data') && data['data'] is List) {
            tutorsList = data['data'] as List;
          } else if (data.containsKey('list') && data['list'] is List) {
            tutorsList = data['list'] as List;
          }

          print(
              'DEBUG - API devolvió ${tutorsList.length} tutores para la página ${currentPage + 1}');

          if (tutorsList.isNotEmpty) {
            setState(() {
              tutors.addAll(tutorsList
                  .map((item) => item as Map<String, dynamic>)
                  .toList());
              final paginationData = data['pagination'] ?? data;
              currentPage = paginationData['currentPage'] ?? currentPage + 1;
              totalPages = paginationData['totalPages'] ?? totalPages;
              totalTutors = paginationData['total'] ?? totalTutors;
              print(
                  'DEBUG - Tutores cargados exitosamente. Nuevo total: ${tutors.length} de $totalTutors');
            });
          } else {
            print(
                'DEBUG - No se encontraron más tutores en la página ${currentPage + 1}');
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
      print(
          'DEBUG - No se cargaron más tutores. Condiciones: !isLoading: ${!isLoading}, tutors.length < 100: ${tutors.length < 100}');
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

  void openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterTutorBottomSheet(
        subjectGroups: subjectGroups,
        selectedGroupId: selectedGroupId,
        tutorName: tutorName,
        minCourses: _minCourses,
        minRating: _minRating,
        onApplyFilters: (
            {int? groupId,
            String? tutorName,
            int? minCourses,
            double? minRating}) {
          setState(() {
            this.selectedGroupId = groupId;
            this.tutorName = tutorName;
            this._minCourses = minCourses;
            this._minRating = minRating;

            currentPage = 1;
            tutors.clear();
            isInitialLoading = true;
          });
          fetchInitialTutors(
            maxPrice: maxPrice,
            country: selectedCountryId,
            groupId: groupId,
            sessionType: sessionType,
            subjectId: selectedSubjectId,
            languageIds: selectedLanguageIds,
            tutorName: tutorName,
            minCourses: minCourses,
            minRating: minRating,
          );
        },
      ),
    );
  }

  void _scrollListener() {
    final offset = _scrollController.offset;
    final direction = _scrollController.position.userScrollDirection;

    // Lógica simplificada para mostrar/ocultar la barra de navegación
    if (direction == ScrollDirection.reverse && _showBottomBar) {
      setState(() {
        _showBottomBar = false;
      });
    } else if (direction == ScrollDirection.forward && !_showBottomBar) {
      setState(() {
        _showBottomBar = true;
      });
    }

    // Mantener la lógica para la animación de los filtros superiores
    // final maxScrollExtent = _scrollController.position.maxScrollExtent; // unused
    final scrollDelta = (_lastScrollOffset - offset).abs();
    final animationSpeed = (scrollDelta * 0.1).clamp(0.05, 0.2);

    double newSearchOpacity = _searchOpacity;
    double newCounterOpacity = _counterOpacity;
    double newFiltersOpacity = _filtersOpacity;

    if (offset <= 0) {
      newSearchOpacity = 1.0;
      newCounterOpacity = 1.0;
      newFiltersOpacity = 1.0;
    } else if (direction == ScrollDirection.forward) {
      newSearchOpacity = (_searchOpacity + animationSpeed).clamp(0.0, 1.0);
      if (_searchOpacity > 0.3) {
        newCounterOpacity = (_counterOpacity + animationSpeed).clamp(0.0, 1.0);
      }
      if (_counterOpacity > 0.3) {
        newFiltersOpacity = (_filtersOpacity + animationSpeed).clamp(0.0, 1.0);
      }
    } else if (direction == ScrollDirection.reverse && offset > 0) {
      if (_filtersOpacity > 0.0) {
        newFiltersOpacity = (_filtersOpacity - animationSpeed).clamp(0.0, 1.0);
      }
      if (_filtersOpacity < 0.3) {
        newCounterOpacity = (_counterOpacity - animationSpeed).clamp(0.0, 1.0);
      }
      if (_counterOpacity < 0.3) {
        newSearchOpacity = (_searchOpacity - animationSpeed).clamp(0.0, 1.0);
      }
    }

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

    _lastScrollOffset = offset;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreTutors();
    }
  }

  Widget _buildFiltrosYBuscador() {
    double searchHeight = 60.0;
    double counterHeight = 35.0;
    double filtersHeight = 55.0;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(30.0),
        bottomRight: Radius.circular(30.0),
      ),
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.blurprimary.withOpacity(0.5),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30.0),
            bottomRight: Radius.circular(30.0),
          ),
          border: Border(
            bottom: BorderSide(
                color: AppColors.navbar.withOpacity(0.3), width: 1.5),
            left: BorderSide(
                color: AppColors.navbar.withOpacity(0.3), width: 1.5),
            right: BorderSide(
                color: AppColors.navbar.withOpacity(0.3), width: 1.5),
          ),
        ),
        child: Column(
          key: _searchFilterContentKey,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Buscador
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: searchHeight * _searchOpacity,
              transform: Matrix4.translationValues(
                  0, _searchOpacity < 1.0 ? -50 * (1 - _searchOpacity) : 0, 0),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _searchOpacity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Busca por materia...',
                      hintStyle: AppTextStyles.body.copyWith(
                          color: AppColors.whiteColor.withOpacity(0.7)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 12),
                      prefixIcon: Icon(Icons.search,
                          color: AppColors.whiteColor.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.2),
                    ),
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.whiteColor),
                  ),
                ),
              ),
            ),
            // Contador de tutores
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: counterHeight * _counterOpacity,
              transform: Matrix4.translationValues(0,
                  _counterOpacity < 1.0 ? -50 * (1 - _counterOpacity) : 0, 0),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _counterOpacity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 2.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      (keyword != null && keyword!.isNotEmpty)
                          ? '${totalTutors} tutores para "${keyword!}"'
                          : '${totalTutors} Tutores Encontrados',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.whiteColor.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Filtros + Chips con scroll y botón fijo
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: filtersHeight * _filtersOpacity,
              transform: Matrix4.translationValues(0,
                  _filtersOpacity < 1.0 ? -50 * (1 - _filtersOpacity) : 0, 0),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _filtersOpacity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      // Scroll horizontal para chips y dropdown
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildModeChip('agendar', 'Agendar'),
                              SizedBox(width: 4),
                              _buildModeChip(
                                  'instantanea', 'Tutoría instantánea'),
                              SizedBox(width: 4),
                              Container(
                                width: 90,
                                height: 32,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedSortOption,
                                    hint: Text('Ordenar',
                                        style: AppTextStyles.body.copyWith(
                                            color: AppColors.whiteColor
                                                .withOpacity(0.7),
                                            fontSize: 11)),
                                    icon: Icon(Icons.arrow_drop_down,
                                        color: AppColors.whiteColor
                                            .withOpacity(0.7),
                                        size: 15),
                                    dropdownColor: AppColors.blurprimary,
                                    borderRadius: BorderRadius.circular(12.0),
                                    style: AppTextStyles.body.copyWith(
                                        color: AppColors.whiteColor,
                                        fontSize: 11),
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
                                        _sortTutors(newValue);
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      // Botón de filtro fijo a la derecha
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.orangeprimary,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.orangeprimary.withOpacity(0.3),
                              blurRadius: 5,
                              spreadRadius: 0.5,
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: SvgPicture.asset(
                            AppImages.filterIcon,
                            color: AppColors.whiteColor,
                            width: 13,
                            height: 13,
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
    );
  }

  Widget _buildModeChip(String mode, String label) {
    final bool isSelected = selectedMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMode = mode;
          // Recargar tutores cuando se cambie el modo
          currentPage = 1;
          tutors.clear();
          isInitialLoading = true;
        });
        // Llamar a la API con el nuevo modo
        fetchInitialTutors(
          maxPrice: maxPrice,
          country: selectedCountryId,
          groupId: selectedGroupId,
          sessionType: sessionType,
          subjectId: selectedSubjectId,
          languageIds: selectedLanguageIds,
          tutorName: tutorName,
          minCourses: _minCourses,
          minRating: _minRating,
        );
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightBlueColor : AppColors.darkBlue,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: AppColors.lightBlueColor,
                  width: 1.5,
                )
              : null,
        ),
        child: Opacity(
          opacity: isSelected ? 1.0 : 0.55,
          child: Row(
            children: [
              if (mode == 'agendar')
                Icon(Icons.calendar_today,
                    color: isSelected ? Colors.white : AppColors.lightBlueColor,
                    size: 16),
              if (mode == 'instantanea')
                Icon(Icons.flash_on,
                    color: isSelected ? Colors.white : AppColors.lightBlueColor,
                    size: 16),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.lightBlueColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
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
      return AnimationLimiter(
        child: ListView.builder(
          itemCount: 5,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 600),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: TutorCardSkeleton(isFullWidth: true),
                  ),
                ),
              ),
            );
          },
        ),
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
        child: AnimationLimiter(
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
                  .where((subject) =>
                      subject['status'] == 'active' &&
                      subject['deleted_at'] == null)
                  .map((subject) => subject['name'] as String)
                  .toList();

              // Obtener el primer subject válido para el ID
              final firstValidSubject = subjects
                  .where((subject) =>
                      subject['status'] == 'active' &&
                      subject['deleted_at'] == null)
                  .firstOrNull;
              final subjectId = firstValidSubject?['id'] ?? 1;

              // Depuración de imágenes de tutores
              final hdUrl = highResTutorImages[tutor['id']];
              print(
                  'Tutor: ${profile['full_name']} - tutor["id"]: ${tutor['id']} - HD URL: $hdUrl');

              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 600),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: GestureDetector(
                        onTap: () {
                          _searchFocusNode.unfocus(); // Quitar el foco
                          Navigator.push(
                            context,
                            SlideUpRoute(
                              page: TutorProfileScreen(
                                tutorId: tutor['id'].toString(),
                                tutorName:
                                    profile['full_name'] ?? 'No name available',
                                tutorImage: highResTutorImages[tutor['id']] ??
                                    profile['image'] ??
                                    AppImages.placeHolderImage,
                                tutorVideo: profile['intro_video'] ?? '',
                                description: profile['description'] ??
                                    'No hay descripción disponible.',
                                rating: tutor['avg_rating'] != null
                                    ? (tutor['avg_rating'] is String
                                        ? double.tryParse(
                                                tutor['avg_rating']) ??
                                            0.0
                                        : (tutor['avg_rating'] is num
                                            ? tutor['avg_rating'].toDouble()
                                            : 0.0))
                                    : 0.0,
                                subjects: validSubjects,
                                completedCourses: (tutor[
                                        'completed_courses_count'] is int)
                                    ? tutor['completed_courses_count'] ?? 0
                                    : int.tryParse(
                                            '${tutor['completed_courses_count'] ?? 0}') ??
                                        0,
                              ),
                            ),
                          );
                        },
                        child: TutorCard(
                          name: profile['full_name'] ?? 'No name available',
                          rating: tutor['avg_rating'] != null
                              ? (tutor['avg_rating'] is String
                                  ? double.tryParse(tutor['avg_rating']) ?? 0.0
                                  : (tutor['avg_rating'] is num
                                      ? tutor['avg_rating'].toDouble()
                                      : 0.0))
                              : 0.0,
                          reviews:
                              int.tryParse('${tutor['total_reviews'] ?? 0}') ??
                                  0,
                          imageUrl: highResTutorImages[tutor['id']] ??
                              profile['image'] ??
                              AppImages.placeHolderImage,
                          tutorId: tutor['id'].toString(),
                          tutorVideo: profile['intro_video'] ?? '',
                          tagline: profile['tagline'] as String?,
                          onRejectPressed: () {
                            _searchFocusNode.unfocus(); // Quitar el foco
                            Navigator.push(
                              context,
                              SlideUpRoute(
                                page: TutorProfileScreen(
                                  tutorId: tutor['id'].toString(),
                                  tutorName: profile['full_name'] ??
                                      'No name available',
                                  tutorImage: highResTutorImages[tutor['id']] ??
                                      profile['image'] ??
                                      AppImages.placeHolderImage,
                                  tutorVideo: profile['intro_video'] ?? '',
                                  description: profile['description'] ??
                                      'No hay descripción disponible.',
                                  rating: tutor['avg_rating'] != null
                                      ? (tutor['avg_rating'] is String
                                          ? double.tryParse(
                                                  tutor['avg_rating']) ??
                                              0.0
                                          : (tutor['avg_rating'] is num
                                              ? tutor['avg_rating'].toDouble()
                                              : 0.0))
                                      : 0.0,
                                  subjects: validSubjects,
                                  completedCourses: (tutor[
                                          'completed_courses_count'] is int)
                                      ? tutor['completed_courses_count'] ?? 0
                                      : int.tryParse(
                                              '${tutor['completed_courses_count'] ?? 0}') ??
                                          0,
                                ),
                              ),
                            );
                          },
                          onAcceptPressed: selectedMode == 'agendar'
                              ? () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => BookingModal(
                                      tutorName: profile['full_name'] ??
                                          'No name available',
                                      tutorImage:
                                          highResTutorImages[tutor['id']] ??
                                              profile['image'] ??
                                              AppImages.placeHolderImage,
                                      subjects: validSubjects,
                                      tutorId: tutor['id'],
                                      subjectId: subjectId,
                                    ),
                                  );
                                }
                              : () {
                                  // Acción para tutoría instantánea (como antes)
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => Container(
                                      margin: EdgeInsets.only(top: 60),
                                      decoration: BoxDecoration(
                                        color: AppColors.darkBlue,
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(24)),
                                      ),
                                      child: InstantTutoringScreen(
                                        tutorName: profile['full_name'] ??
                                            'No name available',
                                        tutorImage:
                                            highResTutorImages[tutor['id']] ??
                                                profile['image'] ??
                                                AppImages.placeHolderImage,
                                        subjects: validSubjects,
                                        tutorId: tutor['id'],
                                        subjectId: subjectId,
                                      ),
                                    ),
                                  );
                                },
                          tutorProfession: validSubjects.isNotEmpty
                              ? validSubjects.first
                              : 'Profesión no disponible',
                          sessionDuration: 'Clases de 20 minutos',
                          isFavoriteInitial: tutor['is_favorite'] ?? false,
                          onFavoritePressed: (isFavorite) {
                            print(
                                'Tutor ${profile['full_name'] ?? ''} es favorito: $isFavorite');
                          },
                          subjectsString: validSubjects.join(', '),
                          description: profile['description'] ??
                              'No hay descripción disponible.',
                          isVerified: true,
                          showStartButton: selectedMode == 'instantanea',
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  Future<void> fetchHighResTutorImages() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await getVerifiedTutorsPhotos(token);
      if (response.containsKey('data') && response['data'] is List) {
        final List<dynamic> data = response['data'];
        setState(() {
          highResTutorImages = {
            for (var item in data)
              if (item['id'] != null && item['profile_image'] != null)
                item['id'] as int: item['profile_image'] as String
          };
        });
      }
    } catch (e) {
      print('Error fetching high-res tutor images: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    // final authProvider = Provider.of<AuthProvider>(context);
    // final token = authProvider.token; // unused

    // buildProfileIcon() eliminado por no ser usado

    return WillPopScope(
      onWillPop: () async {
        if (isLoading) {
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset:
            false, // Evita que la barra suba con el teclado
        key: _scaffoldKey,
        backgroundColor: AppColors.primaryGreen,
        body: Stack(
          children: [
            Column(
              children: [
                MainHeader(
                  showMenuButton: false,
                  showProfileButton: false,
                  showBackButton: true,
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
                    physics: NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    children: [
                      Column(
                        children: [
                          _buildFiltrosYBuscador(),
                          Expanded(
                            child: _buildTutoresList(),
                          ),
                        ],
                      ),
                      StudentCalendarScreen(),
                      StudentHistoryScreen(),
                      ProfileScreen(),
                    ],
                  ),
                ),
              ],
            ),
            // Barra flotante
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                offset: _showBottomBar ? Offset(0, 0) : Offset(0, 1),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  opacity: _showBottomBar ? 1.0 : 0.0,
                  child: SizedBox(
                    height: 80,
                    child: _ModernNavBar(
                      currentIndex: selectedIndex,
                      onTap: _onItemTapped,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _ModernNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = [
      {'icon': Icons.search_outlined, 'label': 'Buscar'},
      {'icon': Icons.calendar_today_outlined, 'label': 'Reservas'},
      {'icon': Icons.history_edu_outlined, 'label': 'Historial'},
      {'icon': Icons.person_outline, 'label': 'Perfil'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.blurprimary.withOpacity(0.85),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (index) {
          bool isActive = index == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.orangeprimary.withOpacity(0.95)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  navItems[index]['icon'] as IconData,
                  color:
                      isActive ? Colors.white : Colors.white.withOpacity(0.7),
                  size: 24,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class BookingModal extends StatefulWidget {
  final String tutorName;
  final String tutorImage;
  final List<String> subjects;
  final int tutorId;
  final int subjectId;

  const BookingModal({
    required this.tutorName,
    required this.tutorImage,
    required this.subjects,
    required this.tutorId,
    required this.subjectId,
  });

  @override
  State<BookingModal> createState() => BookingModalState();
}

class BookingModalState extends State<BookingModal> {
  String? selectedSubject;
  DateTime? selectedDay;
  String? selectedHour;

  // Reemplazar datos estáticos con datos dinámicos
  Map<int, List<String>> availableDays =
      {}; // Clave: millisecondsSinceEpoch, Valor: Lista de horarios
  bool isLoading = true;
  String? errorMessage;

  DateTime currentMonth = DateTime.now();
  ScrollController? _sheetScrollController;

  // --- NUEVO: Keys y animaciones para resaltar secciones ---
  final GlobalKey _materiaKey = GlobalKey();
  final GlobalKey _calendarKey = GlobalKey();
  final GlobalKey _hourKey = GlobalKey();
  bool _highlightMateria = false;
  bool _highlightCalendar = false;
  bool _highlightHour = false;

  OverlayEntry? _floatingMessage;

  @override
  void initState() {
    super.initState();
    if (widget.subjects.isNotEmpty) {
      selectedSubject = widget.subjects.first;
    }

    // Cargar los datos reales del tutor
    _loadTutorAvailableSlots();
  }

  /// Carga los horarios disponibles del tutor para el mes actual
  ///
  /// ✅ CAMBIO IMPORTANTE: Ahora usa el endpoint correcto:
  /// /tutor/{tutorId}/available-slots en lugar de /subject-slots
  ///
  /// SOLUCIÓN AL PROBLEMA: Anteriormente se usaba solo el día del mes (startTime.day)
  /// lo que causaba que se mostraran días incorrectos. Ahora se usa la fecha completa
  /// como clave (millisecondsSinceEpoch) para evitar conflictos entre meses.
  Future<void> _loadTutorAvailableSlots() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        setState(() {
          errorMessage = 'No se pudo autenticar';
          isLoading = false;
        });
        return;
      }

      final response =
          await getTutorAvailableSlots(token, widget.tutorId.toString());

      final Map<int, List<String>> newAvailableDays = {};

      // ✅ CAMBIO: Procesar la respuesta del nuevo endpoint
      // La API devuelve directamente una lista de slots
      dynamic data;

      if (response.containsKey('data')) {
        data = response['data'];
      } else {
        data = response;
      }

      // ✅ SIMPLIFICADO: Solo procesar la lista de slots
      if (data is List) {
        for (var slot in data) {
          try {
            // Verificar que el slot tenga los campos necesarios
            if (slot['start_time'] == null ||
                slot['end_time'] == null ||
                slot['date'] == null) {
              continue;
            }

            // ✅ CAMBIO: Usar el campo 'date' para determinar el día
            final dateStr = slot['date'].toString().trim();
            final slotDate = DateTime.parse(dateStr);

            // ✅ CAMBIO: Solo filtrar por fecha futura, no por mes actual
            if (slotDate.isAfter(DateTime.now().subtract(Duration(days: 1)))) {
              // ✅ SOLUCIÓN: Usar fecha completa como clave
              final dateKey =
                  DateTime(slotDate.year, slotDate.month, slotDate.day);

              // ✅ CAMBIO: Usar start_time y end_time para las horas
              // ✅ CORRECCIÓN: Ajustar zona horaria de UTC a Bolivia (UTC-4)
              final startTimeUTC =
                  DateTime.parse(slot['start_time'].toString().trim());
              final endTimeUTC =
                  DateTime.parse(slot['end_time'].toString().trim());

              // Convertir a hora local de Bolivia (UTC-4)
              // Los horarios de la base de datos están en UTC, restamos 4 horas para Bolivia
              final startTime = startTimeUTC.subtract(Duration(hours: 4));
              final endTime = endTimeUTC.subtract(Duration(hours: 4));

              // ✅ DEBUG: Verificar conversión de zona horaria
              print(
                  '[BookingModal] 🔍 DEBUG - Zona horaria: UTC ${_formatTime(startTimeUTC)}-${_formatTime(endTimeUTC)} -> Bolivia ${_formatTime(startTime)}-${_formatTime(endTime)}');

              final timeRange =
                  '${_formatTime(startTime)}-${_formatTime(endTime)}';

              if (!newAvailableDays
                  .containsKey(dateKey.millisecondsSinceEpoch)) {
                newAvailableDays[dateKey.millisecondsSinceEpoch] = [];
              }

              // Evitar duplicados
              if (!newAvailableDays[dateKey.millisecondsSinceEpoch]!
                  .contains(timeRange)) {
                newAvailableDays[dateKey.millisecondsSinceEpoch]!
                    .add(timeRange);
              }
            }
          } catch (e) {
            // Error parsing slot
          }
        }
      }

      setState(() {
        availableDays = newAvailableDays;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar los horarios disponibles: $e';
        isLoading = false;
      });
    }
  }

  void _showFloatingMessage(String text, GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    _floatingMessage?.remove();
    _floatingMessage = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx + 10,
        top: offset.dy - 36,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_floatingMessage!);
    Future.delayed(Duration(milliseconds: 1200), () {
      _floatingMessage?.remove();
      _floatingMessage = null;
    });
  }

  void _scrollAndHighlight(
      GlobalKey key, String section, String message) async {
    final ctx = key.currentContext;
    if (ctx != null && _sheetScrollController != null) {
      final box = ctx.findRenderObject() as RenderBox;
      final offset =
          box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
      final scrollOffset = _sheetScrollController!.offset + offset.dy - 120;
      _sheetScrollController!.animateTo(
        scrollOffset,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() {
        if (section == 'materia') _highlightMateria = true;
        if (section == 'calendar') _highlightCalendar = true;
        if (section == 'hour') _highlightHour = true;
      });
      _showFloatingMessage(message, key);
      await Future.delayed(Duration(milliseconds: 900));
      setState(() {
        _highlightMateria = false;
        _highlightCalendar = false;
        _highlightHour = false;
      });
    }
  }

  List<String> _generateTimeSlots(String range) {
    final parts = range.split('-');
    if (parts.length != 2) return [];
    final start = _parseTime(parts[0]);
    final end = _parseTime(parts[1]);
    if (start == null || end == null) return [];
    List<String> slots = [];
    DateTime slot = start;

    // ✅ CORRECCIÓN: Generar intervalos de exactamente 20 minutos
    // La última hora debe permitir una sesión completa de 20 minutos
    while (slot.isBefore(end.subtract(Duration(minutes: 20))) ||
        slot.isAtSameMomentAs(end.subtract(Duration(minutes: 20)))) {
      slots.add(_formatTime(slot));
      slot = slot.add(Duration(minutes: 20));
    }
    return slots;
  }

  DateTime? _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final min = int.tryParse(parts[1]);
    if (hour == null || min == null) return null;
    final result = DateTime(0, 1, 1, hour, min);
    print('[BookingModal] 🔍 DEBUG - _parseTime: $hhmm -> $result');
    return result;
  }

  String _formatTime(DateTime t) {
    final result = t.hour.toString().padLeft(2, '0') +
        ':' +
        t.minute.toString().padLeft(2, '0');
    print('[BookingModal] 🔍 DEBUG - _formatTime: $t -> $result');
    return result;
  }

  bool _isTimeInRange(String range, String time) {
    final parts = range.split('-');
    if (parts.length != 2) return false;
    final start = _parseTime(parts[0]);
    final end = _parseTime(parts[1]);
    final t = _parseTime(time);
    if (start == null || end == null || t == null) return false;

    // ✅ DEBUG: Mostrar los tiempos para debugging
    print('[BookingModal] 🔍 DEBUG - _isTimeInRange: range=$range, time=$time');
    print('[BookingModal] 🔍 DEBUG - start=$start, end=$end, t=$t');

    // ✅ CORRECCIÓN: Validar que la hora permita una sesión completa de 20 minutos
    final result = (t.isAtSameMomentAs(start) || t.isAfter(start)) &&
        t.isBefore(end.subtract(Duration(minutes: 20)));

    print('[BookingModal] 🔍 DEBUG - _isTimeInRange result: $result');
    return result;
  }

  Future<void> _pickTime(String range) async {
    final now = TimeOfDay.now();
    final parts = range.split('-');
    final start = _parseTime(parts[0]);
    final end = _parseTime(parts[1]); // ✅ CAMBIO: Necesitamos el end time

    final initial =
        start != null ? TimeOfDay(hour: start.hour, minute: start.minute) : now;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          dialogBackgroundColor: AppColors.darkBlue,
          colorScheme: ColorScheme.dark(
            primary: AppColors.lightBlueColor,
            onPrimary: Colors.white,
            surface: AppColors.darkBlue,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final pickedStr = picked.hour.toString().padLeft(2, '0') +
          ':' +
          picked.minute.toString().padLeft(2, '0');
      if (_isTimeInRange(range, pickedStr)) {
        // ✅ CORRECCIÓN: Calcular hora de fin exactamente 20 minutos después
        final pickedDateTime = DateTime(0, 1, 1, picked.hour, picked.minute);
        final endDateTime = pickedDateTime.add(Duration(minutes: 20));
        final endTimeStr =
            '${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';

        final fullRange = '$pickedStr-$endTimeStr';
        print(
            '[BookingModal] 🔍 DEBUG - _pickTime: range=$range, picked=$pickedStr, endTimeStr=$endTimeStr, fullRange=$fullRange');
        setState(() => selectedHour = fullRange);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hora fuera del rango permitido.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateUtils.getDaysInMonth(currentMonth.year, currentMonth.month);
    final firstWeekday =
        DateTime(currentMonth.year, currentMonth.month, 1).weekday;
    final weekDays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        _sheetScrollController = scrollController;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.darkBlue,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Stack(
            children: [
              // Contenido principal scrollable
              CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _BookingHeaderDelegate(
                      child: Container(
                        padding: EdgeInsets.only(
                            left: 18, right: 8, top: 18, bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.darkBlue,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(widget.tutorImage),
                              radius: 26,
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                widget.tutorName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.white70),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                    floating: false,
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 6),
                          Text('Materia',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          AnimatedContainer(
                            key: _materiaKey,
                            duration: Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              border: _highlightMateria
                                  ? Border.all(
                                      color: AppColors.lightBlueColor, width: 3)
                                  : null,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: _highlightMateria
                                  ? [
                                      BoxShadow(
                                        color: AppColors.lightBlueColor
                                            .withOpacity(0.5),
                                        blurRadius: 18,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedSubject,
                                dropdownColor: AppColors.darkBlue,
                                borderRadius: BorderRadius.circular(12),
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                items: widget.subjects
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s,
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  setState(() => selectedSubject = v);
                                  Future.delayed(Duration(milliseconds: 100),
                                      () {
                                    if (_sheetScrollController != null) {
                                      _sheetScrollController!.animateTo(
                                        _sheetScrollController!
                                            .position.maxScrollExtent,
                                        duration: Duration(milliseconds: 400),
                                        curve: Curves.easeOut,
                                      );
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 18),
                          Text('Selecciona un día',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          AnimatedContainer(
                            key: _calendarKey,
                            duration: Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              border: _highlightCalendar
                                  ? Border.all(
                                      color: AppColors.lightBlueColor, width: 3)
                                  : null,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: _highlightCalendar
                                  ? [
                                      BoxShadow(
                                        color: AppColors.lightBlueColor
                                            .withOpacity(0.5),
                                        blurRadius: 18,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    AppColors.lightBlueColor.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 6),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.chevron_left,
                                            color: Colors.white70),
                                        onPressed: () {
                                          setState(() {
                                            currentMonth = DateTime(
                                                currentMonth.year,
                                                currentMonth.month - 1);
                                            selectedDay = null;
                                            selectedHour = null;
                                          });
                                          // Recargar slots para el nuevo mes
                                          _loadTutorAvailableSlots();
                                        },
                                      ),
                                      Text(
                                        '${_monthName(currentMonth.month)} ${currentMonth.year}',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.chevron_right,
                                            color: Colors.white70),
                                        onPressed: () {
                                          setState(() {
                                            currentMonth = DateTime(
                                                currentMonth.year,
                                                currentMonth.month + 1);
                                            selectedDay = null;
                                            selectedHour = null;
                                          });
                                          // Recargar slots para el nuevo mes
                                          _loadTutorAvailableSlots();
                                        },
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: weekDays
                                        .map((d) => Expanded(
                                              child: Center(
                                                  child: Text(d,
                                                      style: TextStyle(
                                                          color: Colors.white54,
                                                          fontWeight: FontWeight
                                                              .bold))),
                                            ))
                                        .toList(),
                                  ),
                                  SizedBox(height: 2),
                                  if (isLoading) ...[
                                    Container(
                                      height: 200,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                AppColors.lightBlueColor,
                                              ),
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              'Cargando horarios disponibles...',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ] else if (errorMessage != null) ...[
                                    Container(
                                      height: 200,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              color: Colors.red[300],
                                              size: 48,
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              errorMessage!,
                                              style: TextStyle(
                                                color: Colors.red[300],
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(height: 16),
                                            ElevatedButton(
                                              onPressed:
                                                  _loadTutorAvailableSlots,
                                              child: Text('Reintentar'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.lightBlueColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ] else if (availableDays.isEmpty) ...[
                                    Container(
                                      height: 200,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.schedule,
                                              color: Colors.white54,
                                              size: 48,
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              'No hay horarios disponibles\npara este mes',
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 7,
                                        mainAxisSpacing: 2,
                                        crossAxisSpacing: 2,
                                        childAspectRatio: 1.1,
                                      ),
                                      itemCount: daysInMonth + firstWeekday - 1,
                                      itemBuilder: (context, i) {
                                        if (i < firstWeekday - 1)
                                          return SizedBox();
                                        final day = i - firstWeekday + 2;
                                        final currentDate = DateTime(
                                            currentMonth.year,
                                            currentMonth.month,
                                            day);
                                        // Solo mostrar como disponible si es del mes actual y está en availableDays
                                        final isAvailable = availableDays
                                                .containsKey(currentDate
                                                    .millisecondsSinceEpoch) &&
                                            currentDate.month ==
                                                currentMonth.month &&
                                            currentDate.year ==
                                                currentMonth.year;
                                        final isSelected =
                                            selectedDay != null &&
                                                selectedDay!.day == day &&
                                                selectedDay!.month ==
                                                    currentMonth.month &&
                                                selectedDay!.year ==
                                                    currentMonth.year;
                                        return GestureDetector(
                                          onTap: isAvailable
                                              ? () {
                                                  setState(() {
                                                    selectedDay = DateTime(
                                                        currentMonth.year,
                                                        currentMonth.month,
                                                        day);
                                                    selectedHour = null;
                                                  });
                                                  print(
                                                      '[BookingModal] selectedDay=$day/${currentMonth.month}/${currentMonth.year}');
                                                  Future.delayed(
                                                      Duration(
                                                          milliseconds: 100),
                                                      () {
                                                    if (_sheetScrollController !=
                                                        null) {
                                                      _sheetScrollController!
                                                          .animateTo(
                                                        _sheetScrollController!
                                                            .position
                                                            .maxScrollExtent,
                                                        duration: Duration(
                                                            milliseconds: 400),
                                                        curve: Curves.easeOut,
                                                      );
                                                    }
                                                  });
                                                }
                                              : null,
                                          child: Container(
                                            margin: EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.lightBlueColor
                                                  : isAvailable
                                                      ? AppColors.lightBlueColor
                                                          .withOpacity(0.18)
                                                      : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: isSelected
                                                  ? Border.all(
                                                      color: Colors.white,
                                                      width: 2)
                                                  : null,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$day',
                                                style: TextStyle(
                                                  color: isAvailable
                                                      ? Colors.white
                                                      : Colors.white24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 18),
                          if (selectedDay != null &&
                              availableDays.containsKey(
                                  selectedDay!.millisecondsSinceEpoch)) ...[
                            Text('Selecciona una hora',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(height: 6),
                            AnimatedContainer(
                              key: _hourKey,
                              duration: Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              decoration: BoxDecoration(
                                border: _highlightHour
                                    ? Border.all(
                                        color: AppColors.lightBlueColor,
                                        width: 3)
                                    : null,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: _highlightHour
                                    ? [
                                        BoxShadow(
                                          color: AppColors.lightBlueColor
                                              .withOpacity(0.5),
                                          blurRadius: 18,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Builder(
                                builder: (context) {
                                  final slotsOrRanges = availableDays[
                                      selectedDay!.millisecondsSinceEpoch]!;
                                  final List<Widget> chips = [];
                                  bool hasRange = false;
                                  for (final slot in slotsOrRanges) {
                                    if (slot.contains('-')) {
                                      hasRange = true;
                                      final intervals =
                                          _generateTimeSlots(slot);
                                      chips.addAll(intervals.map((h) =>
                                          ChoiceChip(
                                            label: Text(h,
                                                style: TextStyle(
                                                    color: selectedHour == h
                                                        ? Colors.white
                                                        : AppColors
                                                            .lightBlueColor)),
                                            selected: selectedHour == h,
                                            selectedColor:
                                                AppColors.lightBlueColor,
                                            backgroundColor: AppColors
                                                .lightBlueColor
                                                .withOpacity(0.13),
                                            onSelected: (_) {
                                              // ✅ CORRECCIÓN: Guardar la hora en formato HH:MM-HH:MM
                                              // La hora de fin debe ser 20 minutos después de la hora seleccionada
                                              final selectedTime =
                                                  _parseTime(h);
                                              if (selectedTime != null) {
                                                final endTime = selectedTime
                                                    .add(Duration(minutes: 20));
                                                final endTimeStr =
                                                    _formatTime(endTime);
                                                final fullRange =
                                                    '$h-$endTimeStr';
                                                setState(() =>
                                                    selectedHour = fullRange);
                                                print(
                                                    '[BookingModal] selectedHour=$fullRange (hora + 20 min)');
                                              } else {
                                                setState(
                                                    () => selectedHour = h);
                                                print(
                                                    '[BookingModal] selectedHour=$h (fallback)');
                                              }
                                              print(
                                                  '[BookingModal] 🔍 DEBUG - Hora seleccionada: $h, rango original: $slot');
                                              print(
                                                  '[BookingModal] 🔍 DEBUG - selectedHour después del setState: $selectedHour');
                                              Future.delayed(
                                                  Duration(milliseconds: 100),
                                                  () {
                                                if (_sheetScrollController !=
                                                    null) {
                                                  _sheetScrollController!
                                                      .animateTo(
                                                    _sheetScrollController!
                                                        .position
                                                        .maxScrollExtent,
                                                    duration: Duration(
                                                        milliseconds: 400),
                                                    curve: Curves.easeOut,
                                                  );
                                                }
                                              });
                                            },
                                          )));
                                    } else {
                                      chips.add(ChoiceChip(
                                        label: Text(slot,
                                            style: TextStyle(
                                                color: selectedHour == slot
                                                    ? Colors.white
                                                    : AppColors
                                                        .lightBlueColor)),
                                        selected: selectedHour == slot,
                                        selectedColor: AppColors.lightBlueColor,
                                        backgroundColor: AppColors
                                            .lightBlueColor
                                            .withOpacity(0.13),
                                        onSelected: (_) {
                                          // ✅ CORRECCIÓN: Para horas únicas, también calcular hora de fin
                                          final selectedTime = _parseTime(slot);
                                          if (selectedTime != null) {
                                            final endTime = selectedTime
                                                .add(Duration(minutes: 20));
                                            final endTimeStr =
                                                _formatTime(endTime);
                                            final fullRange =
                                                '$slot-$endTimeStr';
                                            setState(
                                                () => selectedHour = fullRange);
                                            print(
                                                '[BookingModal] selectedHour=$fullRange (hora única + 20 min)');
                                          } else {
                                            setState(() => selectedHour = slot);
                                            print(
                                                '[BookingModal] selectedHour=$slot (fallback)');
                                          }
                                          Future.delayed(
                                              Duration(milliseconds: 100), () {
                                            if (_sheetScrollController !=
                                                null) {
                                              _sheetScrollController!.animateTo(
                                                _sheetScrollController!
                                                    .position.maxScrollExtent,
                                                duration:
                                                    Duration(milliseconds: 400),
                                                curve: Curves.easeOut,
                                              );
                                            }
                                          });
                                        },
                                      ));
                                    }
                                  }
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          // Calcula cuántos botones caben por fila según el ancho
                                          int buttonsPerRow =
                                              (constraints.maxWidth / 90)
                                                  .floor();
                                          if (buttonsPerRow < 2)
                                            buttonsPerRow = 2;
                                          final rows = <Widget>[];
                                          for (int i = 0;
                                              i < chips.length;
                                              i += buttonsPerRow) {
                                            rows.add(
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: chips
                                                    .skip(i)
                                                    .take(buttonsPerRow)
                                                    .map((chip) => Expanded(
                                                        child: Container(
                                                            margin: EdgeInsets
                                                                .symmetric(
                                                                    horizontal:
                                                                        4,
                                                                    vertical:
                                                                        6),
                                                            child: chip)))
                                                    .toList(),
                                              ),
                                            );
                                          }
                                          return Column(children: rows);
                                        },
                                      ),
                                      if (hasRange)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 10.0),
                                          child: Center(
                                            child: ElevatedButton.icon(
                                              onPressed: () async {
                                                final firstRange =
                                                    slotsOrRanges.firstWhere(
                                                        (s) => s.contains('-'));
                                                await _pickTime(firstRange);
                                                Future.delayed(
                                                    Duration(milliseconds: 100),
                                                    () {
                                                  if (_sheetScrollController !=
                                                      null) {
                                                    _sheetScrollController!
                                                        .animateTo(
                                                      _sheetScrollController!
                                                          .position
                                                          .maxScrollExtent,
                                                      duration: Duration(
                                                          milliseconds: 400),
                                                      curve: Curves.easeOut,
                                                    );
                                                  }
                                                });
                                              },
                                              icon: Icon(Icons.access_time,
                                                  color: Colors.white),
                                              label: Text('Elegir hora exacta',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.lightBlueColor,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            14)),
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 10,
                                                    horizontal: 18),
                                                elevation: 0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (selectedHour == null) ...[
                                        SizedBox(height: 24),
                                        Center(
                                          child: Column(
                                            children: [
                                              Icon(Icons.access_time,
                                                  color:
                                                      AppColors.lightBlueColor,
                                                  size: 38),
                                              SizedBox(height: 0),
                                              Text(
                                                'Selecciona una hora para continuar',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(height: 0),
                                            ],
                                          ),
                                        ),
                                      ],
                                      SizedBox(height: 90),
                                    ],
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 18),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Botón y texto de confirmación fijos abajo
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: AppColors.darkBlue,
                  padding: EdgeInsets.fromLTRB(18, 10, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectedDay != null && selectedHour != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event,
                                  color: AppColors.lightBlueColor, size: 20),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Reserva: ${selectedDay!.day.toString().padLeft(2, '0')}/${selectedDay!.month.toString().padLeft(2, '0')}/${selectedDay!.year} a las $selectedHour',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (selectedSubject != null &&
                                  selectedDay != null &&
                                  selectedHour != null)
                              ? () {
                                  // Cerrar el modal de agendar
                                  print(
                                      '[BookingModal] Reservar pressed with subject=$selectedSubject day=${selectedDay?.toIso8601String()} hour=$selectedHour');
                                  Navigator.pop(context);

                                  // ✅ DEBUG: Mostrar datos que se van a pasar
                                  print(
                                      '[BookingModal] 🔍 DEBUG - Datos a pasar a InstantTutoringScreen:');
                                  print(
                                      '[BookingModal] selectedDay: $selectedDay');
                                  print(
                                      '[BookingModal] selectedHour: $selectedHour');
                                  print(
                                      '[BookingModal] selectedHour type: ${selectedHour.runtimeType}');
                                  print(
                                      '[BookingModal] selectedSubject: $selectedSubject');

                                  // ✅ CAMBIO: Navegar a la vista instant tutoring con datos de reserva programada
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => Container(
                                      margin: EdgeInsets.only(top: 60),
                                      decoration: BoxDecoration(
                                        color: AppColors.darkBlue,
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(24)),
                                      ),
                                      child: InstantTutoringScreen(
                                        tutorName: widget.tutorName,
                                        tutorImage: widget.tutorImage,
                                        subjects: widget.subjects,
                                        selectedSubject: selectedSubject,
                                        tutorId: widget.tutorId,
                                        subjectId: widget.subjectId,
                                        // ✅ NUEVO: Pasar datos de reserva programada
                                        scheduledDate: selectedDay,
                                        scheduledTime: selectedHour,
                                        isScheduledBooking: true,
                                      ),
                                    ),
                                  );
                                }
                              : () {
                                  // --- NUEVO: Guía visual ---
                                  if (selectedSubject == null) {
                                    _scrollAndHighlight(_materiaKey, 'materia',
                                        'Debes seleccionar la materia');
                                  } else if (selectedDay == null) {
                                    _scrollAndHighlight(_calendarKey,
                                        'calendar', 'Debes seleccionar el día');
                                  } else if (selectedHour == null) {
                                    _scrollAndHighlight(_hourKey, 'hour',
                                        'Debes seleccionar la hora');
                                  }
                                },
                          icon: Icon(Icons.check_circle,
                              color: (selectedSubject != null &&
                                      selectedDay != null &&
                                      selectedHour != null)
                                  ? Colors.white
                                  : Colors.white54),
                          label: Text('Confirmar Reserva',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: (selectedSubject != null &&
                                        selectedDay != null &&
                                        selectedHour != null)
                                    ? Colors.white
                                    : Colors.white54,
                              )),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (selectedSubject != null &&
                                    selectedDay != null &&
                                    selectedHour != null)
                                ? AppColors.lightBlueColor
                                : AppColors.lightBlueColor.withOpacity(0.25),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: (selectedSubject != null &&
                                        selectedDay != null &&
                                        selectedHour != null)
                                    ? Colors.transparent
                                    : Colors.white24,
                                width: 1.2,
                              ),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _monthName(int m) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return months[m - 1];
  }
}

class _BookingHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _BookingHeaderDelegate({required this.child});

  @override
  double get minExtent => 80;
  @override
  double get maxExtent => 80;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
