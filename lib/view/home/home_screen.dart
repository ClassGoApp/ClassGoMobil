import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/components/video_widget.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/tutor/search_tutors_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_projects/view/tutor/tutor_profile_screen.dart';
import 'package:flutter_projects/helpers/slide_up_route.dart';
import 'package:flutter_projects/view/tutor/instant_tutoring_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:flutter_projects/helpers/pusher_service.dart';
import 'package:http/http.dart' as http;

// 1. Agrega RouteObserver para detectar cuando se vuelve a la pantalla principal
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, RouteAware {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  List<dynamic> _subjects = [];
  bool _isLoadingSubjects = false;
  bool _isFetchingMoreSubjects = false;
  int _currentPageSubjects = 1;
  bool _hasMoreSubjects = true;
  bool _isModalLoading = true;
  final int _subjectsPerPage =
      100; // Aumentado a 100 para cargar más materias de una vez

  // Variables para el manejo de videos y scroll
  final ScrollController _scrollController = ScrollController();
  bool _isManualPlay = false;
  Map<int, bool> _visibleItems = {};
  Map<int, Uint8List?> _thumbnailCache = {};
  List<dynamic> featuredTutors = [];
  bool isLoadingTutors = false;
  List<dynamic> alliances = [];
  bool isLoadingAlliances = false;
  VideoPlayerController? _activeController;
  bool _isVideoLoading = true;
  int _playingIndex = -1;
  bool _isCustomDrawerOpen = false;
  bool _isLeftDrawerOpen = false;

  // Define las rutas base
  final String baseImageUrl = 'https://classgoapp.com/storage/profile_images/';
  final String baseVideoUrl = 'https://classgoapp.com/storage/profile_videos/';

  // Declara un PageController en el estado:
  late final PageController _featuredTutorsPageController = PageController(
      viewportFraction: 1.0); // Aumentado para más a la izquierda

  // En el estado:
  final double tutorCardWidth = 280.0;
  final double tutorCardImageHeight = 150.0;
  final double tutorCardPadding = 6.0;
  late final ScrollController _featuredTutorsScrollController =
      ScrollController();

  final PageController _pageController = PageController(viewportFraction: 0.98);

  // Nuevo ScrollController para el carrusel de tutores
  late final ScrollController _tutorsScrollController = ScrollController();

  // 1. Declara el mapa para imágenes HD:
  Map<int, String> highResTutorImages = {};

  List<Map<String, dynamic>> _todaysBookings = [];
  bool _isLoadingBookings = true;

  AuthProvider? _authProvider;
  int? _lastFetchedUserId;

  Timer? _bookingsTimer;
  PusherChannelsFlutter? _pusher;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _tutorsScrollController.addListener(_onTutorsScroll);

    fetchFeaturedTutorsAndVerified();
    fetchAlliancesData();
    fetchInitialSubjects();
    fetchHighResTutorImages();
    // _initPusherService(); // Elimino inicialización local
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    if (_authProvider != authProvider) {
      _authProvider = authProvider;
      _checkAndFetchBookings();
      _authProvider!.addListener(_checkAndFetchBookings);
    }
    // Suscríbete al RouteObserver
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);

    // Inicializa PusherService global solo una vez
    final pusherService = Provider.of<PusherService>(context, listen: false);
    pusherService.init(onSlotBookingStatusChanged: (data) {
      try {
        print('DEBUG: Tipo de data: \\${data.runtimeType}');
        print('DEBUG: Contenido de data: \\${data}');
        if (data == null) {
          print('Error: Evento de Pusher recibido pero data es null');
          return;
        }
        Map<String, dynamic> parsedData;
        if (data is String) {
          parsedData = json.decode(data);
        } else if (data is Map<String, dynamic>) {
          parsedData = data;
        } else {
          print('Error: Formato de data no reconocido: \\${data.runtimeType}');
          return;
        }
        final slotBookingId = parsedData['slotBookingId'].toString();
        final newStatus = parsedData['newStatus'];
        bool updated = false;
        setState(() {
          for (var booking in _todaysBookings) {
            if (booking['id'].toString() == slotBookingId) {
              booking['status'] = newStatus;
              updated = true;
            }
          }
        });
        if (updated) {
          print('Actualizada la tutoría $slotBookingId a estado $newStatus');
          setState(() {});
        } else {
          print(
              'Tutoría con id $slotBookingId no encontrada en la lista actual. Actualizando lista completa...');
          _fetchTodaysBookings();
        }
        print(
            'Lista de tutorías tras actualizar: ' + _todaysBookings.toString());
      } catch (e, stack) {
        print('Error en el callback de Pusher: $e');
        print(stack);
      }
    });
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_checkAndFetchBookings);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    if (_activeController != null) {
      _activeController!.dispose();
    }
    _thumbnailCache.clear();
    _searchController.dispose();
    _debounce?.cancel();
    _featuredTutorsScrollController.dispose();
    _featuredTutorsPageController.dispose();
    _pageController.dispose();
    _tutorsScrollController.dispose();
    // PusherService().dispose(); // Elimino dispose local
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Refresca los bookings al volver a la pantalla principal
  @override
  void didPopNext() {
    _fetchTodaysBookings();
  }

  Future<void> _fetchTodaysBookings() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.userId;
      print('ID del usuario logueado para bookings: $userId');
      if (token != null && userId != null) {
        final bookings = await getUserBookingsById(token, userId);
        print('Tutorías obtenidas para el usuario: ${bookings.length}');
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        _todaysBookings = bookings.where((b) {
          if (b['status'] == 'Completado') return false;
          final start = DateTime.tryParse(b['start_time'] ?? '') ?? now;
          return start.year == today.year &&
              start.month == today.month &&
              start.day == today.day;
        }).toList();
        print('Tutorías filtradas para hoy: ${_todaysBookings.length}');
      }
    } catch (e) {
      print('Error al obtener tutorías del usuario: $e');
      _todaysBookings = [];
    }
    setState(() {
      _isLoadingBookings = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_pattern.png', // Cambia la ruta si tu asset es diferente
              fit: BoxFit.cover,
            ),
          ),
          // Main content (ScrollView)
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left menu icon
                        Builder(
                          builder: (context) => InkWell(
                            onTap: () {
                              setState(() {
                                _isLeftDrawerOpen =
                                    !_isLeftDrawerOpen; // Toggle left drawer state
                                _isCustomDrawerOpen =
                                    false; // Close right drawer if open
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.menu,
                                  color: Colors.white,
                                  size:
                                      26), // Adjusted size to match person icon
                            ),
                          ),
                        ),
                        Image.asset(
                          'assets/images/logo_classgo.png',
                          height: 38, // Ajusta el tamaño según tu diseño
                        ),
                        // Right person icon
                        Builder(
                          builder: (context) => InkWell(
                            onTap: () {
                              setState(() {
                                _isCustomDrawerOpen =
                                    !_isCustomDrawerOpen; // Toggle right drawer state
                                _isLeftDrawerOpen =
                                    false; // Close left drawer if open
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.person_outline,
                                  color: Colors.white,
                                  size: 26), // Adjusted size to match menu icon
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Mensaje principal, menú de opciones e imagen
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        const Text(
                          'Aprende con\nTutorías en Línea',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 24),
                        // --- BANNER DE TUTORÍAS PRÓXIMAS/EN VIVO ---
                        if (!_isLoadingBookings && _todaysBookings.isNotEmpty)
                          UpcomingSessionBanner(
                            key: ValueKey(_todaysBookings.isNotEmpty
                                ? _todaysBookings.first['id'].toString() +
                                    (_todaysBookings.first['status'] ?? '')
                                        .toString() +
                                    DateTime.now()
                                        .millisecondsSinceEpoch
                                        .toString()
                                : DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString()),
                            bookings: List<Map<String, dynamic>>.from(
                                _todaysBookings),
                          ),
                        // --- FIN BANNER ---
                        // Barra de búsqueda principal (como en Yango)
                        GestureDetector(
                          onTap: () {
                            _showSearchModal();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.search,
                                    color: Colors.white, size: 28),
                                SizedBox(width: 12),
                                Text(
                                  '¿Qué materia necesitas?',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 18),
                                ),
                                Spacer(),
                                Icon(Icons.arrow_forward_ios,
                                    color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        // Menú de opciones estilo Yango
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Builder(
                              builder: (mainContext) => _buildMenuOption(
                                context,
                                icon: Icons
                                    .flash_on, // Ícono para "Tutor al Instante"
                                label: 'Tutor\nal Instante',
                                onTap: () async {
                                  // Espera a que se precarguen las materias si aún no están listas
                                  if (_subjects.isEmpty && _isLoadingSubjects) {
                                    await Future.doWhile(() async {
                                      await Future.delayed(
                                          Duration(milliseconds: 100));
                                      return _isLoadingSubjects;
                                    });
                                  }
                                  await showModalBottomSheet(
                                    context: mainContext,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) {
                                      final TextEditingController
                                          searchController =
                                          TextEditingController();
                                      String search = '';
                                      // Inicializar con las materias precargadas
                                      List<dynamic> filteredSubjects =
                                          List<dynamic>.from(_subjects);
                                      bool isSearchingAPI = false;
                                      return StatefulBuilder(
                                        builder: (context, setModalState) {
                                          // Filtrar materias localmente primero
                                          List<dynamic> displaySubjects =
                                              filteredSubjects
                                                  .where((s) => (s['name'] ??
                                                          '')
                                                      .toLowerCase()
                                                      .contains(
                                                          search.toLowerCase()))
                                                  .toList();

                                          return SafeArea(
                                            child: Container(
                                              constraints: BoxConstraints(
                                                maxHeight:
                                                    MediaQuery.of(context)
                                                            .size
                                                            .height *
                                                        0.85,
                                                minHeight:
                                                    MediaQuery.of(context)
                                                            .size
                                                            .height *
                                                        0.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.darkBlue,
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(24),
                                                  topRight: Radius.circular(24),
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (search.trim().isEmpty)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 18,
                                                              left: 12,
                                                              right: 12,
                                                              bottom: 8),
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppColors
                                                              .lightBlueColor
                                                              .withOpacity(
                                                                  0.18),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(18),
                                                          border: Border.all(
                                                              color: AppColors
                                                                  .lightBlueColor,
                                                              width: 1.2),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: AppColors
                                                                  .lightBlueColor
                                                                  .withOpacity(
                                                                      0.10),
                                                              blurRadius: 12,
                                                              offset:
                                                                  Offset(0, 4),
                                                            ),
                                                          ],
                                                        ),
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 16,
                                                                vertical: 14),
                                                        child: Row(
                                                          children: [
                                                            Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: AppColors
                                                                    .lightBlueColor,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(10),
                                                              child: Icon(
                                                                  Icons
                                                                      .flash_on,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 28),
                                                            ),
                                                            SizedBox(width: 14),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    '¡Tutor al Instante!',
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          16,
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                      height:
                                                                          4),
                                                                  Text(
                                                                    'Elige una materia y conecta al momento con un tutor disponible.',
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .white
                                                                          .withOpacity(
                                                                              0.85),
                                                                      fontSize:
                                                                          13,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16.0),
                                                    child: TextField(
                                                      controller:
                                                          searchController,
                                                      autofocus: true,
                                                      decoration:
                                                          InputDecoration(
                                                        hintText:
                                                            'Busca tu materia...',
                                                        hintStyle: TextStyle(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    0.6)),
                                                        prefixIcon: Icon(
                                                            Icons.search,
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    0.6)),
                                                        filled: true,
                                                        fillColor: Colors.white
                                                            .withOpacity(0.1),
                                                        contentPadding:
                                                            EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        14),
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(30),
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),
                                                      ),
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                      onChanged: (value) {
                                                        if (_debounce
                                                                ?.isActive ??
                                                            false)
                                                          _debounce!.cancel();
                                                        _debounce = Timer(
                                                            const Duration(
                                                                milliseconds:
                                                                    300),
                                                            () async {
                                                          setModalState(() {
                                                            search = value;
                                                          });

                                                          // Si la búsqueda está vacía, mostrar materias precargadas
                                                          if (value
                                                              .trim()
                                                              .isEmpty) {
                                                            setModalState(() {
                                                              filteredSubjects =
                                                                  List<dynamic>.from(
                                                                      _subjects);
                                                              isSearchingAPI =
                                                                  false;
                                                            });
                                                            return;
                                                          }

                                                          // Primero filtrar localmente
                                                          List<dynamic> localResults = _subjects
                                                              .where((s) => (s[
                                                                          'name'] ??
                                                                      '')
                                                                  .toLowerCase()
                                                                  .contains(value
                                                                      .toLowerCase()))
                                                              .toList();

                                                          // Si hay suficientes resultados locales, usarlos
                                                          if (localResults
                                                                  .length >=
                                                              3) {
                                                            setModalState(() {
                                                              filteredSubjects =
                                                                  localResults;
                                                              isSearchingAPI =
                                                                  false;
                                                            });
                                                          } else {
                                                            // Si no hay suficientes resultados, buscar en API
                                                            setModalState(() {
                                                              isSearchingAPI =
                                                                  true;
                                                            });
                                                            try {
                                                              final response =
                                                                  await getAllSubjects(
                                                                null,
                                                                page: 1,
                                                                perPage: 100,
                                                                keyword: value,
                                                              );
                                                              List<dynamic>
                                                                  newSubjects =
                                                                  [];
                                                              if (response !=
                                                                      null &&
                                                                  response.containsKey(
                                                                      'data')) {
                                                                final responseData =
                                                                    response[
                                                                        'data'];
                                                                if (responseData
                                                                        is Map<
                                                                            String,
                                                                            dynamic> &&
                                                                    responseData
                                                                        .containsKey(
                                                                            'data')) {
                                                                  newSubjects =
                                                                      responseData[
                                                                          'data'];
                                                                }
                                                              }
                                                              setModalState(() {
                                                                filteredSubjects =
                                                                    newSubjects;
                                                                isSearchingAPI =
                                                                    false;
                                                              });
                                                            } catch (e) {
                                                              setModalState(() {
                                                                filteredSubjects =
                                                                    localResults; // Usar resultados locales como fallback
                                                                isSearchingAPI =
                                                                    false;
                                                              });
                                                            }
                                                          }
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: isSearchingAPI
                                                        ? Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                                    color: Colors
                                                                        .white))
                                                        : displaySubjects
                                                                .isEmpty
                                                            ? Center(
                                                                child: Text(
                                                                    'No se encontraron materias',
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .white70)))
                                                            : ListView
                                                                .separated(
                                                                itemCount:
                                                                    displaySubjects
                                                                        .length,
                                                                separatorBuilder: (context,
                                                                        index) =>
                                                                    Divider(
                                                                        color: Colors
                                                                            .white
                                                                            .withOpacity(
                                                                                0.1),
                                                                        height:
                                                                            1,
                                                                        indent:
                                                                            16,
                                                                        endIndent:
                                                                            16),
                                                                itemBuilder:
                                                                    (context,
                                                                        index) {
                                                                  final subject =
                                                                      displaySubjects[
                                                                          index];
                                                                  return ListTile(
                                                                    title: Text(
                                                                        subject['name'] ??
                                                                            'Materia desconocida',
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.white)),
                                                                    onTap:
                                                                        () async {
                                                                      Navigator.pop(
                                                                          context); // Cierra el modal de selección
                                                                      final subjectName =
                                                                          subject['name'] ??
                                                                              '';
                                                                      final subjectId =
                                                                          subject[
                                                                              'id'];
                                                                      print(
                                                                          'DEBUG: subjectId seleccionado: $subjectId, subjectName: $subjectName');
                                                                      final authProvider = Provider.of<
                                                                              AuthProvider>(
                                                                          mainContext,
                                                                          listen:
                                                                              false);
                                                                      final token =
                                                                          authProvider
                                                                              .token;
                                                                      // Mostrar loader
                                                                      showDialog(
                                                                        context:
                                                                            mainContext,
                                                                        barrierDismissible:
                                                                            false,
                                                                        builder:
                                                                            (context) =>
                                                                                Center(
                                                                          child:
                                                                              Material(
                                                                            color:
                                                                                Colors.transparent,
                                                                            child:
                                                                                Container(
                                                                              width: MediaQuery.of(context).size.width * 0.82,
                                                                              padding: EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                                                                              decoration: BoxDecoration(
                                                                                gradient: LinearGradient(
                                                                                  colors: [
                                                                                    AppColors.darkBlue,
                                                                                    AppColors.blurprimary
                                                                                  ],
                                                                                  begin: Alignment.topLeft,
                                                                                  end: Alignment.bottomRight,
                                                                                ),
                                                                                borderRadius: BorderRadius.circular(24),
                                                                                boxShadow: [
                                                                                  BoxShadow(
                                                                                    color: Colors.black.withOpacity(0.18),
                                                                                    blurRadius: 32,
                                                                                    offset: Offset(0, 12),
                                                                                  ),
                                                                                ],
                                                                                border: Border.all(color: Colors.white.withOpacity(0.10)),
                                                                              ),
                                                                              child: Column(
                                                                                mainAxisSize: MainAxisSize.min,
                                                                                children: [
                                                                                  // Icono animado con glow
                                                                                  Container(
                                                                                    decoration: BoxDecoration(
                                                                                      shape: BoxShape.circle,
                                                                                      boxShadow: [
                                                                                        BoxShadow(
                                                                                          color: AppColors.orangeprimary.withOpacity(0.5),
                                                                                          blurRadius: 24,
                                                                                          spreadRadius: 2,
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                    child: CircleAvatar(
                                                                                      radius: 32,
                                                                                      backgroundColor: AppColors.orangeprimary.withOpacity(0.12),
                                                                                      child: Icon(Icons.flash_on, color: AppColors.orangeprimary, size: 28),
                                                                                    ),
                                                                                  ),
                                                                                  SizedBox(height: 24),
                                                                                  Text(
                                                                                    'Buscando el mejor tutor para ti',
                                                                                    style: TextStyle(
                                                                                      color: Colors.white,
                                                                                      fontWeight: FontWeight.bold,
                                                                                      fontSize: 19,
                                                                                    ),
                                                                                    textAlign: TextAlign.center,
                                                                                  ),
                                                                                  SizedBox(height: 14),
                                                                                  Text(
                                                                                    'Estamos conectando con tutores verificados de la materia seleccionada. Esto puede tomar unos segundos.',
                                                                                    style: TextStyle(
                                                                                      color: Colors.white.withOpacity(0.85),
                                                                                      fontSize: 15,
                                                                                    ),
                                                                                    textAlign: TextAlign.center,
                                                                                  ),
                                                                                  SizedBox(height: 24),
                                                                                  _AnimatedDots(),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        useRootNavigator:
                                                                            true,
                                                                      );
                                                                      try {
                                                                        print(
                                                                            'DEBUG: Llamando a getVerifiedTutors con subjectId: $subjectId');
                                                                        final response =
                                                                            await getVerifiedTutors(
                                                                          token,
                                                                          perPage:
                                                                              50,
                                                                          subjectId:
                                                                              subjectId,
                                                                        );
                                                                        print(
                                                                            'DEBUG: Respuesta de getVerifiedTutors: $response');
                                                                        List<dynamic>
                                                                            tutors =
                                                                            [];
                                                                        if (response
                                                                            .containsKey('data')) {
                                                                          final data =
                                                                              response['data'];
                                                                          if (data
                                                                              is List) {
                                                                            tutors =
                                                                                data;
                                                                          } else if (data is Map &&
                                                                              data.containsKey(
                                                                                  'data') &&
                                                                              data['data']
                                                                                  is List) {
                                                                            tutors =
                                                                                data['data'];
                                                                          } else if (data is Map &&
                                                                              data.containsKey('list') &&
                                                                              data['list'] is List) {
                                                                            tutors =
                                                                                data['list'];
                                                                          }
                                                                        }
                                                                        print(
                                                                            'DEBUG: Tutores encontrados: ${tutors.length}');
                                                                        Navigator.of(mainContext,
                                                                                rootNavigator: true)
                                                                            .pop(); // Cierra el loader
                                                                        if (tutors
                                                                            .isNotEmpty) {
                                                                          final randomTutor =
                                                                              (tutors..shuffle()).first;
                                                                          final profile =
                                                                              randomTutor['profile'] ?? {};
                                                                          final tutorName =
                                                                              profile['full_name'] ?? 'Sin nombre';
                                                                          final tutorImage = highResTutorImages != null && highResTutorImages[randomTutor['id']] != null
                                                                              ? highResTutorImages[randomTutor['id']]
                                                                              : profile['image'] ?? '';
                                                                          final validSubjects = (randomTutor['subjects'] as List)
                                                                              .where((s) => s['status'] == 'active' && s['deleted_at'] == null)
                                                                              .map((s) => s['name'].toString())
                                                                              .toList();
                                                                          showModalBottomSheet(
                                                                            context:
                                                                                mainContext,
                                                                            isScrollControlled:
                                                                                true,
                                                                            backgroundColor:
                                                                                Colors.transparent,
                                                                            builder: (context) =>
                                                                                InstantTutoringScreen(
                                                                              tutorName: tutorName,
                                                                              tutorImage: tutorImage,
                                                                              subjects: validSubjects,
                                                                              selectedSubject: subjectName, // <-- Pasar la materia seleccionada
                                                                              tutorId: randomTutor['id'],
                                                                              subjectId: subjectId,
                                                                            ),
                                                                          );
                                                                        } else {
                                                                          print(
                                                                              'DEBUG: No hay tutores disponibles para esta materia.');
                                                                          await showDialog(
                                                                            context:
                                                                                mainContext,
                                                                            barrierDismissible:
                                                                                true,
                                                                            builder: (context) =>
                                                                                Center(
                                                                              child: Material(
                                                                                color: Colors.transparent,
                                                                                child: Container(
                                                                                  width: MediaQuery.of(context).size.width * 0.85,
                                                                                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                                                                                  decoration: BoxDecoration(
                                                                                    color: AppColors.darkBlue,
                                                                                    borderRadius: BorderRadius.circular(24),
                                                                                    boxShadow: [
                                                                                      BoxShadow(
                                                                                        color: Colors.black.withOpacity(0.18),
                                                                                        blurRadius: 32,
                                                                                        offset: Offset(0, 12),
                                                                                      ),
                                                                                    ],
                                                                                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                                                                                  ),
                                                                                  child: Column(
                                                                                    mainAxisSize: MainAxisSize.min,
                                                                                    children: [
                                                                                      Icon(Icons.sentiment_dissatisfied_rounded, color: AppColors.orangeprimary, size: 54),
                                                                                      SizedBox(height: 18),
                                                                                      Text(
                                                                                        '¡Ups! No hay tutores disponibles',
                                                                                        style: TextStyle(
                                                                                          color: Colors.white,
                                                                                          fontWeight: FontWeight.bold,
                                                                                          fontSize: 20,
                                                                                        ),
                                                                                        textAlign: TextAlign.center,
                                                                                      ),
                                                                                      SizedBox(height: 12),
                                                                                      Text(
                                                                                        'Por el momento no hay tutores disponibles para la materia seleccionada. Puedes intentarlo más tarde o elegir otra materia.',
                                                                                        style: TextStyle(
                                                                                          color: Colors.white.withOpacity(0.85),
                                                                                          fontSize: 15,
                                                                                        ),
                                                                                        textAlign: TextAlign.center,
                                                                                      ),
                                                                                      SizedBox(height: 28),
                                                                                      SizedBox(
                                                                                        width: double.infinity,
                                                                                        child: ElevatedButton.icon(
                                                                                          onPressed: () => Navigator.of(context).pop(),
                                                                                          icon: Icon(Icons.close, color: Colors.white),
                                                                                          label: Text('Cerrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                                                          style: ElevatedButton.styleFrom(
                                                                                            backgroundColor: AppColors.orangeprimary,
                                                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                                                            padding: EdgeInsets.symmetric(vertical: 14),
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          );
                                                                        }
                                                                      } catch (e) {
                                                                        Navigator.of(mainContext,
                                                                                rootNavigator: true)
                                                                            .pop(); // Cierra el loader
                                                                        print(
                                                                            'DEBUG: Error al buscar tutores: $e');
                                                                        ScaffoldMessenger.of(mainContext)
                                                                            .showSnackBar(
                                                                          SnackBar(
                                                                            content:
                                                                                Text('Error al buscar tutores: $e'),
                                                                          ),
                                                                        );
                                                                      }
                                                                    },
                                                                  );
                                                                },
                                                              ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            _buildMenuOption(
                              context,
                              icon:
                                  Icons.calendar_today, // Ícono para "Agendar"
                              label: 'Agendar\nTutoría',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SearchTutorsScreen(
                                        initialMode: 'agendar'),
                                  ),
                                );
                              },
                            ),
                            _buildMenuOption(
                              context,
                              icon: Icons.explore, // Ícono para "Explorar"
                              label: 'Explorar\nTutores',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SearchTutorsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Mascota/Ilustración animada (GIF)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: SizedBox(
                        height: 300, // Más grande
                        child: Image.asset(
                          'assets/images/ave_animada.gif',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  // Tutores destacados
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Color(0xFF062B3A),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tutores destacados',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Conoce a Nuestros Tutores\nCuidadosamente Seleccionados',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 12),
                          SizedBox(
                            height: MediaQuery.of(context).size.height *
                                0.38, // Antes 0.44, ajusto para tarjetas más compactas
                            child: PageView.builder(
                              controller: PageController(
                                viewportFraction:
                                    (tutorCardWidth + tutorCardPadding * 2) /
                                        MediaQuery.of(context).size.width,
                              ),
                              itemCount: featuredTutors.length,
                              itemBuilder: (context, index) {
                                final tutor = featuredTutors[index];
                                final profile = tutor['profile'] ?? {};
                                final name =
                                    profile['full_name'] ?? 'Sin nombre';
                                final subjects = tutor['subjects'];
                                final validSubjects = (subjects as List)
                                    .where((s) =>
                                        s['status'] == 'active' &&
                                        s['deleted_at'] == null)
                                    .map((s) => s['name'].toString())
                                    .toList();
                                final rating = double.tryParse(
                                        tutor['avg_rating']?.toString() ??
                                            '0.0') ??
                                    0.0;
                                final imagePath = profile['image'] ?? '';
                                final videoPath = profile['intro_video'] ?? '';
                                final imageUrl =
                                    highResTutorImages[tutor['id']] ??
                                        getFullUrl(imagePath, baseImageUrl);
                                final videoUrl =
                                    getFullUrl(videoPath, baseVideoUrl);
                                final completed =
                                    tutor['completed_courses_count'] ?? 0;
                                final total = 18;
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: tutorCardPadding),
                                  child: Container(
                                    width: tutorCardWidth,
                                    margin: EdgeInsets.zero,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 12,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Container(
                                              width: tutorCardWidth,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                border: Border.all(
                                                    color: AppColors
                                                        .lightBlueColor,
                                                    width: 4),
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                              ),
                                              child: Column(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(20),
                                                      topRight:
                                                          Radius.circular(20),
                                                    ),
                                                    child: SizedBox(
                                                      width: double.infinity,
                                                      height:
                                                          tutorCardImageHeight,
                                                      child: _playingIndex ==
                                                                  index &&
                                                              _activeController !=
                                                                  null
                                                          ? (_isVideoLoading
                                                              ? Positioned.fill(
                                                                  child: Center(
                                                                    child:
                                                                        CircularProgressIndicator(
                                                                      color: AppColors
                                                                          .lightBlueColor,
                                                                      strokeWidth:
                                                                          4,
                                                                    ),
                                                                  ),
                                                                )
                                                              : Stack(
                                                                  children: [
                                                                    SizedBox
                                                                        .expand(
                                                                      child: VideoPlayer(
                                                                          _activeController!),
                                                                    ),
                                                                    Positioned
                                                                        .fill(
                                                                      child:
                                                                          Material(
                                                                        color: Colors
                                                                            .transparent,
                                                                        child:
                                                                            InkWell(
                                                                          onTap: () =>
                                                                              _handleVideoTap(index),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ))
                                                          : FittedBox(
                                                              fit: BoxFit.cover,
                                                              clipBehavior:
                                                                  Clip.hardEdge,
                                                              child: SizedBox(
                                                                width:
                                                                    tutorCardWidth,
                                                                height:
                                                                    tutorCardImageHeight,
                                                                child:
                                                                    _buildVideoThumbnail(
                                                                        videoUrl,
                                                                        index),
                                                              ),
                                                            ),
                                                    ),
                                                  ),
                                                  Container(
                                                    width: double.infinity,
                                                    height: 28, // más compacto
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                          .lightBlueColor,
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        bottomLeft:
                                                            Radius.circular(20),
                                                        bottomRight:
                                                            Radius.circular(20),
                                                      ),
                                                    ),
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    padding: EdgeInsets.only(
                                                        left: 65, right: 8),
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        Navigator.of(context)
                                                            .push(
                                                          SlideUpRoute(
                                                            page:
                                                                TutorProfileScreen(
                                                              tutorId: tutor[
                                                                      'id']
                                                                  .toString(),
                                                              tutorName: profile[
                                                                      'full_name'] ??
                                                                  'Sin nombre',
                                                              tutorImage: highResTutorImages[
                                                                      tutor[
                                                                          'id']] ??
                                                                  getFullUrl(
                                                                      profile['image'] ??
                                                                          '',
                                                                      baseImageUrl),
                                                              tutorVideo: profile[
                                                                      'intro_video'] ??
                                                                  '',
                                                              description: profile[
                                                                      'description'] ??
                                                                  'Sin descripción',
                                                              rating: double.tryParse(
                                                                      tutor['avg_rating']
                                                                              ?.toString() ??
                                                                          '0.0') ??
                                                                  0.0,
                                                              subjects:
                                                                  validSubjects,
                                                              completedCourses:
                                                                  completed,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child: Text(
                                                        name,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Avatar sobrepuesto al borde inferior del video
                                            Positioned(
                                              top: tutorCardImageHeight -
                                                  24, // justo debajo del video
                                              left: 16,
                                              child: GestureDetector(
                                                onTap: () {
                                                  Navigator.of(context).push(
                                                    SlideUpRoute(
                                                      page: TutorProfileScreen(
                                                        tutorId: tutor['id']
                                                            .toString(),
                                                        tutorName: profile[
                                                                'full_name'] ??
                                                            'Sin nombre',
                                                        tutorImage: highResTutorImages[
                                                                tutor['id']] ??
                                                            getFullUrl(
                                                                profile['image'] ??
                                                                    '',
                                                                baseImageUrl),
                                                        tutorVideo: profile[
                                                                'intro_video'] ??
                                                            '',
                                                        description: profile[
                                                                'description'] ??
                                                            'Sin descripción',
                                                        rating: double.tryParse(
                                                                tutor['avg_rating']
                                                                        ?.toString() ??
                                                                    '0.0') ??
                                                            0.0,
                                                        subjects: validSubjects,
                                                        completedCourses:
                                                            completed,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: _buildAvatarWithShimmer(
                                                    imageUrl),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0, vertical: 4.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              // Indicador de materias
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 2.0,
                                                          bottom: 2.0),
                                                  child: Text(
                                                    'Materias que imparte',
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .lightBlueColor
                                                          .withOpacity(0.85),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Materias en chips
                                              SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: Row(
                                                  children: subjects
                                                      .map<Widget>((subject) =>
                                                          Container(
                                                            margin:
                                                                const EdgeInsets
                                                                    .only(
                                                                    right: 8),
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        10,
                                                                    vertical:
                                                                        4),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: AppColors
                                                                  .lightBlueColor
                                                                  .withOpacity(
                                                                      0.18),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                            ),
                                                            child: Text(
                                                              subject['name'] ??
                                                                  '',
                                                              style:
                                                                  const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ))
                                                      .toList(),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              // Cursos completados
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: AppColors
                                                      .lightBlueColor
                                                      .withOpacity(0.18),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(Icons.menu_book,
                                                        color: AppColors
                                                            .lightBlueColor,
                                                        size: 18),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      '$completed/$total cursos completados',
                                                      style: const TextStyle(
                                                        color: AppColors
                                                            .lightBlueColor,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              // Botón Empezar tutoría
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    showModalBottomSheet(
                                                      context: context,
                                                      isScrollControlled: true,
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      builder: (context) =>
                                                          InstantTutoringScreen(
                                                        tutorName: profile[
                                                                'full_name'] ??
                                                            'Sin nombre',
                                                        tutorImage: highResTutorImages[
                                                                tutor['id']] ??
                                                            getFullUrl(
                                                                profile['image'] ??
                                                                    '',
                                                                baseImageUrl),
                                                        subjects: validSubjects,
                                                        tutorId: tutor['id'],
                                                        subjectId: validSubjects
                                                                .isNotEmpty
                                                            ? 1
                                                            : 1, // Default subject ID
                                                      ),
                                                    );
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColors.orangeprimary,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16.0),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 6.0),
                                                    elevation: 0,
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      const Icon(
                                                          Icons
                                                              .play_circle_fill,
                                                          color: Colors.white,
                                                          size: 18),
                                                      const SizedBox(width: 8),
                                                      const Text(
                                                        'Empezar tutoría',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 18),
                          // Guía paso a paso
                          Text(
                            'Una guía paso a paso',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Desbloquea tu potencial con pasos sencillos',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                          SizedBox(height: 12),
                          SizedBox(
                            height: MediaQuery.of(context).size.height *
                                0.36, // Altura variable
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _StepCard(
                                  step: 'Paso 1',
                                  title: 'Inscríbete',
                                  description:
                                      'Crea tu cuenta rápidamente para comenzar a utilizar nuestra plataforma.',
                                  buttonText: 'Empezar',
                                  imageUrl:
                                      'https://classgoapp.com/storage/optionbuilder/uploads/927102-18-2025_1202amPASO_1.jpg',
                                ),
                                SizedBox(width: 18),
                                _StepCard(
                                  step: 'Paso 2',
                                  title: 'Encuentra un Tutor',
                                  description:
                                      'Busca y selecciona entre tutores calificados según tus necesidades.',
                                  buttonText: 'Buscar Ahora',
                                  imageUrl:
                                      'https://classgoapp.com/storage/optionbuilder/uploads/776302-18-2025_1203amPASO_2.jpg',
                                ),
                                SizedBox(width: 18),
                                _StepCard(
                                  step: 'Paso 3',
                                  title: 'Programar una Sesión',
                                  description:
                                      'Reserva fácilmente un horario conveniente para tu sesión.',
                                  buttonText: 'Empecemos',
                                  imageUrl:
                                      'https://classgoapp.com/storage/optionbuilder/uploads/229502-18-2025_1204amPASO_3.jpg',
                                ),
                                SizedBox(width: 18),
                                _StartJourneyCard(),
                                SizedBox(
                                    width:
                                        8), // Added SizedBox for spacing at the end
                              ],
                            ),
                          ),
                          SizedBox(height: 18),
                          // ¿Por qué elegirnos?
                          Text(
                            '¿Por qué Elegirnos?',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Por el acceso rápido, 24/7, a tutorías personalizadas que potencian tu aprendizaje',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Accede a sesiones cortas y prácticas, diseñadas por tutores expertos para ser tus pequeños salvavidas en el aprendizaje',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• Acceso 24/7',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14)),
                                Text('• Tutores Expertos',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14)),
                                Text('• Tarifas asequibles',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14)),
                              ],
                            ),
                          ),
                          SizedBox(height: 12), // Added SizedBox for spacing
                          Center(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFF9900),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 12),
                              ),
                              onPressed: () {
                                // TODO: Implement action for 'Comienza Ahora'
                              },
                              child: Text('Comienza Ahora',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          SizedBox(height: 18),
                          // Imagen de grupo (usa la imagen del paso 3)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              'https://classgoapp.com/storage/optionbuilder/uploads/229502-18-2025_1204amPASO_3.jpg',
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 18),
                          // Alianzas
                          Text('Alianzas',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          SizedBox(height: 10),
                          SizedBox(
                            height: 180,
                            child: isLoadingAlliances
                                ? Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.white))
                                : alliances.isEmpty
                                    ? Center(
                                        child: Text(
                                            'No hay alianzas disponibles',
                                            style:
                                                TextStyle(color: Colors.white)))
                                    : ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: alliances.length,
                                        separatorBuilder: (_, __) =>
                                            SizedBox(width: 10),
                                        itemBuilder: (context, index) {
                                          final alianza = alliances[index];
                                          final logoUrl =
                                              alianza['imagen'] ?? '';
                                          final name = alianza['titulo'] ?? '';
                                          final enlace =
                                              alianza['enlace'] ?? '';
                                          final color = Color(0xFF0B9ED9);
                                          return GestureDetector(
                                            onTap: () {
                                              if (enlace.isNotEmpty) {
                                                launchUrl(Uri.parse(enlace));
                                              }
                                            },
                                            child: _AllianceCard(
                                              logoUrl: logoUrl,
                                              name: name,
                                              color: color,
                                            ),
                                          );
                                        },
                                      ),
                          ),
                          SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Overlay to dismiss right drawer when tapping outside
          if (_isCustomDrawerOpen) // Existing overlay for the right drawer
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isCustomDrawerOpen = false;
                  });
                },
                child: Container(
                    color: Colors.black54), // Semi-transparent overlay
              ),
            ),
          // Custom Drawer Implementation (Right) - Existing
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: MediaQuery.of(context).padding.top,
            right: _isCustomDrawerOpen
                ? 0
                : -(MediaQuery.of(context).size.width * 0.7),
            width: MediaQuery.of(context).size.width * 0.7,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                minHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              decoration: BoxDecoration(
                color: Color(0xFF0B3C5D),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.lightBlueColor, width: 2.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(-5, 0),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: <Widget>[
                        // Drawer Header (User Info)
                        _CustomDrawerHeader(
                          authProvider:
                              Provider.of<AuthProvider>(context, listen: false),
                          highResTutorImages: highResTutorImages,
                        ),
                        Divider(
                            color: Colors.white54,
                            thickness: 0.5), // Add a divider after header
                        // Menu Items
                        ListTile(
                          leading: Icon(Icons.dashboard, color: Colors.white),
                          title: Text('Panel',
                              style: TextStyle(color: Colors.white)),
                          onTap: () {
                            // TODO: Implement navigation to Panel screen
                            setState(() {
                              _isCustomDrawerOpen = false;
                            });
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.settings, color: Colors.white),
                          title: Text('Configuración del perfil',
                              style: TextStyle(color: Colors.white)),
                          onTap: () {
                            // TODO: Implement navigation to Profile Settings screen
                            setState(() {
                              _isCustomDrawerOpen = false;
                            });
                          },
                        ),
                        ListTile(
                          leading:
                              Icon(Icons.calendar_today, color: Colors.white),
                          title: Text('Mis reservas',
                              style: TextStyle(color: Colors.white)),
                          onTap: () {
                            // TODO: Implement navigation to My Bookings screen
                            setState(() {
                              _isCustomDrawerOpen = false;
                            });
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.receipt, color: Colors.white),
                          title: Text('Facturas',
                              style: TextStyle(color: Colors.white)),
                          onTap: () {
                            // TODO: Implement navigation to Invoices screen
                            setState(() {
                              _isCustomDrawerOpen = false;
                            });
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.inbox, color: Colors.white),
                          title: Text('Bandeja de entrada',
                              style: TextStyle(color: Colors.white)),
                          onTap: () {
                            // TODO: Implement navigation to Inbox screen
                            setState(() {
                              _isCustomDrawerOpen = false;
                            });
                          },
                        ),
                        Divider(
                            color: Colors.white54,
                            thickness: 0.5), // Add a divider
                        ListTile(
                          leading: Icon(Icons.logout, color: Colors.red),
                          title: Text('Salir de la cuenta',
                              style: TextStyle(color: Colors.red)),
                          onTap: () async {
                            // Make the function async
                            // TODO: Implement logout functionality
                            // Call the logout method from AuthProvider
                            await Provider.of<AuthProvider>(context,
                                    listen: false)
                                .clearToken();

                            // Navigate to the LoginScreen and remove all previous routes
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => LoginScreen()),
                              (Route<dynamic> route) => false,
                            );
                            setState(() {
                              _isCustomDrawerOpen = false;
                            }); // Close the drawer
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Custom Drawer Implementation (Left) - Existing
          if (_isLeftDrawerOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isLeftDrawerOpen = false;
                  });
                },
                child: Container(
                    color: Colors.black
                        .withOpacity(0.5)), // Overlay semi-transparente
              ),
            ),

          // Custom Drawer Implementation (Left) - Código movido aquí
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300), // Animation duration
            curve: Curves.easeInOut,
            top: MediaQuery.of(context).padding.top +
                62.0, // Position below status bar and header
            left: _isLeftDrawerOpen
                ? 0
                : -(MediaQuery.of(context).size.width *
                    0.7), // Slide in/out from the left
            width: MediaQuery.of(context).size.width *
                0.7, // Set width (adjust as needed)
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height *
                    0.8, // Máximo 80% de la altura de la pantalla
              ),
              decoration: BoxDecoration(
                color:
                    const Color(0xFF00B4D8), // Teal background color from Figma
                borderRadius: BorderRadius.only(
                  topRight:
                      Radius.circular(16), // Apply border radius to top right
                  bottomRight: Radius.circular(
                      16), // Apply border radius to bottom right
                ),
                boxShadow: [
                  // Optional: Add shadow for depth
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(5, 0),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min, // Importante: usar MainAxisSize.min
                children: [
                  Expanded(
                    child: ListView(
                      shrinkWrap: true, // Importante: agregar shrinkWrap
                      padding: EdgeInsets.zero,
                      children: [
                        // Menu Items
                        ListTile(
                          title: Text('Inicio',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                          onTap: () {
                            // TODO: Implement navigation for Inicio
                            setState(() {
                              _isLeftDrawerOpen = false;
                            });
                          },
                        ),
                        Divider(
                            color: Colors.white54, thickness: 0.5), // Divider
                        ListTile(
                          title: Text('Buscar Tutores',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                          onTap: () {
                            // TODO: Implement navigation for Buscar Tutores
                            setState(() {
                              _isLeftDrawerOpen = false;
                            });
                          },
                        ),
                        Divider(
                            color: Colors.white54, thickness: 0.5), // Divider
                        ListTile(
                          title: Text('Sobre Nosotros',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                          onTap: () {
                            // TODO: Implement navigation for Sobre Nosotros
                            setState(() {
                              _isLeftDrawerOpen = false;
                            });
                          },
                        ),
                        Divider(
                            color: Colors.white54, thickness: 0.5), // Divider
                        ListTile(
                          title: Text('Como Trabajamos',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                          onTap: () {
                            // TODO: Implement navigation for Como Trabajamos
                            setState(() {
                              _isLeftDrawerOpen = false;
                            });
                          },
                        ),
                        Divider(
                            color: Colors.white54, thickness: 0.5), // Divider
                        ListTile(
                          title: Text('Preguntas',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                          onTap: () {
                            // TODO: Implement navigation for Preguntas
                            setState(() {
                              _isLeftDrawerOpen = false;
                            });
                          },
                        ),
                        Divider(
                            color: Colors.white54, thickness: 0.5), // Divider
                        ListTile(
                          title: Text('Blogs',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                          onTap: () {
                            // TODO: Implement navigation for Blogs
                            setState(() {
                              _isLeftDrawerOpen = false;
                            });
                          },
                        ),
                        Divider(
                            color: Colors.white54, thickness: 0.5), // Divider
                      ],
                    ),
                  ),
                  // Social Media Icons Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20.0, horizontal: 16.0), // Adjust padding
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // TODO: Replace with actual social media icon widgets and onTap functionality
                        Icon(Icons.tiktok,
                            color: Colors.white, size: 30), // Placeholder icon
                        Icon(Icons.facebook,
                            color: Colors.white, size: 30), // Placeholder icon
                        Icon(Icons.chat,
                            color: Colors.white,
                            size: 30), // Usar icono genérico para Whatsapp
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _playVideo(String url, int index) async {
    if (_activeController != null) {
      await _activeController!.dispose();
    }

    setState(() {
      _playingIndex = index;
      _isVideoLoading = true;
    });

    try {
      if (url.isEmpty) {
        throw Exception('URL del video vacía');
      }

      final controller = VideoPlayerController.network(
        url,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
        httpHeaders: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type',
        },
      );

      await controller.initialize().timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Tiempo de espera agotado al cargar el video');
        },
      );

      if (!mounted) {
        controller.dispose();
        return;
      }

      controller.setVolume(1.0);
      controller.setLooping(true);

      setState(() {
        _activeController = controller;
        _isVideoLoading = false;
      });

      await controller.play();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isVideoLoading = false;
        _playingIndex = -1;
        _activeController = null;
      });

      String errorMessage = 'No se pudo reproducir el video. ';
      if (e is TimeoutException) {
        errorMessage += 'El servidor tardó demasiado en responder.';
      } else if (e.toString().contains('CleartextNotPermitted')) {
        errorMessage += 'Error de configuración de red.';
      } else {
        errorMessage += 'Por favor, intente más tarde.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleVideoTap(int index) {
    final tutor = featuredTutors[index];
    final profile = tutor['profile'] ?? {};
    final videoPath = profile['intro_video'] ?? '';
    if (videoPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Este tutor no tiene video de presentación'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final videoUrl = getFullUrl(videoPath, baseVideoUrl);

    if (_playingIndex == index && _activeController != null) {
      if (_activeController!.value.isPlaying) {
        _activeController!.pause();
      } else {
        _activeController!.play();
      }
    } else {
      setState(() {
        _isManualPlay = true;
      });
      _playVideo(videoUrl, index);
    }
  }

  void _stopVideo() {
    if (_activeController != null) {
      _activeController!.pause();
      _activeController!.dispose();
      _activeController = null;
    }
    if (!mounted) return;

    setState(() {
      _playingIndex = -1;
      _isVideoLoading = true;
      _isManualPlay = false;
    });
  }

  Widget _buildVideoThumbnail(String videoUrl, int index) {
    if (_playingIndex == index && _activeController != null) {
      return Stack(
        children: [
          AspectRatio(
            aspectRatio: _activeController!.value.aspectRatio,
            child: VideoPlayer(_activeController!),
          ),
          if (_isVideoLoading)
            Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.lightBlueColor,
                  strokeWidth: 4,
                ),
              ),
            ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleVideoTap(index),
              ),
            ),
          ),
        ],
      );
    }

    if (_thumbnailCache.containsKey(index) && _thumbnailCache[index] != null) {
      return Stack(
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: Image.memory(
                _thumbnailCache[index]!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleVideoTap(index),
              ),
            ),
          ),
        ],
      );
    }

    // Imagen por defecto mientras se carga el thumbnail
    return Stack(
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[400]!,
          highlightColor: Colors.white,
          child: Container(
            width: tutorCardWidth,
            height: tutorCardImageHeight,
            color: Colors.grey[400],
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _handleVideoTap(index),
            ),
          ),
        ),
      ],
    );
  }

  // Función para obtener la URL completa de imagen o video
  String getFullUrl(String path, String base) {
    if (path.startsWith('http')) {
      return path;
    }
    return base + path;
  }

  Widget _buildMenuOption(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchModal() {
    print(
        'DEBUG: Iniciando _showSearchModal con ${_subjects.length} materias precargadas');

    _searchQuery = '';
    _searchController.clear();
    _isModalLoading = false;

    Map<String, dynamic>?
        _selectedSubject; // Variable de estado para la materia seleccionada

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Declarar variables locales para el modal de búsqueda
            List<dynamic> filteredSubjects = List<dynamic>.from(_subjects);
            bool isSearchingAPI = false;

            Future<void> loadMoreSubjectsFromModal() async {
              if (_isFetchingMoreSubjects || !_hasMoreSubjects) return;

              _isFetchingMoreSubjects = true;
              setModalState(() {});

              try {
                final response = await getAllSubjects(
                  null,
                  page: _currentPageSubjects,
                  perPage: _subjectsPerPage,
                  keyword: _searchQuery,
                );
                if (response != null && response.containsKey('data')) {
                  final responseData = response['data'];
                  if (responseData is Map<String, dynamic> &&
                      responseData.containsKey('data')) {
                    final subjectsList = responseData['data'];
                    final totalPages = responseData['last_page'] ?? 1;
                    final currentPage = responseData['current_page'] ?? 1;

                    final nuevos = subjectsList
                        .where((s) => !_subjects.any((e) => e['id'] == s['id']))
                        .toList();
                    _subjects.addAll(nuevos);

                    _hasMoreSubjects = currentPage < totalPages;
                    if (_hasMoreSubjects)
                      _currentPageSubjects = currentPage + 1;

                    setModalState(() {});
                  }
                }
              } catch (e) {
                print('DEBUG: Error al cargar más materias: $e');
              } finally {
                _isFetchingMoreSubjects = false;
                setModalState(() {});
              }
            }

            final ScrollController modalScrollController = ScrollController();
            modalScrollController.addListener(() {
              if (modalScrollController.position.pixels >=
                  modalScrollController.position.maxScrollExtent - 200) {
                // loadMoreSubjectsFromModal(); // Descomentar si se implementa paginación
              }
            });

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                  minHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.darkBlue, // Color oscuro de la paleta
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              autofocus: true,
                              controller: _searchController,
                              onChanged: (value) {
                                if (_debounce?.isActive ?? false)
                                  _debounce!.cancel();
                                _debounce =
                                    Timer(const Duration(milliseconds: 300),
                                        () async {
                                  setModalState(() {
                                    _searchQuery = value;
                                  });

                                  // Si la búsqueda está vacía, mostrar materias precargadas
                                  if (value.trim().isEmpty) {
                                    setModalState(() {
                                      filteredSubjects =
                                          List<dynamic>.from(_subjects);
                                      isSearchingAPI = false;
                                    });
                                    return;
                                  }

                                  // Primero filtrar localmente
                                  List<dynamic> localResults = _subjects
                                      .where((s) => (s['name'] ?? '')
                                          .toLowerCase()
                                          .contains(value.toLowerCase()))
                                      .toList();

                                  // Si hay suficientes resultados locales, usarlos
                                  if (localResults.length >= 3) {
                                    setModalState(() {
                                      filteredSubjects = localResults;
                                      isSearchingAPI = false;
                                    });
                                  } else {
                                    // Si no hay suficientes resultados, buscar en API
                                    setModalState(() {
                                      isSearchingAPI = true;
                                    });
                                    try {
                                      final response = await getAllSubjects(
                                        null,
                                        page: 1,
                                        perPage: 100,
                                        keyword: value,
                                      );
                                      List<dynamic> newSubjects = [];
                                      if (response != null &&
                                          response.containsKey('data')) {
                                        final responseData = response['data'];
                                        if (responseData
                                                is Map<String, dynamic> &&
                                            responseData.containsKey('data')) {
                                          newSubjects = responseData['data'];
                                        }
                                      }
                                      setModalState(() {
                                        filteredSubjects = newSubjects;
                                        isSearchingAPI = false;
                                      });
                                    } catch (e) {
                                      setModalState(() {
                                        filteredSubjects =
                                            localResults; // Usar resultados locales como fallback
                                        isSearchingAPI = false;
                                      });
                                    }
                                  }
                                });
                              },
                              onSubmitted: (value) {
                                if (value.trim().isNotEmpty) {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SearchTutorsScreen(
                                          initialKeyword: value.trim()),
                                    ),
                                  );
                                }
                              },
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'Busca tu materia...',
                                hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.6)),
                                prefixIcon: Icon(Icons.search,
                                    color: Colors.white.withOpacity(0.6)),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              if (_searchController.text.trim().isNotEmpty) {
                                final searchKeyword =
                                    _searchController.text.trim();
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SearchTutorsScreen(
                                        initialKeyword: searchKeyword),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              'Buscar',
                              style: TextStyle(
                                color: AppColors.lightBlueColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Divider(color: Colors.white.withOpacity(0.1), height: 1),
                    Expanded(
                      child: Stack(
                        children: [
                          _isModalLoading && _subjects.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                          color: AppColors.lightBlueColor),
                                      SizedBox(height: 16),
                                      Text('Buscando materias...',
                                          style:
                                              TextStyle(color: Colors.white70)),
                                    ],
                                  ),
                                )
                              : _subjects.isEmpty &&
                                      !_hasMoreSubjects &&
                                      !_isModalLoading
                                  ? Center(
                                      child: Text('No se encontraron materias',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16)),
                                    )
                                  : ListView.separated(
                                      controller: modalScrollController,
                                      padding: EdgeInsets.only(
                                          bottom: _selectedSubject != null
                                              ? 100
                                              : 0),
                                      itemCount: _subjects.length +
                                          (_hasMoreSubjects ? 1 : 0),
                                      separatorBuilder: (context, index) =>
                                          Divider(
                                        color: Colors.white.withOpacity(0.1),
                                        height: 1,
                                        indent: 16,
                                        endIndent: 16,
                                      ),
                                      itemBuilder: (context, index) {
                                        if (index == _subjects.length) {
                                          return Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                                        color: AppColors
                                                            .lightBlueColor)),
                                          );
                                        }

                                        final subject = _subjects[index];
                                        final subjectName = subject['name'] ??
                                            'Materia desconocida';
                                        final isSelected =
                                            _selectedSubject != null &&
                                                _selectedSubject!['id'] ==
                                                    subject['id'];

                                        return ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 8),
                                          tileColor: isSelected
                                              ? AppColors.lightBlueColor
                                                  .withOpacity(0.15)
                                              : Colors.transparent,
                                          title: Text(
                                            subjectName,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? AppColors.lightBlueColor
                                                  : Colors.white,
                                              fontSize: 16,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          onTap: () {
                                            FocusScope.of(context)
                                                .unfocus(); // Cierra el teclado
                                            setModalState(() {
                                              _selectedSubject = subject;
                                            });
                                            // Mostrar el BottomSheet contextual al seleccionar una materia
                                            Future.delayed(
                                                Duration(milliseconds: 150),
                                                () {
                                              showModalBottomSheet(
                                                context: context,
                                                backgroundColor:
                                                    Colors.transparent,
                                                builder: (context) {
                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      color: AppColors.darkBlue,
                                                      borderRadius:
                                                          BorderRadius.vertical(
                                                              top: Radius
                                                                  .circular(
                                                                      24)),
                                                    ),
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                            24,
                                                            24,
                                                            24,
                                                            24 +
                                                                MediaQuery.of(
                                                                        context)
                                                                    .padding
                                                                    .bottom),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          '¿Qué deseas hacer con "${subject['name']}"?',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 18,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                        SizedBox(height: 24),
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child:
                                                                  ElevatedButton
                                                                      .icon(
                                                                onPressed: () {
                                                                  Navigator.pop(
                                                                      context);
                                                                  // Acción para Empezar tutoría
                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .showSnackBar(
                                                                    SnackBar(
                                                                        content:
                                                                            Text('Empezar tutoría para "${subject['name']}"')),
                                                                  );
                                                                },
                                                                icon: Icon(
                                                                    Icons
                                                                        .play_circle_fill,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 22),
                                                                label: Text(
                                                                    'Empezar tutoría',
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontWeight:
                                                                            FontWeight.bold)),
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                  backgroundColor:
                                                                      AppColors
                                                                          .orangeprimary,
                                                                  shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              14)),
                                                                  padding: EdgeInsets
                                                                      .symmetric(
                                                                          vertical:
                                                                              16),
                                                                  elevation: 2,
                                                                  shadowColor: AppColors
                                                                      .orangeprimary
                                                                      .withOpacity(
                                                                          0.25),
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(width: 16),
                                                            Expanded(
                                                              child:
                                                                  ElevatedButton
                                                                      .icon(
                                                                onPressed: () {
                                                                  Navigator.pop(
                                                                      context);
                                                                  // Acción para Elegir Tutor
                                                                  Navigator.pop(
                                                                      context); // Cierra el modal de materias
                                                                  Navigator
                                                                      .push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder:
                                                                          (context) =>
                                                                              SearchTutorsScreen(
                                                                        initialKeyword:
                                                                            subject['name'],
                                                                        initialSubjectId:
                                                                            subject['id'],
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                                icon: Icon(
                                                                    Icons
                                                                        .person_search,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 22),
                                                                label: Text(
                                                                    'Elegir Tutor',
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontWeight:
                                                                            FontWeight.bold)),
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                  backgroundColor:
                                                                      AppColors
                                                                          .lightBlueColor,
                                                                  shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              14)),
                                                                  padding: EdgeInsets
                                                                      .symmetric(
                                                                          vertical:
                                                                              16),
                                                                  elevation: 2,
                                                                  shadowColor: AppColors
                                                                      .lightBlueColor
                                                                      .withOpacity(
                                                                          0.25),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              );
                                            });
                                          },
                                        );
                                      },
                                    ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _fetchSubjects(
      {bool isInitialLoad = false, String keyword = ''}) async {
    if (!isInitialLoad && (!_hasMoreSubjects || _isFetchingMoreSubjects)) {
      return;
    }

    if (isInitialLoad) {
      _isLoadingSubjects = true;
      _isModalLoading = true;
      _subjects.clear();
    } else {
      _isFetchingMoreSubjects = true;
    }

    try {
      print(
          'DEBUG: Buscando materias - Página $_currentPageSubjects, Keyword: ${keyword ?? _searchQuery}');
      final response = await getAllSubjects(
        null,
        page: _currentPageSubjects,
        perPage: _subjectsPerPage,
        keyword: keyword ?? _searchQuery,
      );

      if (response != null && response.containsKey('data')) {
        final responseData = response['data'];
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('data')) {
          final subjectsList = responseData['data'];
          final totalPages = responseData['last_page'] ?? 1;
          final currentPage = responseData['current_page'] ?? 1;

          _subjects.addAll(subjectsList);
          print('DEBUG: Materias encontradas: ${subjectsList.length}');

          _hasMoreSubjects = currentPage < totalPages;
          if (_hasMoreSubjects) {
            _currentPageSubjects = currentPage + 1;
            print('DEBUG: Siguiente página: $_currentPageSubjects');
          } else {
            print('DEBUG: No hay más páginas disponibles');
          }
        } else {
          _hasMoreSubjects = false;
          print('DEBUG: Estructura de respuesta inválida');
        }
      } else {
        _hasMoreSubjects = false;
        print('DEBUG: Respuesta de API inválida');
      }
    } catch (e) {
      _hasMoreSubjects = false;
      print('DEBUG: Error al buscar materias: $e');
    } finally {
      _isModalLoading = false;
      _isFetchingMoreSubjects = false;
      _isLoadingSubjects = false;
    }
  }

  void _onScroll() {
    if (!mounted || _isManualPlay) return;

    // Actualizar la visibilidad de los items (sin setState frecuente)
    bool hasChanges = false;
    for (int i = 0; i < featuredTutors.length; i++) {
      final isVisible = _isItemVisible(i);
      if (_visibleItems[i] != isVisible) {
        _visibleItems[i] = isVisible;
        hasChanges = true;
        if (isVisible && !_thumbnailCache.containsKey(i)) {
          final tutor = featuredTutors[i];
          final profile = tutor['profile'] ?? {};
          final videoPath = profile['intro_video'] ?? '';
          if (videoPath.isNotEmpty) {
            final videoUrl = getFullUrl(videoPath, baseVideoUrl);
            _preloadThumbnail(videoUrl, i);
          }
        }
      }
    }

    // Solo llamar setState si hay cambios significativos
    if (hasChanges && mounted) {
      setState(() {});
    }
  }

  bool _isItemVisible(int index) {
    if (!_scrollController.hasClients) return false;

    final itemPosition = index * 208.0; // 200 (ancho) + 8 (margen)
    final screenWidth = MediaQuery.of(context).size.width;
    final scrollOffset = _scrollController.offset;

    return itemPosition >= scrollOffset &&
        itemPosition <= scrollOffset + screenWidth;
  }

  Future<void> _preloadThumbnail(String videoUrl, int index) async {
    if (_thumbnailCache.containsKey(index)) return;

    try {
      if (videoUrl.isEmpty) {
        if (mounted) {
          setState(() {
            _thumbnailCache[index] = null;
          });
        }
        return;
      }

      final thumbnail = await VideoThumbnail.thumbnailData(
        video: videoUrl,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 400,
        quality: 90,
      );

      if (mounted) {
        setState(() {
          _thumbnailCache[index] = thumbnail;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _thumbnailCache[index] = null;
        });
      }
    }
  }

  void _onTutorsScroll() {
    // Ya no necesitamos este listener con PageView
    // El PageView maneja automáticamente el snap y la precarga
  }

  Future<void> fetchFeaturedTutorsAndVerified() async {
    setState(() {
      isLoadingTutors = true;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      // Obtiene destacados
      final response = await findTutors(token, perPage: 1000);
      List<dynamic> tutors = [];
      if (response.containsKey('data')) {
        final data = response['data'];
        if (data.containsKey('list') && data['list'] is List) {
          tutors = data['list'];
        } else if (data.containsKey('data') && data['data'] is List) {
          tutors = data['data'];
        } else if (data is List) {
          tutors = data;
        }
      }
      // Obtiene verificados
      final verifiedResponse = await getVerifiedTutors(token, perPage: 1000);
      List<dynamic> verifiedTutors = [];
      if (verifiedResponse.containsKey('data')) {
        final data = verifiedResponse['data'];
        if (data.containsKey('list') && data['list'] is List) {
          verifiedTutors = data['list'];
        } else if (data.containsKey('data') && data['data'] is List) {
          verifiedTutors = data['data'];
        } else if (data is List) {
          verifiedTutors = data;
        }
      }
      // Unir ambos sin duplicados por id
      final allTutors = <int, dynamic>{};
      for (var t in tutors) {
        if (t['id'] != null) allTutors[t['id']] = t;
      }
      for (var t in verifiedTutors) {
        if (t['id'] != null) allTutors[t['id']] = t;
      }
      setState(() {
        featuredTutors = allTutors.values
            .where((t) =>
                t['subjects'] != null && (t['subjects'] as List).isNotEmpty)
            .toList();
      });
      // Precargar thumbnails para los primeros tutores visibles
      for (var i = 0; i < featuredTutors.length; i++) {
        final tutor = featuredTutors[i];
        final profile = tutor['profile'] ?? {};
        final videoPath = profile['intro_video'] ?? '';
        if (videoPath.isNotEmpty) {
          final videoUrl = getFullUrl(videoPath, baseVideoUrl);
          _preloadThumbnail(videoUrl, i);
        }
      }
    } catch (e) {
      print('DEBUG: Error en fetchFeaturedTutorsAndVerified: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error al cargar los tutores. Por favor, intente más tarde.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        isLoadingTutors = false;
      });
    }
  }

  Future<void> fetchAlliancesData() async {
    setState(() {
      isLoadingAlliances = true;
    });
    try {
      print('DEBUG: Obteniendo alianzas');
      final response = await fetchAlliances();
      print('DEBUG: Respuesta de fetchAlliances: ${response.keys.toList()}');

      if (response.containsKey('data')) {
        final alliancesData = response['data'];
        print(
            'DEBUG: Alianzas encontradas: ${alliancesData is List ? alliancesData.length : "no es lista"}');

        if (alliancesData is List) {
          setState(() {
            alliances = alliancesData;
          });
        } else {
          print('DEBUG: alliancesData no es una lista: $alliancesData');
          setState(() {
            alliances = [];
          });
        }
      } else {
        print(
            'DEBUG: No se encontró la clave "data" en la respuesta de alianzas');
        setState(() {
          alliances = [];
        });
      }
    } catch (e) {
      print('DEBUG: Error en fetchAlliancesData: $e');
      // Error silencioso para alianzas
      setState(() {
        alliances = [];
      });
    } finally {
      setState(() {
        isLoadingAlliances = false;
      });
    }
  }

  // Función para precargar las primeras 20 materias
  Future<void> fetchInitialSubjects() async {
    try {
      print('DEBUG: Precargando 20 materias iniciales');
      final response = await getAllSubjects(
        null,
        page: 1,
        perPage: 20, // Solo 20 materias para precarga rápida
      );
      if (response != null && response.containsKey('data')) {
        final responseData = response['data'];
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('data')) {
          final subjectsList = responseData['data'];
          setState(() {
            _subjects = subjectsList;
            _currentPageSubjects = 2; // La siguiente página será la 2
            _hasMoreSubjects = responseData['last_page'] > 1;
          });
          print('DEBUG: Precargadas ${subjectsList.length} materias iniciales');
        }
      }
    } catch (e) {
      print('DEBUG: Error al precargar materias iniciales: $e');
    }
  }

  // 3. Implementa la función para obtener las imágenes HD:
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

  Widget _buildAvatarWithShimmer(String imageUrl) {
    return SizedBox(
      width: 48,
      height: 48,
      child: imageUrl.isEmpty
          ? Shimmer.fromColors(
              baseColor: Colors.grey[400]!,
              highlightColor: Colors.white,
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 21,
                  backgroundColor: Colors.grey[400],
                ),
              ),
            )
          : ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[400]!,
                  highlightColor: Colors.white,
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 21,
                      backgroundColor: Colors.grey[400],
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 21,
                    backgroundColor: Colors.grey[400],
                    child:
                        Icon(Icons.person, size: 20, color: Colors.grey[600]),
                  ),
                ),
              ),
            ),
    );
  }

  void _checkAndFetchBookings() {
    final userId = _authProvider!.userId;
    if (userId != null && userId != _lastFetchedUserId) {
      _lastFetchedUserId = userId;
      _fetchTodaysBookings();
    }
  }

  Future<String?> fetchTutorHDImage(int tutorId) async {
    try {
      final url = Uri.parse(
          'https://classgoapp.com/api/verified-tutors-photos?tutor_id=$tutorId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] is List && data['data'].isNotEmpty) {
          final item = data['data'].firstWhere(
            (e) => e['id'] == tutorId && e['profile_image'] != null,
            orElse: () => null,
          );
          if (item != null && item['profile_image'] != null) {
            return item['profile_image'] as String;
          }
        }
      }
    } catch (e) {
      // Ignorar error, usar fallback
    }
    return '';
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final String description;
  final String buttonText;
  final String imageUrl;

  const _StepCard({
    required this.step,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Image.network(
              imageUrl,
              height: 80,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          margin: EdgeInsets.only(top: 2, bottom: 6),
                          decoration: BoxDecoration(
                            color: Color(0xFFFF9900),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(step,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                        SizedBox(height: 8),
                        Text(
                          title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF0B3C5D)),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 2.0),
                    child: Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF9900),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding:
                              EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        ),
                        onPressed: () {},
                        child: Text(buttonText,
                            style: TextStyle(fontWeight: FontWeight.bold)),
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
  }
}

