import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_dropdown.dart';
import 'package:flutter_projects/helpers/slide_up_route.dart';
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
import 'package:flutter_projects/view/tutor/tutor_profile_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class SearchTutorsScreen extends StatefulWidget {
  final String? initialKeyword;
  final int? initialSubjectId;

  const SearchTutorsScreen({
    Key? key,
    this.initialKeyword,
    this.initialSubjectId,
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

    _pageController = PageController(initialPage: selectedIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_searchFilterContentKey.currentContext != null) {
        setState(() {
          _initialSearchFilterHeight =
              _searchFilterContentKey.currentContext!.size!.height;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose(); // 4. Liberar el FocusNode
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

      print('DEBUG - Llamando a la API verifiedTutors para la página inicial');
      print('DEBUG - keyword (materia): $keyword');
      final response = await getVerifiedTutors(
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
            'DEBUG - Llamando a la API verifiedTutors para la página ${currentPage + 1}');
        final response = await getVerifiedTutors(
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
    final maxScrollExtent = _scrollController.position.maxScrollExtent;

    // Detectar dirección del scroll
    final isScrollingUp = offset < _lastScrollOffset;
    final isScrollingDown = offset > _lastScrollOffset;

    // Calcular la velocidad del scroll para ajustar la animación
    final scrollDelta = (_lastScrollOffset - offset).abs();
    final animationSpeed =
        (scrollDelta * 0.1).clamp(0.05, 0.2); // Velocidad ajustada

    // Calcular las opacidades basadas en el scroll
    double newSearchOpacity = _searchOpacity;
    double newCounterOpacity = _counterOpacity;
    double newFiltersOpacity = _filtersOpacity;

    // PRIORIDAD: Si estamos en la parte superior, mostrar completamente
    if (offset <= 0) {
      newSearchOpacity = 1.0;
      newCounterOpacity = 1.0;
      newFiltersOpacity = 1.0;
    } else if (isScrollingUp) {
      // Al hacer scroll hacia arriba, mostrar secuencialmente con deslizamiento
      // Primero el buscador
      newSearchOpacity = (_searchOpacity + animationSpeed).clamp(0.0, 1.0);

      // Luego el contador (cuando el buscador esté casi visible)
      if (_searchOpacity > 0.3) {
        newCounterOpacity = (_counterOpacity + animationSpeed).clamp(0.0, 1.0);
      }

      // Finalmente los filtros (cuando el contador esté casi visible)
      if (_counterOpacity > 0.3) {
        newFiltersOpacity = (_filtersOpacity + animationSpeed).clamp(0.0, 1.0);
      }
    } else if (isScrollingDown && offset > 0) {
      // Al hacer scroll hacia abajo, ocultar gradualmente
      // Los elementos se ocultan en orden inverso: filtros -> contador -> buscador

      // Los filtros se ocultan primero
      if (_filtersOpacity > 0.0) {
        newFiltersOpacity = (_filtersOpacity - animationSpeed).clamp(0.0, 1.0);
      }

      // Luego el contador (cuando los filtros estén casi ocultos)
      if (_filtersOpacity < 0.3) {
        newCounterOpacity = (_counterOpacity - animationSpeed).clamp(0.0, 1.0);
      }

      // Finalmente el buscador (cuando el contador esté casi oculto)
      if (_counterOpacity < 0.3) {
        newSearchOpacity = (_searchOpacity - animationSpeed).clamp(0.0, 1.0);
      }
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

    // Lógica para cargar más tutores (paginación infinita)
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
            // Filtros
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: filtersHeight * _filtersOpacity,
              transform: Matrix4.translationValues(0,
                  _filtersOpacity < 1.0 ? -50 * (1 - _filtersOpacity) : 0, 0),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _filtersOpacity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 5, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSortOption,
                              hint: Text('Ordenar por',
                                  style: AppTextStyles.body.copyWith(
                                      color:
                                          AppColors.whiteColor.withOpacity(0.7),
                                      fontSize: 14)),
                              icon: Icon(Icons.arrow_drop_down,
                                  color: AppColors.whiteColor.withOpacity(0.7),
                                  size: 20),
                              dropdownColor: AppColors.blurprimary,
                              borderRadius: BorderRadius.circular(15.0),
                              style: AppTextStyles.body.copyWith(
                                  color: AppColors.whiteColor, fontSize: 14),
                              isExpanded: true,
                              items: _sortOptions.map((String value) {
                                bool isLastOfGroup = value == 'Nombre (Z-A)';
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    decoration: BoxDecoration(
                                      border: isLastOfGroup
                                          ? Border(
                                              bottom: BorderSide(
                                                  color: AppColors.navbar
                                                      .withOpacity(0.2),
                                                  width: 1))
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          value.contains('(A-Z)')
                                              ? Icons.arrow_downward
                                              : Icons.arrow_upward,
                                          size: 18,
                                          color: AppColors.whiteColor
                                              .withOpacity(0.7),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(value),
                                      ],
                                    ),
                                  ),
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
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.orangeprimary,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.orangeprimary.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: SvgPicture.asset(
                            AppImages.filterIcon,
                            color: AppColors.whiteColor,
                            width: 18,
                            height: 18,
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
                                ),
                              ),
                            );
                          },
                          onAcceptPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Reservar con ${profile['full_name'] ?? 'Tutor'}')),
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
            // Barra flotante
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _CustomBubbleNavBar(
                currentIndex: selectedIndex,
                onTap: _onItemTapped,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomBubbleNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _CustomBubbleNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = [
      Icons.search_outlined,
      Icons.calendar_today_outlined,
      Icons.person_outline,
    ];

    return Container(
      height: 60,
      margin: EdgeInsets.symmetric(
          horizontal: 60, vertical: 24), // Barra mucho más estrecha
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.navbar,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.navbar.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navbar
                .withOpacity(0.5), // Sombra a juego con el nuevo color
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double barWidth = constraints.maxWidth;
          final double itemWidth = barWidth / navItems.length;
          const double circleDiameter = 48.0;
          final double indicatorLeft = (currentIndex * itemWidth) +
              (itemWidth / 2) -
              (circleDiameter / 2);

          return Stack(
            alignment: Alignment.center,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.elasticOut,
                left: indicatorLeft,
                top: (60 - circleDiameter) / 2,
                child: Container(
                  width: circleDiameter,
                  height: circleDiameter,
                  decoration: BoxDecoration(
                    color: AppColors.orangeprimary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.orangeprimary.withOpacity(0.6),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
              ),
              Row(
                children: List.generate(navItems.length, (index) {
                  final bool isSelected = currentIndex == index;
                  return GestureDetector(
                    onTap: () => onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: itemWidth,
                      height: 60,
                      child: Icon(
                        navItems[index],
                        color: isSelected
                            ? Colors.white
                            : AppColors.whiteColor.withOpacity(0.7),
                        size: 24,
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
