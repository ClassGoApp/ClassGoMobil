import 'dart:convert';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/components/role_based_navigation.dart';
import 'package:flutter_projects/view/student/instant_tutoring/widgets/radar_search_screen.dart';
import 'package:flutter_projects/view/student/widgets/student_bottom_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InstantTutoringScreen extends StatefulWidget {
  const InstantTutoringScreen({
    super.key,
  });

  @override
  State<InstantTutoringScreen> createState() => _InstantTutoringScreenState();
}

class _InstantTutoringScreenState extends State<InstantTutoringScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  // ==========================================
  // ⚡ VARIABLES DE ALTO RENDIMIENTO
  // ==========================================
  bool _isLoadingData = true;
  List<dynamic> _allSubjects = [];
  List<dynamic> _searchResults = [];
  Map<String, List<dynamic>> _subjectsByCategory = {}; // Búsqueda O(1)

  // 🎨 TUS CATEGORÍAS EXACTAS CON DISEÑO PREMIUM
  final List<Map<String, dynamic>> _uiCategories = [
    {'name': 'Primaria', 'icon': Icons.backpack_rounded, 'color': 0xFFF59E0B},
    {'name': 'Secundaria', 'icon': Icons.school_rounded, 'color': 0xFF3B82F6},
    {
      'name': 'Ciencias Exactas',
      'icon': Icons.calculate_rounded,
      'color': 0xFF10B981
    },
    {
      'name': 'Ingeniería Avanzada',
      'icon': Icons.precision_manufacturing_rounded,
      'color': 0xFFEF4444
    },
    {
      'name': 'Ciencias Sociales y Económicas',
      'icon': Icons.public_rounded,
      'color': 0xFF8B5CF6
    },
    {'name': 'Idiomas', 'icon': Icons.translate_rounded, 'color': 0xFFEC4899},
    {
      'name': 'Marketing y Comunicación Digital',
      'icon': Icons.campaign_rounded,
      'color': 0xFFF97316
    },
    {
      'name': 'Arte y Diseño',
      'icon': Icons.palette_rounded,
      'color': 0xFF14B8A6
    },
    {
      'name': 'Gastronomía y Repostería',
      'icon': Icons.restaurant_rounded,
      'color': 0xFFEAB308
    },
    {
      'name': 'Ingeniería y Tecnología',
      'icon': Icons.computer_rounded,
      'color': 0xFF6366F1
    },
    {
      'name': 'Psicología y Desarrollo Personal',
      'icon': Icons.psychology_rounded,
      'color': 0xFF06B6D4
    },
    {
      'name': 'Deporte y Bienestar',
      'icon': Icons.fitness_center_rounded,
      'color': 0xFF84CC16
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadJsonData(); 
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _confirmarYNavegarAlRadar(BuildContext context, String materiaName, String materiaId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Confirmar Búsqueda", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text("¿Deseas buscar un tutor disponible ahora mismo para la materia de $materiaName?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RadarSearchScreen(
                      subjectName: materiaName,
                      subjectId: materiaId,
                    ),
                  ),
                );
              },
              child: const Text("Sí, Buscar Tutor", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // 🧠 CARGA Y PRE-INDEXACIÓN DEL JSON (Magia de rendimiento)
  // Future<void> _loadJsonData() async {
  //   try {
  //     final String jsonString = await rootBundle.loadString('assets/materias.json');
  //     final List<dynamic> jsonData = jsonDecode(jsonString);
  //     final Map<String, List<dynamic>> grouped = {};
  //     for (var item in jsonData) {
  //       final cat = item['Subcategoría'];
  //       if (cat != null) {
  //         grouped.putIfAbsent(cat, () => []).add(item);
  //       }
  //     }
  //     if (mounted) {
  //       setState(() {
  //         _allSubjects = jsonData;
  //         _subjectsByCategory = grouped;
  //         _isLoadingData = false;
  //       });
  //     }
  //   } catch (e) {
  //     print("🔥 Error cargando materias.json: $e");
  //     if (mounted) setState(() => _isLoadingData = false);
  //   }
  // }
  // Future<void> _loadJsonData() async {
  //   final List<dynamic> hardcodedData = [
  //     {"Subcategoría": "Primaria", "Materia": "Matemáticas para Primaria"},
  //     {"Subcategoría": "Secundaria", "Materia": "Física para Secundaria"},
  //     {"Subcategoría": "Idiomas", "Materia": "Inglés Básico"},
  //     {"Subcategoría": "Ciencias Exactas", "Materia": "Cálculo I"},
  //     {"Subcategoría": "Ingeniería Avanzada", "Materia": "Termodinámica"},
  //   ];

  //   final Map<String, List<dynamic>> grouped = {};
  //   for (var item in hardcodedData) {
  //     grouped.putIfAbsent(item['Subcategoría'], () => []).add(item);
  //   }

  //   if (mounted) {
  //     setState(() {
  //       _allSubjects = hardcodedData;
  //       _subjectsByCategory = grouped;
  //       _isLoadingData = false; // Apagamos el circulito de carga
  //     });
  //   }
  // }


  // Importa tu archivo de API arriba: 
  // import 'ruta/hacia/tu/api_service.dart';

  Future<void> _loadJsonData() async {
    try {

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // Llama al api_service
      final jsonData = await getCategoriasMaterias(token);
      
      final List<dynamic> categoriasApi = jsonData['data'];
      final Map<String, List<dynamic>> grouped = {};
      final List<dynamic> allSubjectsFlat = [];

      for (var cat in categoriasApi) {
        String catName = cat['categoria'];
        List<dynamic> materiasArray = cat['materias'];
        List<dynamic> materiasAdaptadas = [];

        for (var mat in materiasArray) {
          var subjectAdapted = {
            'Subcategoría': catName,
            'Materia': mat['materia'], 
            'id_materia': mat['id_materia'] 
          };
          materiasAdaptadas.add(subjectAdapted);
          allSubjectsFlat.add(subjectAdapted);
        }

        grouped[catName] = materiasAdaptadas;
      }

      if (mounted) {
        setState(() {
          _allSubjects = allSubjectsFlat;
          _subjectsByCategory = grouped;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print("🔥 Error al cargar materias: $e");
      
      if (mounted) setState(() => _isLoadingData = false);
    }
  }
  // 🔍 BUSCADOR OPTIMIZADO CON DEBOUNCE (Evita trabar el teclado)
  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      setState(() {
        if (query.trim().isEmpty) {
          _searchResults = [];
        } else {
          final lowerQuery = query.toLowerCase();
          _searchResults = _allSubjects.where((subject) {
            final materia = subject['Materia']?.toString().toLowerCase() ?? '';
            return materia.contains(lowerQuery);
          }).toList();
        }
      });
    });
  }

  // 💡 BOTTOM SHEET: CARGA INSTANTÁNEA GRACIAS A LA PRE-INDEXACIÓN O(1)
  void _openCategoryBottomSheet(
      BuildContext context, String categoryName, int colorHex) {
    // Buscamos directo en el diccionario. Si no hay, devolvemos lista vacía.
    final subjects = _subjectsByCategory[categoryName] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.70, // 70% de pantalla
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Color(colorHex).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child:
                          Icon(Icons.category_rounded, color: Color(colorHex)),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        categoryName,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A)),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 30),

              // LISTA DE MATERIAS DENTRO DE LA CATEGORÍA
              Expanded(
                child: subjects.isEmpty
                    ? const Center(
                        child: Text('Próximamente materias aquí...',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: subjects.length,
                        itemBuilder: (context, index) {
                          final subject = subjects[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 4),
                            title: Text(subject['Materia'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155))),
                            trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: Colors.grey),
                            onTap: () {
                              // 1. Cerramos el BottomSheet de categorías
                              Navigator.pop(context);

                              _confirmarYNavegarAlRadar(
                                context, 
                                subject['Materia'], 
                                subject['id_materia'].toString()
                              );},
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: _isLoadingData
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1E40AF)))
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. HEADER
                  SliverAppBar(
                    backgroundColor: const Color(0xFFF8FAFC),
                    floating: true,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    title: const Text(
                      'Tutor Instantáneo',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A)),
                    ),
                    // leading: IconButton(
                    //   icon: const Icon(Icons.arrow_back_rounded,
                    //       color: Color(0xFF0F172A)),
                    //   onPressed: () => Navigator.of(context).pop(),
                    // ),
                  ),

                  // 2. BUSCADOR
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¿Qué quieres\naprender hoy?',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'outfit',
                                  color: const Color(0xFF0F172A),
                                  height: 1.1,
                                ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5)),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              decoration: InputDecoration(
                                hintText: 'Ej. Matemáticas, Inglés...',
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade400),
                                prefixIcon: const Icon(Icons.search_rounded,
                                    color: Color(0xFF1E40AF)),
                                suffixIcon: isSearching
                                    ? IconButton(
                                        icon: const Icon(Icons.clear,
                                            color: Colors.grey, size: 20),
                                        onPressed: () {
                                          _searchController.clear();
                                          _onSearchChanged('');
                                          FocusScope.of(context).unfocus();
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. LÓGICA CONDICIONAL: ¿MUESTRA LISTA DE BÚSQUEDA O EL GRID DE CATEGORÍAS?
                  if (isSearching) ...[
                    // MODO BÚSQUEDA: Muestra los resultados limpios
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 24, bottom: 10, top: 10),
                        child: Text(
                          "Resultados (${_searchResults.length})",
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey),
                        ),
                      ),
                    ),
                    _searchResults.isEmpty
                        ? const SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(40.0),
                                child: Text("No se encontraron materias 😕",
                                    style: TextStyle(color: Colors.grey)),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final subject = _searchResults[index];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 2),
                                  title: Text(subject['Materia'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF334155))),
                                  subtitle: Text(subject['Subcategoría'],
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12)),
                                  trailing: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: Colors.grey),
                                  onTap: () {
                                    FocusScope.of(context).unfocus(); 
                                    
                                    _confirmarYNavegarAlRadar(
                                      context, 
                                      subject['Materia'], 
                                      subject['id_materia'].toString()
                                    );
                                  },
                                );
                              },
                              childCount: _searchResults.length,
                            ),
                          ),
                  ] else ...[
                    // MODO NORMAL: Muestra el Grid de Categorías
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Text(
                          'Explorar Categorías',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A)),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 15,
                          crossAxisSpacing: 15,
                          childAspectRatio:
                              1.15, // Tarjetas un poco más cuadradas y estéticas
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final cat = _uiCategories[index];
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _openCategoryBottomSheet(
                                    context, cat['name'], cat['color']);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4)),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Color(cat['color'])
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Icon(cat['icon'],
                                            color: Color(cat['color']),
                                            size: 26),
                                      ),
                                      Text(
                                        cat['name'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'manrope',
                                            fontSize: 14,
                                            color: Color(0xFF0F172A),
                                            height: 1.2),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: _uiCategories.length,
                        ),
                      ),
                    ),
                  ],

                  const SliverToBoxAdapter(
                      child: SizedBox(height: 100)), // Espacio para el navbar
                ],
              ),
      ),
      // bottomNavigationBar: StudentBottomNav(
      //   currentIndex: -1, // -1 porque no es ninguna pestaña principal
      //   onTap: (index) {
      //     Navigator.of(context).pushAndRemoveUntil(
      //       PageRouteBuilder(
      //         pageBuilder: (context, animation, secondaryAnimation) =>
      //             const RoleBasedNavigation(),
      //         transitionDuration: Duration.zero,
      //       ),
      //       (route) => false,
      //     );
      //   },
      //   onCenterTap: () => HapticFeedback.lightImpact(),
      // ),
    
    );
  }
}