class _AllianceCard extends StatelessWidget {
  final String logoUrl;
  final String name;
  final Color color;

  const _AllianceCard({
    required this.logoUrl,
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 160,
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              logoUrl,
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              name,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartJourneyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      width: isMobile ? 240 : 280,
      margin: EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Color(0xFF073B4C),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Icon(Icons.layers, color: Colors.white, size: 38),
          ),
          SizedBox(height: 12),
          Text(
            'Comienza tu Jornada',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Comienza tu viaje educativo con nosotros. ¡Encuentra un tutor y reserva tu primera sesión hoy mismo!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
            ),
          ),
          SizedBox(height: 18),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF9900),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
              onPressed: () {},
              icon: Icon(Icons.arrow_forward, color: Colors.white),
              label: Text('Empieza Ahora',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotsAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    _dotsAnimation = StepTween(begin: 1, end: 3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotsAnimation,
      builder: (context, child) {
        String dots = '.' * _dotsAnimation.value;
        return Text(
          'Buscando$dots',
          style: TextStyle(
            color: AppColors.orangeprimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        );
      },
    );
  }
}

class _CustomDrawerHeader extends StatelessWidget {
  final AuthProvider authProvider;
  final Map<int, String> highResTutorImages;

  const _CustomDrawerHeader(
      {required this.authProvider, required this.highResTutorImages});

