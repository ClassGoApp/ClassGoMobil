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

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  List<dynamic> _subjects = [];
  bool _isLoadingSubjects = false;
  bool _isFetchingMoreSubjects = false;
  int _currentPageSubjects = 1;
  bool _hasMoreSubjects = true;
  bool _isModalLoading = true;
  final int _subjectsPerPage = 100; // Aumentado a 100 para cargar más materias de una vez

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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    fetchFeaturedTutors();
    fetchAlliancesData();
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left menu icon
                        Builder(
                          builder: (context) => InkWell(
                            onTap: () {
                              setState(() {
                                _isLeftDrawerOpen = !_isLeftDrawerOpen; // Toggle left drawer state
                                _isCustomDrawerOpen = false; // Close right drawer if open
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.menu, color: Colors.white, size: 26), // Adjusted size to match person icon
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
                                _isCustomDrawerOpen = !_isCustomDrawerOpen; // Toggle right drawer state
                                _isLeftDrawerOpen = false; // Close left drawer if open
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.person_outline, color: Colors.white, size: 26), // Adjusted size to match menu icon
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Mensaje principal
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aprende con\nTutorías en Línea',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Alcanza tus metas con tutorías personalizadas de los mejores expertos. Conéctate con tutores dedicados para asegurar tu éxito.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 18),
                        // Barra de búsqueda
                        GestureDetector(
                          onTap: () {
                            _showSearchModal();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                    child: TextField(
                                      enabled: false,
                                      style: TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: 'Buscar Tutores',
                                        hintStyle: TextStyle(color: Colors.white70),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.search, color: Colors.white),
                                  onPressed: () {
                                    _showSearchModal();
                                  },
                                ),
                              ],
                            ),
                          ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18),
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
                            height: MediaQuery.of(context).size.height * 0.26, // 35% de la altura de la pantalla
                            child: isLoadingTutors
                                ? Center(child: CircularProgressIndicator(color: Colors.white))
                                : featuredTutors.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No hay tutores disponibles',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      )
                                    : ListView.separated(
                                        controller: _scrollController,
                                        scrollDirection: Axis.horizontal,
                                        itemCount: featuredTutors.length,
                                        separatorBuilder: (_, __) => SizedBox(width: 12),
                                        itemBuilder: (context, index) {
                                          try {
                                          final tutor = featuredTutors[index];
                                          final profile = tutor['profile'] ?? {};
                                          final name = profile['full_name'] ?? 'Sin nombre';
                                          final subjects = tutor['subjects'];
                                          String specialty = 'Sin especialidad';
                                          if (subjects is List && subjects.isNotEmpty && subjects[0] != null && subjects[0]['name'] != null) {
                                            specialty = subjects[0]['name'];
                                          }
                                            final rating = double.tryParse(tutor['avg_rating']?.toString() ?? '0.0') ?? 0.0;
                                            final imagePath = profile['image'] ?? '';
                                            final videoPath = profile['intro_video'] ?? '';
                                            final imageUrl = getFullUrl(imagePath, baseImageUrl);
                                            final videoUrl = getFullUrl(videoPath, baseVideoUrl);
                                            return Column(
                                              children: [
                                                Stack(
                                                  clipBehavior: Clip.none,
                                                  children: [
                                                    Container(
                                                      width: 200,
                                                      decoration: BoxDecoration(
                                                        color: Colors.transparent,
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                      child: Column(
                                                        children: [
                                                          Container(
                                                            width: 200,
                                                            decoration: BoxDecoration(
                                                              color: Colors.white,
                                                              border: Border.all(color: AppColors.lightBlueColor, width: 4),
                                                              borderRadius: BorderRadius.circular(16),
                                                            ),
                                                            child: Column(
                                                              children: [
                                                                ClipRRect(
                                                                  borderRadius: BorderRadius.only(
                                                                    topLeft: Radius.circular(12),
                                                                    topRight: Radius.circular(12),
                                                                  ),
                                                                  child: Container(
                                                                    width: 200,
                                                                    height: 100,
                                                                    color: Colors.grey[300],
                                                                    child: _playingIndex == index && _activeController != null
                                                                        ? _isVideoLoading
                                                                            ? Center(child: CircularProgressIndicator(color: AppColors.lightBlueColor))
                                                                            : Stack(
                                                                                children: [
                                                                                  VideoPlayer(_activeController!),
                                                                                  Positioned.fill(
                                                                                    child: Material(
                                                                                      color: Colors.transparent,
                                                                                      child: InkWell(
                                                                                        onTap: () => _handleVideoTap(index),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              )
                                                                        : _buildVideoThumbnail(videoUrl, index),
                                                                  ),
                                                                ),
                                                                Container(
                                                                  width: double.infinity,
                                                                  height: 20,
                                                                  decoration: BoxDecoration(
                                                                    color: AppColors.lightBlueColor,
                                                                    borderRadius: BorderRadius.only(
                                                                      bottomLeft: Radius.circular(12),
                                                                      bottomRight: Radius.circular(12),
                                                                    ),
                                                                  ),
                                                                  alignment: Alignment.centerLeft,
                                                                  padding: EdgeInsets.only(left: 44, right: 8),
                                                                  child: Text(
                                                                    name,
                                                                    style: TextStyle(
                                                                      color: Colors.white,
                                                                      fontWeight: FontWeight.bold,
                                                                      fontSize: 14,
                                                                    ),
                                                                    overflow: TextOverflow.ellipsis,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Positioned(
                                                      bottom: -18,
                                                      left: 8,
                                                      child: CircleAvatar(
                                                        radius: 20,
                                                        backgroundColor: Colors.white,
                                                        child: CircleAvatar(
                                                          radius: 17,
                                                          backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                                                          backgroundColor: Colors.grey[300],
                                                          child: imageUrl.isEmpty ? Icon(Icons.person, size: 18, color: Colors.grey[600]) : null,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 18),
                                                Container(
                                                  width: 200,
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Especialidad: $specialty',
                                                        style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Text(rating.toStringAsFixed(2), style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                                                          SizedBox(width: 6),
                                                          Row(
                                                            children: List.generate(5, (i) {
                                                              if (rating >= i + 1) {
                                                                return Icon(Icons.star, color: Colors.amber, size: 16);
                                                              } else if (rating > i && rating < i + 1) {
                                                                return Icon(Icons.star_half, color: Colors.amber, size: 16);
                                                              } else {
                                                                return Icon(Icons.star_border, color: Colors.amber, size: 16);
                                                              }
                                                            }),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          } catch (e, stack) {
                                            print('Error en itemBuilder de tutor:');
                                            print(e);
                                            print(stack);
                                            return Container(
                                              width: 200,
                                              height: 120,
                                              color: Colors.red[100],
                                              child: Center(child: Text('Error al mostrar tutor', style: TextStyle(color: Colors.red))),
                                            );
                                          }
                                        },
                                      ),
                          ),
                          SizedBox(height: 18),
                          // Guía paso a paso
                          Text(
                            'Una guía paso a paso',
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Desbloquea tu potencial con pasos sencillos',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          SizedBox(height: 12),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.36, // Altura variable
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _StepCard(
                                  step: 'Paso 1',
                                  title: 'Inscríbete',
                                  description: 'Crea tu cuenta rápidamente para comenzar a utilizar nuestra plataforma.',
                                  buttonText: 'Empezar',
                                  imageUrl: 'https://classgoapp.com/storage/optionbuilder/uploads/927102-18-2025_1202amPASO_1.jpg',
                                ),
                                SizedBox(width: 18),
                                _StepCard(
                                  step: 'Paso 2',
                                  title: 'Encuentra un Tutor',
                                  description: 'Busca y selecciona entre tutores calificados según tus necesidades.',
                                  buttonText: 'Buscar Ahora',
                                  imageUrl: 'https://classgoapp.com/storage/optionbuilder/uploads/776302-18-2025_1203amPASO_2.jpg',
                                ),
                                SizedBox(width: 18),
                                _StepCard(
                                  step: 'Paso 3',
                                  title: 'Programar una Sesión',
                                  description: 'Reserva fácilmente un horario conveniente para tu sesión.',
                                  buttonText: 'Empecemos',
                                  imageUrl: 'https://classgoapp.com/storage/optionbuilder/uploads/229502-18-2025_1204amPASO_3.jpg',
                                ),
                                SizedBox(width: 18),
                                _StartJourneyCard(),
                                SizedBox(width: 8), // Added SizedBox for spacing at the end
                              ],
                            ),
                          ),
                          SizedBox(height: 18),
                          // ¿Por qué elegirnos?
                          Text(
                            '¿Por qué Elegirnos?',
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Por el acceso rápido, 24/7, a tutorías personalizadas que potencian tu aprendizaje',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Accede a sesiones cortas y prácticas, diseñadas por tutores expertos para ser tus pequeños salvavidas en el aprendizaje',
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• Acceso 24/7', style: TextStyle(color: Colors.white, fontSize: 14)),
                                Text('• Tutores Expertos', style: TextStyle(color: Colors.white, fontSize: 14)),
                                Text('• Tarifas asequibles', style: TextStyle(color: Colors.white, fontSize: 14)),
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
                                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              ),
                              onPressed: () {
                                // TODO: Implement action for 'Comienza Ahora'
                              },
                              child: Text('Comienza Ahora', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          Text('Alianzas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 10),
                          SizedBox(
                            height: 180,
                            child: isLoadingAlliances
                                ? Center(child: CircularProgressIndicator(color: Colors.white))
                                : alliances.isEmpty
                                    ? Center(child: Text('No hay alianzas disponibles', style: TextStyle(color: Colors.white)))
                                    : ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: alliances.length,
                                        separatorBuilder: (_, __) => SizedBox(width: 10),
                                        itemBuilder: (context, index) {
                                          
                                          final alianza = alliances[index];
                                          final logoUrl = alianza['imagen'] ?? '';
                                          final name = alianza['titulo'] ?? '';
                                          final enlace = alianza['enlace'] ?? '';
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
                child: Container(color: Colors.black54), // Semi-transparent overlay
              ),
            ),
          // Custom Drawer Implementation (Right) - Existing
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300), // Animation duration
            curve: Curves.easeInOut,
            top: MediaQuery.of(context).padding.top + 62.0, // Position below status bar and header (estimated height)
            right: _isCustomDrawerOpen ? 0 : -(MediaQuery.of(context).size.width * 0.7), // Slide in/out from the right
            width: MediaQuery.of(context).size.width * 0.7, // Set width (adjust as needed)
            child: Container(
              height: 465.0, // Increased height to fit all options (adjust as needed)
              decoration: BoxDecoration(
                color: Color(0xFF0B3C5D), // Dark background color
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16), // Apply border radius to bottom left
                ),
                border: Border.all(color: AppColors.lightBlueColor, width: 2.0), // Ensure light blue border with thickness 2.0
                boxShadow: [ // Optional: Add shadow for depth
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(-5, 0),
                  ),
                ],
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  // Drawer Header (User Info)
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return _CustomDrawerHeader(
                        authProvider: authProvider,
                      );
                    },
                  ),
                  Divider(color: Colors.white54, thickness: 0.5), // Add a divider after header
                  // Menu Items
                  ListTile(
                    leading: Icon(Icons.dashboard, color: Colors.white),
                    title: Text('Panel', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      // TODO: Implement navigation to Panel screen
                      setState(() { _isCustomDrawerOpen = false; });
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.settings, color: Colors.white),
                    title: Text('Configuración del perfil', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      // TODO: Implement navigation to Profile Settings screen
                      setState(() { _isCustomDrawerOpen = false; });
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.calendar_today, color: Colors.white),
                    title: Text('Mis reservas', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      // TODO: Implement navigation to My Bookings screen
                      setState(() { _isCustomDrawerOpen = false; });
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.receipt, color: Colors.white),
                    title: Text('Facturas', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      // TODO: Implement navigation to Invoices screen
                      setState(() { _isCustomDrawerOpen = false; });
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.inbox, color: Colors.white),
                    title: Text('Bandeja de entrada', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      // TODO: Implement navigation to Inbox screen
                      setState(() { _isCustomDrawerOpen = false; });
                    },
                  ),
                  Divider(color: Colors.white54, thickness: 0.5), // Add a divider
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text('Salir de la cuenta', style: TextStyle(color: Colors.red)),
                    onTap: () async { // Make the function async
                      // TODO: Implement logout functionality
                      // Call the logout method from AuthProvider
                      await Provider.of<AuthProvider>(context, listen: false).clearToken();

                      // Navigate to the LoginScreen and remove all previous routes
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                            (Route<dynamic> route) => false,
                      );
                      setState(() { _isCustomDrawerOpen = false; }); // Close the drawer
                    },
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
                child: Container(color: Colors.black.withOpacity(0.5)), // Overlay semi-transparente
              ),
            ),

          // Custom Drawer Implementation (Left) - Código movido aquí
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300), // Animation duration
            curve: Curves.easeInOut,
            top: MediaQuery.of(context).padding.top + 62.0, // Position below status bar and header
            left: _isLeftDrawerOpen ? 0 : -(MediaQuery.of(context).size.width * 0.7), // Slide in/out from the left
            width: MediaQuery.of(context).size.width * 0.7, // Set width (adjust as needed)
            child: Container(
              height: 480.0, // Set a specific height (adjust as needed based on content)
              decoration: BoxDecoration(
                color: const Color(0xFF00B4D8), // Teal background color from Figma
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16), // Apply border radius to top right
                  bottomRight: Radius.circular(16), // Apply border radius to bottom right
                ),
                boxShadow: [ // Optional: Add shadow for depth
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(5, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        // Menu Items
                        ListTile(
                          title: Text('Inicio', style: TextStyle(color: Colors.white, fontSize: 16)),
                          onTap: () {
                            // TODO: Implement navigation for Inicio
                            setState(() { _isLeftDrawerOpen = false; });
                          },
                        ),
                        Divider(color: Colors.white54, thickness: 0.5), // Divider
                        ListTile(
                          title: Text('Buscar Tutores', style: TextStyle(color: Colors.white, fontSize: 16)),
                          onTap: () {
                            // TODO: Implement navigation for Buscar Tutores
                            setState(() { _isLeftDrawerOpen = false; });
                          },
                        ),
                        Divider(color: Colors.white54, thickness: 0.5), // Divider
                        ListTile(
                          title: Text('Sobre Nosotros', style: TextStyle(color: Colors.white, fontSize: 16)),
                          onTap: () {
                            // TODO: Implement navigation for Sobre Nosotros
                            setState(() { _isLeftDrawerOpen = false; });
                          },
                        ),
                        Divider(color: Colors.white54, thickness: 0.5), // Divider
                        ListTile(
                          title: Text('Como Trabajamos', style: TextStyle(color: Colors.white, fontSize: 16)),
                          onTap: () {
                            // TODO: Implement navigation for Como Trabajamos
                            setState(() { _isLeftDrawerOpen = false; });
                          },
                        ),
                        Divider(color: Colors.white54, thickness: 0.5), // Divider
                        ListTile(
                          title: Text('Preguntas', style: TextStyle(color: Colors.white, fontSize: 16)),
                          onTap: () {
                            // TODO: Implement navigation for Preguntas
                            setState(() { _isLeftDrawerOpen = false; });
                          },
                        ),
                        Divider(color: Colors.white54, thickness: 0.5), // Divider
                        ListTile(
                          title: Text('Blogs', style: TextStyle(color: Colors.white, fontSize: 16)),
                          onTap: () {
                            // TODO: Implement navigation for Blogs
                            setState(() { _isLeftDrawerOpen = false; });
                          },
                        ),
                        Divider(color: Colors.white54, thickness: 0.5), // Divider
                      ],
                    ),
                  ),
                  // Social Media Icons Section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0), // Adjust padding
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // TODO: Replace with actual social media icon widgets and onTap functionality
                        Icon(Icons.tiktok, color: Colors.white, size: 30), // Placeholder icon
                        Icon(Icons.facebook, color: Colors.white, size: 30), // Placeholder icon
                        Icon(Icons.camera_alt, color: Colors.white, size: 30), // Usar icono genérico para Instagram
                        Icon(Icons.chat, color: Colors.white, size: 30), // Usar icono genérico para Whatsapp
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
            Center(child: CircularProgressIndicator(color: AppColors.lightBlueColor)),
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
          Image.memory(
            _thumbnailCache[index]!,
            width: 200,
            height: 100,
            fit: BoxFit.cover,
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
        Container(
          color: Colors.grey[300],
          width: 200,
          height: 100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library, size: 40, color: Colors.grey[600]),
                SizedBox(height: 4),
                Text(
                  'Cargando...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
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

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    if (_activeController != null) {
      _activeController!.dispose();
    }
    _thumbnailCache.clear();
    _searchController.dispose(); // Disponer del controlador de texto
    _debounce?.cancel(); // Cancelar cualquier debounce activo
    super.dispose();
  }

  // Función para obtener la URL completa de imagen o video
  String getFullUrl(String path, String base) {
    if (path.startsWith('http')) {
      return path;
    }
    return base + path;
  }

  void _showSearchModal() {
    print('DEBUG: Iniciando _showSearchModal');
    _currentPageSubjects = 1;
    _subjects.clear();
    _hasMoreSubjects = true;
    _isFetchingMoreSubjects = false;
    _isModalLoading = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        print('DEBUG: Construyendo modal');
        bool initialLoadDone = false;

        Future<void> cargarMateriasIniciales() async {
          if (initialLoadDone) {
            print('DEBUG: Carga inicial ya realizada, retornando');
            return;
          }
          initialLoadDone = true;
          print('DEBUG: Iniciando carga de materias iniciales - Página 1');
          try {
            final response = await getAllSubjects(
              null,
              page: 1,
              perPage: _subjectsPerPage,
            );
            if (response != null && response.containsKey('data')) {
              final responseData = response['data'];
              if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
                final subjectsList = responseData['data'];
                print('DEBUG: Materias recibidas de la API: ${subjectsList.length}');
                _subjects.addAll(subjectsList);
                print('DEBUG: Materias totales: ${_subjects.length}');
              }
            }
          } catch (e) {
            print('DEBUG: Error al cargar materias iniciales: $e');
          } finally {
            _isModalLoading = false;
            if (mounted) setState(() {});
          }
        }

        // Cargar materias inmediatamente al abrir el modal
        cargarMateriasIniciales();

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            print('DEBUG: Construyendo StatefulBuilder - Materias actuales: ${_subjects.length}');
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: AppColors.darkBlue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Elige tu materia',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.white54, thickness: 0.5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Icon(Icons.auto_stories, color: AppColors.lightBlueColor),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            autofocus: true,
                            controller: _searchController,
                            onChanged: (value) {
                              if (_debounce?.isActive ?? false) _debounce!.cancel();
                              _debounce = Timer(const Duration(milliseconds: 200), () {
                                setModalState(() {
                                  _searchQuery = value;
                                  _currentPageSubjects = 1;
                                  _subjects.clear();
                                  _hasMoreSubjects = true;
                                  _isModalLoading = true;
                                });
                                _fetchSubjects(isInitialLoad: true, keyword: value).then((_) {
                                  setModalState(() {});
                                });
                              });
                            },
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '¿De que materia quieres tutoría?',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                              suffixIcon: Icon(Icons.search, color: Colors.white),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (_searchController.text.trim().isNotEmpty) {
                              final searchKeyword = _searchController.text.trim();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SearchTutorsScreen(
                                    initialKeyword: searchKeyword,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text('Buscar', style: TextStyle(color: AppColors.lightBlueColor)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isModalLoading && _subjects.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: AppColors.lightBlueColor),
                                SizedBox(height: 16),
                                Text(
                                  'Cargando materias...',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          )
                        : _subjects.isEmpty && !_hasMoreSubjects && !_isModalLoading
                            ? Center(
                                child: Text(
                                  'No hay materias disponibles',
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  children: _subjects.map((subject) {
                                    final subjectName = subject['name'] ?? 'Materia desconocida';
                                    return ListTile(
                                      leading: Icon(Icons.menu_book, color: Colors.white54, size: 20),
                                      title: Text(subjectName, style: TextStyle(color: Colors.white)),
                                      onTap: () {
                                        _searchController.text = subjectName;
                                        Navigator.pop(context);
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SearchTutorsScreen(
                                              initialKeyword: subjectName,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      print('DEBUG: Modal cerrado - Limpiando estado');
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _searchController.clear();
      _searchQuery = '';
      _isModalLoading = false;
    });
  }

  Future<void> _loadMoreSubjects() async {
    if (_isFetchingMoreSubjects || !_hasMoreSubjects) {
      print('DEBUG: _loadMoreSubjects cancelado - Fetching: $_isFetchingMoreSubjects, HasMore: $_hasMoreSubjects');
      return;
    }
    _isFetchingMoreSubjects = true;
    if (mounted) setState(() {});
    try {
      print('DEBUG: Cargando más materias - Página $_currentPageSubjects');
      final response = await getAllSubjects(
        null,
        page: _currentPageSubjects,
        perPage: _subjectsPerPage,
        keyword: _searchQuery,
      );
      if (response != null && response.containsKey('data')) {
        final responseData = response['data'];
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          final subjectsList = responseData['data'];
          final totalPages = responseData['last_page'] ?? 1;
          final currentPage = responseData['current_page'] ?? 1;
          print('DEBUG: Materias recibidas de la API: ${subjectsList.length}');
          print('DEBUG: IDs de materias recibidas: ${subjectsList.map((s) => s['id']).toList()}');
          // Filtrar duplicados
          final nuevos = subjectsList.where((s) => !_subjects.any((e) => e['id'] == s['id'])).toList();
          print('DEBUG: Materias nuevas a agregar: ${nuevos.length}');
          print('DEBUG: IDs nuevas: ${nuevos.map((s) => s['id']).toList()}');
          _subjects.addAll(nuevos);
          print('DEBUG: Materias totales tras agregar: ${_subjects.length}');
          print('DEBUG: IDs totales: ${_subjects.map((s) => s['id']).toList()}');
          _hasMoreSubjects = currentPage < totalPages;
          if (_hasMoreSubjects) {
            _currentPageSubjects = currentPage + 1;
            print('DEBUG: Siguiente página: $_currentPageSubjects');
          } else {
            print('DEBUG: No hay más páginas disponibles');
          }
        }
      }
    } catch (e) {
      print('DEBUG: Error al cargar más materias: $e');
    } finally {
      _isFetchingMoreSubjects = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _fetchSubjects({bool isInitialLoad = true, String? keyword}) async {
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
      print('DEBUG: Buscando materias - Página $_currentPageSubjects, Keyword: ${keyword ?? _searchQuery}');
      final response = await getAllSubjects(
        null,
        page: _currentPageSubjects,
        perPage: _subjectsPerPage,
        keyword: keyword ?? _searchQuery,
      );
      
      if (response != null && response.containsKey('data')) {
        final responseData = response['data'];
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
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
    
    // Actualizar la visibilidad de los items
    for (int i = 0; i < featuredTutors.length; i++) {
      final isVisible = _isItemVisible(i);
      if (_visibleItems[i] != isVisible) {
        _visibleItems[i] = isVisible;
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
  }

  bool _isItemVisible(int index) {
    if (!_scrollController.hasClients) return false;
    
    final itemPosition = index * 212.0; // 200 (ancho) + 12 (separación)
    final screenWidth = MediaQuery.of(context).size.width;
    final scrollOffset = _scrollController.offset;
    
    return itemPosition >= scrollOffset && 
           itemPosition <= scrollOffset + screenWidth;
  }

  Future<void> _preloadThumbnail(String videoUrl, int index) async {
    if (_thumbnailCache.containsKey(index)) return;
    
    try {
      if (videoUrl.isEmpty) {
        setState(() {
          _thumbnailCache[index] = null;
        });
        return;
      }

      final thumbnail = await VideoThumbnail.thumbnailData(
        video: videoUrl,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 200,
        quality: 50,
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

  Future<void> fetchFeaturedTutors() async {
    setState(() {
      isLoadingTutors = true;
    });
    try {
      final response = await findTutors(null, perPage: 1000);
      
      if (response.containsKey('data') && response['data']['list'] is List) {
        final tutors = response['data']['list'];
        setState(() {
          featuredTutors = tutors;
        });
        
        // Precargar thumbnails para los primeros tutores visibles
        for (var i = 0; i < tutors.length; i++) {
          final tutor = tutors[i];
          final profile = tutor['profile'] ?? {};
          final videoPath = profile['intro_video'] ?? '';
          if (videoPath.isNotEmpty) {
            final videoUrl = getFullUrl(videoPath, baseVideoUrl);
            _preloadThumbnail(videoUrl, i);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudieron cargar los tutores. Por favor, intente más tarde.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar los tutores. Por favor, intente más tarde.'),
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
      final response = await fetchAlliances();
      if (response.containsKey('data')) {
        setState(() {
          alliances = response['data'];
        });
      }
    } catch (e) {
      // Error silencioso para alianzas
    } finally {
      setState(() {
        isLoadingAlliances = false;
      });
    }
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
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          margin: EdgeInsets.only(top: 2, bottom: 6),
                          decoration: BoxDecoration(
                            color: Color(0xFFFF9900),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(step, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        SizedBox(height: 8),
                        Text(
                          title,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0B3C5D)),
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
                          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        ),
                        onPressed: () {},
                        child: Text(buttonText, style: TextStyle(fontWeight: FontWeight.bold)),
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
              label: Text('Empieza Ahora', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomDrawerHeader extends StatelessWidget {
  final AuthProvider authProvider;

  const _CustomDrawerHeader({required this.authProvider});

  @override
  Widget build(BuildContext context) {
    final userData = authProvider.userData;

    // Corregir la URL de la imagen si es necesario
    String? imageUrl = userData?['user']?['profile']?['image'];
    if (imageUrl != null && imageUrl.contains('https://classgoapp.com/storage/thumbnails/https://classgoapp.com/storage/thumbnails/')) {
      imageUrl = imageUrl.replaceFirst('https://classgoapp.com/storage/thumbnails/https://classgoapp.com/storage/thumbnails/', 'https://classgoapp.com/storage/thumbnails/');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // Ajustar padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar o icono de persona
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 26,
                  backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                  child: imageUrl == null ? const Icon(Icons.person, size: 28, color: Color(0xFF023E8A)) : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mostrar nombre o botón de iniciar sesión
                    if (userData != null) // Si el usuario está logueado, muestra el nombre
                      Text(
                        userData['user']?['profile']?['full_name'] ?? 'Usuario',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ) else // Si no está logueado, muestra el botón Iniciar sesión
                      InkWell(
                        onTap: () {
                          // Navegar a la pantalla de login y remover las rutas anteriores
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => LoginScreen()),
                                (Route<dynamic> route) => false,
                          );
                          // Nota: El cajón se cerrará automáticamente ya que HomeScreen se removerá del stack.
                        },
                        child: Text(
                          'Iniciar sesión',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Mostrar email si el usuario está logueado
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
        ],
      ),
    );
  }
} 