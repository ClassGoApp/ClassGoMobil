import 'package:flutter_projects/api_structure/api_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/student/instant_tutoring/widgets/radar_search_screen.dart';
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

  bool _isLoadingData = true;
  bool _isCheckingActive = false;
  Map<String, dynamic>? _activeBatch;
  List<dynamic> _allSubjects = [];
  List<dynamic> _searchResults = [];
  Map<String, List<dynamic>> _subjectsByCategory = {};
  List<Map<String, dynamic>> _gridCategories = [];

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
    _initFlow();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _initFlow() async {
    await _loadJsonData();
    await _checkActiveSession();

    if (_activeBatch != null && mounted) {
      final subjectId = _activeBatch!['subject_id'].toString();
      final subjectName = _getSubjectNameFromId(subjectId);

      _navegarAlRadar(
          subjectName, subjectId, _activeBatch!['seconds_left'] ?? 300);
    }
  }

  Future<void> _checkActiveSession() async {
    if (!mounted) return;
    setState(() => _isCheckingActive = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final result = await checkActiveBatch(token);
      if (result['active'] == true) {
        _activeBatch = result;
      } else {
        _activeBatch = null;
      }
    } catch (e) {
      _activeBatch = null;
    } finally {
      if (mounted) {
        setState(() => _isCheckingActive = false);
      }
    }
  }

  String _getSubjectNameFromId(String subjectId) {
    for (var subject in _allSubjects) {
      if (subject['id_materia'].toString() == subjectId) {
        return subject['Materia'];
      }
    }
    return "Tutoría Activa";
  }

  void _confirmarYNavegarAlRadar(
      BuildContext context, String materiaName, String materiaId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Confirmar Búsqueda",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
              "¿Deseas buscar un tutor disponible ahora mismo para la materia de $materiaName?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _navegarAlRadar(materiaName, materiaId, 300);
              },
              child: const Text("Sí, Buscar Tutor",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadJsonData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final jsonData = await getCategoriasMaterias(token);

      final List<dynamic> categoriasApi = jsonData['data'];
      final Map<String, List<dynamic>> grouped = {};
      final List<dynamic> allSubjectsFlat = [];

      for (var cat in categoriasApi) {
        String catName = cat['categoria'] ?? 'Sin Categoría';
        List<dynamic> materiasArray = cat['materias'] ?? [];
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

      _gridCategories = categoriasApi.map((cat) {
        final name = cat['categoria'] ?? '';
        final matched = _uiCategories.cast<Map<String, dynamic>?>().firstWhere(
              (u) => u?['name'] == name,
              orElse: () => null,
            );
        return {
          'name': name,
          'icon': matched?['icon'] ?? Icons.category_rounded,
          'color': matched?['color'] ?? 0xFF6366F1,
        };
      }).toList();

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

  void _procesarToqueMateria(String materiaName, String materiaId) {
    FocusScope.of(context).unfocus();

    if (_isCheckingActive) return;

    if (_activeBatch != null) {
      final activeSubjectId = _activeBatch!['subject_id'].toString();
      final activeSubjectName = _getSubjectNameFromId(activeSubjectId);

      // 💡 CIRUGÍA 1: Conversión segura para evitar el crasheo de Double a Int
      final rawSeconds = _activeBatch!['seconds_left'];
      final int secondsToPass = (rawSeconds is num) ? rawSeconds.toInt() : 300;

      // Usamos la variable convertida "secondsToPass"
      _navegarAlRadar(activeSubjectName, activeSubjectId, secondsToPass,
          isRecovered: true);
    } else {
      _confirmarYNavegarAlRadar(context, materiaName, materiaId);
    }
  }

  // 💡 Le agregamos el parámetro opcional "isRecovered"
  void _navegarAlRadar(String name, String id, int seconds,
      {bool isRecovered = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RadarSearchScreen(
          subjectName: name,
          subjectId: id,
          timerSeconds: seconds,
          isRecovered: isRecovered, // 💡 Se lo pasamos al Radar
        ),
      ),
    ).then((_) {
      _checkActiveSession();
    });
  }

  // BUSCADOR OPTIMIZADO CON DEBOUNCE (Evita trabar el teclado)
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

  // CARGA INSTANTÁNEA GRACIAS A LA PRE-INDEXACIÓN O(1)
  void _openCategoryBottomSheet(
      BuildContext context, String categoryName, int colorHex) {
    FocusScope.of(context).unfocus();
    final subjects = _subjectsByCategory[categoryName] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.70,
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
                        child: Text('Error de conexión.',
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
                              Navigator.pop(context);

                              _procesarToqueMateria(subject['Materia'],
                                  subject['id_materia'].toString());
                            },
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
            : Stack(children: [
                CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    // 1. HEADER
                    SliverAppBar(
                      backgroundColor: const Color(0xFFF4F4FB),
                      pinned: true,
                      floating: false,
                      elevation: 1,
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
                              '¿En qué te\nacompañamos hoy?',
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
                                autofocus: false,
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

                    if (isSearching) ...[
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
                                  child: Text("No se encontraron materias.",
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

                                      _procesarToqueMateria(subject['Materia'],
                                          subject['id_materia'].toString());
                                    },
                                  );
                                },
                                childCount: _searchResults.length,
                              ),
                            ),
                    ] else ...[
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
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
                            childAspectRatio: 1.15,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final cat = _gridCategories[index];
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
                            childCount: _gridCategories.length,
                          ),
                        ),
                      ),
                    ],

                    const SliverToBoxAdapter(
                        child: SizedBox(height: 100)), // Espacio para el navbar
                  ],
                ),
                if (_isCheckingActive)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                        color: Color(0xFF1E40AF), minHeight: 3),
                  ),
              ]),
      ),
    );
  }
}