  @override
  Widget build(BuildContext context) {
    final userData = authProvider.userData;

    // Corregir la URL de la imagen si es necesario
    String? imageUrl = userData?['user']?['profile']?['image'];
    int? userId = userData?['user']?['id'];
    String? hdImageUrl =
        (userId != null && highResTutorImages.containsKey(userId))
            ? highResTutorImages[userId]
            : null;
    if (hdImageUrl != null && hdImageUrl.isNotEmpty) {
      imageUrl = hdImageUrl;
    } else if (imageUrl != null &&
        imageUrl.contains(
            'https://classgoapp.com/storage/thumbnails/https://classgoapp.com/storage/thumbnails/')) {
      imageUrl = imageUrl.replaceFirst(
          'https://classgoapp.com/storage/thumbnails/https://classgoapp.com/storage/thumbnails/',
          'https://classgoapp.com/storage/thumbnails/');
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B9ED9), Color(0xFF073B4C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          topLeft: Radius.circular(0),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl ?? '',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person,
                          size: 36, color: Color(0xFF023E8A)),
                    ),
                    errorWidget: (context, url, error) => CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person,
                          size: 36, color: Color(0xFF023E8A)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (userData != null)
                      Text(
                        userData['user']?['profile']?['full_name'] ?? 'Usuario',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()),
                            (Route<dynamic> route) => false,
                          );
                        },
                        child: Text(
                          'Iniciar sesión',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    if (userData != null)
                      Text(
                        userData['user']?['email'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: Colors.white24, thickness: 1),
        ],
      ),
    );
  }
}

