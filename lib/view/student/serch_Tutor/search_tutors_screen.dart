import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/helpers/slide_up_route.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/components/login_required_alert.dart';
import 'package:flutter_projects/view/components/skeleton/tutor_card_skeleton.dart';
import 'package:flutter_projects/view/student/serch_Tutor/widgets/tutor_card.dart';
import 'package:flutter_projects/view/student/profile_screen_student.dart';
import 'package:flutter_projects/view/tutor/component/filter_turtor_bottom_sheet.dart';
import 'package:flutter_projects/view/student/services/text_normalization.dart';
import 'package:flutter_projects/view/student/serch_Tutor/services/sort_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/view/tutor/tutor_profile_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_projects/view/tutor/instant_tutoring_screen.dart';
import 'package:flutter_projects/view/tutor/student_calendar_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_projects/view/tutor/student_history_screen.dart';
import 'package:flutter_projects/view/components/main_header.dart';
import 'package:flutter_projects/view/student/reservations/widgets/booking_modal.dart';
// removed unused imports

// Normalización centralizada en view/student/services/text_normalization.dart

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
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> tutors = [];
  List<Map<String, dynamic>> originalTutors = [];
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
      if (!mounted) return; // Evitar setState después de disposed
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
    try {
      final sorted = sortTutors(
          originalTutors.isNotEmpty ? originalTutors : tutors, sortOption);
      setState(() {
        _selectedSortOption = sortOption;
        tutors = sorted;
      });
    } catch (e) {
      // noop
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Sin ordenar'),
                trailing: _selectedSortOption == null ||
                        _selectedSortOption == 'Sin ordenar'
                    ? Icon(Icons.check, color: AppColors.primaryGreen)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedSortOption = null;
                    tutors = List<Map<String, dynamic>>.from(
                        originalTutors.isNotEmpty ? originalTutors : tutors);
                  });
                  Navigator.pop(ctx);
                },
              ),
              ..._sortOptions.map((opt) => ListTile(
                    title: Text(opt),
                    trailing: _selectedSortOption == opt
                        ? Icon(Icons.check, color: AppColors.primaryGreen)
                        : null,
                    onTap: () {
                      _sortTutors(opt);
                      Navigator.pop(ctx);
                    },
                  ))
            ],
          ),
        );
      },
    );
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
    // Cancelar debounce timer para evitar setState después de dispose
    _debounce?.cancel();
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
        if (mounted) {
          setState(() {
            subjects = (response['data'] as List<dynamic>)
                .map((subject) => subject['name'].toString())
                .toList();
          });
        }
      }
    } catch (error) {}
  }

  Future<void> fetchCountries() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getCountries(token);
      final countriesData = response['data'];

      if (mounted) {
        setState(() {
          countries = countriesData.map<Map<String, dynamic>>((country) {
            return {
              'id': country['id'],
              'name': country['name'],
            };
          }).toList();
        });
      }
    } catch (e) {}
  }

  Future<void> fetchLanguages() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getLanguages(token);

      if (response.containsKey('data') && response['data'] is List) {
        if (mounted) {
          setState(() {
            languages = (response['data'] as List<dynamic>)
                .map((language) => language['name'].toString())
                .toList();
          });
        }
      }
    } catch (error) {}
  }

  Future<void> fetchSubjectGroups() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final response = await getSubjectsGroup(token);

      if (response.containsKey('data') && response['data'] is List) {
        if (mounted) {
          setState(() {
            subjectGroups = (response['data'] as List<dynamic>)
                .map((group) => group['name'].toString())
                .toList();
          });
        }
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
    if (mounted) {
      setState(() {
        isInitialLoading = true;
        if (tutors.isEmpty) {
          isInitialLoading = true;
        }
      });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      print(
          'DEBUG - Llamando a la API ${selectedMode == 'instantanea' ? 'availableTutors' : 'verifiedTutors'} para la página inicial');
      print('DEBUG - keyword (materia): $keyword');
      print('DEBUG - Modo seleccionado: $selectedMode');

      final response = selectedMode == 'instantanea'
          ? await getAvailableTutors(
              token,
              page: currentPage,
              keyword: keyword, // Usar keyword para buscar por materia
              tutorName:
                  tutorName, // Usar tutorName para buscar por nombre del tutor
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
              tutorName:
                  tutorName, // Usar tutorName para buscar por nombre del tutor
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

        if (mounted) {
          setState(() {
            tutors = fetchedTutors
                .map((tutor) => tutor as Map<String, dynamic>)
                .toList();
            // Guardar copia original para poder restaurar "Sin ordenar"
            originalTutors = List<Map<String, dynamic>>.from(tutors);

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
        }
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
      if (mounted) {
        setState(() {
          isInitialLoading = false;
          isRefreshing = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    if (mounted) {
      setState(() {
        isRefreshing = true;
        currentPage = 1;
        tutors.clear();
      });
    }
    await fetchInitialTutors();
    if (mounted) {
      setState(() {
        isRefreshing = false;
      });
    }
  }

  void _loadMoreTutors() async {
    print(
        'DEBUG - Intentando cargar más tutores. Página actual: $currentPage, Total páginas: $totalPages, Tutores actuales: ${tutors.length}');

    if (!isLoading && tutors.length < 100) {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

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
            if (mounted) {
              setState(() {
                tutors.addAll(tutorsList
                    .map((item) => item as Map<String, dynamic>)
                    .toList());
                // Mantener copia original también
                originalTutors.addAll(tutorsList
                    .map((item) => item as Map<String, dynamic>)
                    .toList());
                final paginationData = data['pagination'] ?? data;
                currentPage = paginationData['currentPage'] ?? currentPage + 1;
                totalPages = paginationData['totalPages'] ?? totalPages;
                totalTutors = paginationData['total'] ?? totalTutors;
                print(
                    'DEBUG - Tutores cargados exitosamente. Nuevo total: ${tutors.length} de $totalTutors');
              });
            }
          } else {
            print(
                'DEBUG - No se encontraron más tutores en la página ${currentPage + 1}');
          }
        }
      } catch (e) {
        print('Error loading more tutors: $e');
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
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
          if (mounted) {
            setState(() {
              this.selectedGroupId = groupId;
              this.tutorName = tutorName;
              this._minCourses = minCourses;
              this._minRating = minRating;

              currentPage = 1;
              tutors.clear();
              isInitialLoading = true;
            });
          }
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
      if (mounted) {
        setState(() {
          _showBottomBar = false;
        });
      }
    } else if (direction == ScrollDirection.forward && !_showBottomBar) {
      if (mounted) {
        setState(() {
          _showBottomBar = true;
        });
      }
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
      if (mounted) setState(() {});
    }

    _lastScrollOffset = offset;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreTutors();
    }
  }

  Widget _buildFiltrosYBuscador() {
    double searchHeight = 60.0;
    double counterHeight = 50.0;
    double filtersHeight = 55.0;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(30.0),
        bottomRight: Radius.circular(30.0),
      ),
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30.0),
            bottomRight: Radius.circular(30.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
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
                      hintText: 'Busca por materia o tutor...',
                      hintStyle: AppTextStyles.body.copyWith(
                          color: AppColors.greyColor.withOpacity(0.7)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 15),
                      prefixIcon: Icon(Icons.search,
                          color: AppColors.greyColor.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.blackColor),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          (keyword != null && keyword!.isNotEmpty)
                              ? '${totalTutors} tutores para "${keyword!}"'
                              : '${totalTutors} tutores encontrados',
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.whiteColor.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showSortOptions,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sort_rounded,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                _selectedSortOption ?? 'Ordenar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white70, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                  child: Container(
                    height: 45,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _buildFilterChip('Todos', true),
                          SizedBox(width: 8),
                          _buildFilterChip('Disponible', true),
                          SizedBox(width: 8),
                          _buildFilterChip('Mejor Valorado', false),
                          SizedBox(width: 8),
                          _buildFilterChip('Precio', false),
                        ],
                      ),
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
          color: isSelected
              ? AppColors.lightBlueColor
              : Colors.white.withOpacity(0.2),
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
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.9),
                    size: 16),
              if (mode == 'instantanea')
                Icon(Icons.flash_on,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.9),
                    size: 16),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color:
                      isSelected ? Colors.white : Colors.white.withOpacity(0.9),
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

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        // Implementar lógica de filtrado según el chip seleccionado
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryGreen : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
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
                          matchedSubjects:
                              (keyword != null && keyword!.trim().isNotEmpty)
                                  ? validSubjects
                                      .where((s) => normalize(s)
                                          .contains(normalize(keyword!)))
                                      .toList()
                                  : null,
                          searchKeyword: keyword,
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
        if (mounted) {
          setState(() {
            highResTutorImages = {
              for (var item in data)
                if (item['id'] != null && item['profile_image'] != null)
                  item['id'] as int: item['profile_image'] as String
            };
          });
        }
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
        backgroundColor: AppColors.backgroundColor,
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
                      ProfileScreen(showAppBar: true),
                    ],
                  ),
                ),
              ],
            ),
            // Barra de navegación gestionada por el scaffold padre (duplicado eliminado)
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
            offset: Offset(0, 5),
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