class UpcomingSessionBanner extends StatefulWidget {
  final List<Map<String, dynamic>> bookings;
  const UpcomingSessionBanner({Key? key, required this.bookings})
      : super(key: key);

  @override
  State<UpcomingSessionBanner> createState() => _UpcomingSessionBannerState();
}

class _UpcomingSessionBannerState extends State<UpcomingSessionBanner> {
  @override
  Widget build(BuildContext context) {
    print('DEBUG: UpcomingSessionBanner se está reconstruyendo');
    if (widget.bookings.isEmpty) return SizedBox.shrink();
    final now = DateTime.now();
    // Filtrar solo tutorías cuya hora de finalización es igual o posterior a la hora actual
    final validBookings = widget.bookings.where((b) {
      final end = DateTime.tryParse(b['end_time'] ?? '') ?? now;
      return end.isAfter(now) || end.isAtSameMomentAs(now);
    }).toList();
    if (validBookings.isEmpty) return SizedBox.shrink();
    // Ordenar por hora de inicio
    validBookings.sort(
        (a, b) => (a['start_time'] ?? '').compareTo(b['start_time'] ?? ''));
    // Elegir la que mostrar: en curso o la más próxima
    Map<String, dynamic>? booking;
    bool isLive = false;
    for (var b in validBookings) {
      final start = DateTime.tryParse(b['start_time'] ?? '') ?? now;
      final end = DateTime.tryParse(b['end_time'] ?? '') ?? now;
      if (now.isAfter(start) && now.isBefore(end)) {
        booking = b;
        isLive = true;
        break;
      }
    }
    booking ??= validBookings.first;
    final start = DateTime.tryParse(booking['start_time'] ?? '') ?? now;
    final end = DateTime.tryParse(booking['end_time'] ?? '') ?? now;
    final status = (booking['status'] ?? '').toString().trim().toLowerCase();
    // Permitir tanto 'aceptado' como 'aceptada' como estado válido
    final isAceptado = status == 'aceptada' || status == 'aceptado';
    // Permitir tanto 'rechazado' como 'rechazada' como estado válido
    final isRechazado = status == 'rechazada' || status == 'rechazado';
    print('DEBUG: Estado actual de la tutoría: $status');
    final isSoon = !isLive && start.isAfter(now);
    final subject = booking['subject_name'] ?? 'Tutoría';
    final hourStr =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

    // Lógica de colores y animaciones según estado y momento
    String mainText = '';
    String lottieAsset = '';
    Color color = Colors.blueAccent.withOpacity(0.85);
    Color textColor = Colors.white;

    print('DEBUG: isLive = $isLive, isSoon = $isSoon, status = "$status"');

    // Lógica de colores por estado específico primero
    if (isRechazado) {
      print('DEBUG: ESTADO RECHAZADO - Color gris');
      mainText = 'Tutoría rechazada';
      lottieAsset =
          'https://assets2.lottiefiles.com/packages/lf20_4kx2q32n.json';
      color = Colors.grey.withOpacity(0.85);
      textColor = Colors.white;
    } else if (status == 'pendiente') {
      print('DEBUG: ESTADO PENDIENTE - Color naranja');
      mainText = 'Pendiente de aceptación';
      lottieAsset =
          'https://assets2.lottiefiles.com/packages/lf20_4kx2q32n.json';
      color = Colors.orangeAccent.withOpacity(0.95);
      textColor = Colors.black;
    } else if (status == 'solicitada') {
      print('DEBUG: ESTADO SOLICITADA - Color naranja');
      mainText = 'Pendiente de aceptación';
      lottieAsset =
          'https://assets2.lottiefiles.com/packages/lf20_4kx2q32n.json';
      color = Colors.orangeAccent.withOpacity(0.95);
      textColor = Colors.black;
    } else if (isAceptado && isLive) {
      // Estado aceptado EN VIVO: rojo
      print('DEBUG: ESTADO ACEPTADO EN VIVO - Color rojo');
      mainText = 'EN VIVO';
      lottieAsset =
          'https://assets2.lottiefiles.com/packages/lf20_30305_back_to_school.json';
      color = Colors.redAccent.withOpacity(0.85);
      textColor = Colors.white;
    } else if (isAceptado && isSoon) {
      // Estado aceptado PRÓXIMA: azul
      print('DEBUG: ESTADO ACEPTADO PRÓXIMA - Color azul');
      mainText = 'Próxima tutoría';
      lottieAsset =
          'https://assets2.lottiefiles.com/packages/lf20_30305_back_to_school.json';
      color = Colors.blueAccent.withOpacity(0.85);
      textColor = Colors.white;
    } else if (isLive) {
      print('DEBUG: EN HORARIO PERO NO ACEPTADA - Color ámbar');
      mainText = 'En horario, pero no aceptada';
      lottieAsset =
          'https://assets2.lottiefiles.com/packages/lf20_4kx2q32n.json';
      color = Colors.amber.withOpacity(0.95);
      textColor = Colors.black;
    } else {
      print('DEBUG: ESTADO DEFAULT - Color azul gris');
      mainText = 'Tutoría programada para hoy';
      lottieAsset =
          'https://assets2.lottiefiles.com/packages/lf20_30305_back_to_school.json';
      color = Colors.blueGrey.withOpacity(0.85);
      textColor = Colors.white;
    }

    print('DEBUG: Color final seleccionado: $color');
    print('DEBUG: Texto final: $mainText');

    String statusText = 'Estado: \\${booking['status'] ?? ''}';

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _BookingDetailModal(
            booking: booking!,
            highResTutorImages: (context
                    .findAncestorStateOfType<_HomeScreenState>()
                    ?.highResTutorImages) ??
                {},
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [color, Colors.white.withOpacity(0.10)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.18),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: Lottie.network(
                lottieAsset,
                width: 36,
                height: 36,
                repeat: true,
                animate: true,
                options: LottieOptions(enableMergePaths: true),
                errorBuilder: (context, error, stackTrace) {
                  final visibleColor = Colors.white;
                  if (isLive && isAceptado) {
                    return Icon(Icons.play_circle_fill,
                        color: visibleColor, size: 32);
                  } else if (isLive && !isAceptado) {
                    return Icon(Icons.warning_amber_rounded,
                        color: Colors.amber, size: 32);
                  } else if (isSoon &&
                      (status == 'pendiente' || status == 'solicitada')) {
                    return Icon(Icons.warning_amber_rounded,
                        color: Colors.orangeAccent, size: 32);
                  } else if (isSoon && isAceptado) {
                    return Icon(Icons.schedule, color: visibleColor, size: 32);
                  } else if (isRechazado) {
                    return Icon(Icons.cancel, color: Colors.grey, size: 32);
                  } else {
                    return Icon(Icons.school, color: visibleColor, size: 32);
                  }
                },
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mainText,
                    style: TextStyle(
                      color: color.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    subject,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    hourStr,
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: textColor.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingDetailModal extends StatelessWidget {
  final Map<String, dynamic> booking;
  final Map<int, String> highResTutorImages;
  const _BookingDetailModal(
      {Key? key, required this.booking, required this.highResTutorImages})
      : super(key: key);

  Future<Map<String, dynamic>?> fetchSlotDetail(int slotId) async {
    final url = Uri.parse('https://classgoapp.com/api/slot-detail/$slotId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 200 && data['data'] != null) {
        return data['data'];
      }
    }
    return null;
  }

  Future<String?> fetchTutorHDImage(int tutorId) async {
    try {
      final url = Uri.parse(
          'https://classgoapp.com/api/verified-tutors-photos?tutor_id=$tutorId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] is List && data['data'].isNotEmpty) {
          final item = data['data'].firstWhere(
            (e) => e['id'] == tutorId && e['profile_image'] != null,
            orElse: () => null,
          );
          if (item != null && item['profile_image'] != null) {
            return item['profile_image'] as String;
          }
        }
      }
    } catch (e) {
      // Ignorar error, usar fallback
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final slotId = booking['id'] is int
        ? booking['id']
        : int.tryParse(booking['id'].toString() ?? '');
    return FutureBuilder<Map<String, dynamic>?>(
      future: fetchSlotDetail(slotId ?? 0),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SafeArea(
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 32,
                bottom: 24 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 24,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF00B4D8)),
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return SafeArea(
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 32,
                bottom: 24 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 24,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Center(
                child: Text('No se pudo cargar el detalle de la tutoría',
                    style: TextStyle(color: Colors.red)),
              ),
            ),
          );
        }
        final data = snapshot.data!;
        final tutor = data['tutor'] ?? {};
        final subject = data['subject']?['name'] ?? 'Materia desconocida';
        final tutorName = tutor['full_name'] ?? 'Tutor desconocido';
        final tutorUserId = tutor['user_id'] is int
            ? tutor['user_id']
            : int.tryParse(tutor['user_id']?.toString() ?? '');
        final status = (data['status'] ?? '').toString();
        final startHour = data['start_time'] ?? '';
        return FutureBuilder<String?>(
          future: tutorUserId != null
              ? fetchTutorHDImage(tutorUserId)
              : Future.value(null),
          builder: (context, hdSnapshot) {
            final hdImage = hdSnapshot.data;
            print('DEBUG: Mostrando imagen HD de tutor en modal: $hdImage');
            return SafeArea(
              child: Container(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 32,
                  bottom: 24 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: AppColors.darkBlue,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lightBlueColor.withOpacity(0.18),
                      blurRadius: 24,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        margin: EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 38,
                            backgroundColor:
                                AppColors.lightBlueColor.withOpacity(0.18),
                            backgroundImage:
                                (hdImage != null && hdImage.isNotEmpty)
                                    ? NetworkImage(hdImage)
                                    : null,
                            child: (hdImage == null || hdImage.isEmpty)
                                ? Icon(Icons.person,
                                    size: 38, color: AppColors.lightBlueColor)
                                : null,
                          ),
                          SizedBox(height: 10),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.lightBlueColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_user,
                                    color: AppColors.lightBlueColor, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Tutor',
                                  style: TextStyle(
                                    color: AppColors.lightBlueColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            tutorName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18),
                    Row(
                      children: [
                        Icon(Icons.book, color: AppColors.lightBlueColor),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            subject,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            color: AppColors.lightBlueColor),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            startHour.isNotEmpty
                                ? 'Hora de inicio: $startHour'
                                : 'Horario no disponible',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.lightBlueColor),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Estado: $status',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 28),
                    Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lightBlueColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.white),
                        label: Text('Cerrar',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
