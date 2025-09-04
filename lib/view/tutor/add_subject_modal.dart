import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/provider/tutor_subjects_provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class AddSubjectModal extends StatefulWidget {
  @override
  _AddSubjectModalState createState() => _AddSubjectModalState();
}

class _AddSubjectModalState extends State<AddSubjectModal> {
  final _formKey = GlobalKey<FormState>();
  Set<int> _selectedSubjectIds = {}; // Cambiar a Set para múltiples selecciones
  String? _selectedImagePath;
  bool _isLoading = false;
  bool _isLoadingSubjects = true;
  bool _subjectsLoadError = false;
  List<Map<String, dynamic>> _availableSubjects = [];
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoadingMore = false;
  ScrollController _scrollController = ScrollController();
  TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAvailableSubjects();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore &&
        _currentPage < _lastPage &&
        !_subjectsLoadError) {
      _loadMoreSubjects();
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
      _searchSubjects();
    });
  }

  Future<void> _searchSubjects() async {
    if (_searchQuery.trim().isEmpty) {
      _loadAvailableSubjects();
      return;
    }
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final subjectsProvider = Provider.of<TutorSubjectsProvider>(context, listen: false);
      
      if (authProvider.token == null) return;

      final response = await getAllSubjects(authProvider.token!,
          page: 1, perPage: 20, keyword: _searchQuery.trim());

      if (response['status'] == 200 &&
          response['data'] != null &&
          response['data']['data'] != null) {
        final List<dynamic> subjectsData = response['data']['data'];
        
        // Obtener las materias que el tutor ya tiene
        final currentTutorSubjects = subjectsProvider.subjects;
        final currentSubjectIds = currentTutorSubjects.map((subject) => subject.subjectId).toSet();
        
        // Filtrar las materias que el tutor ya tiene
        final filteredSubjects = subjectsData.where((subject) => 
          !currentSubjectIds.contains(subject['id'])
        ).toList();
        
        setState(() {
          _availableSubjects = filteredSubjects
              .map((subject) => {
                    'id': subject['id'],
                    'name': subject['name'],
                  })
              .toList();
          _isLoadingSubjects = false;
          _subjectsLoadError = false;
          _currentPage = response['data']['current_page'] ?? 1;
          _lastPage = response['data']['last_page'] ?? 1;
        });
        
        print('🔍 DEBUG - Búsqueda: Materias disponibles después del filtro: ${_availableSubjects.length}');
      } else {
        setState(() {
          _isLoadingSubjects = false;
          _subjectsLoadError = true;
        });
      }
    } catch (e) {
      print('Error searching subjects: $e');
      setState(() {
        _isLoadingSubjects = false;
        _subjectsLoadError = true;
      });
    }
  }

  Future<void> _loadAvailableSubjects() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final subjectsProvider = Provider.of<TutorSubjectsProvider>(context, listen: false);
      
      if (authProvider.token == null) return;

      final response =
          await getAllSubjects(authProvider.token!, page: 1, perPage: 20);

      if (response['status'] == 200 &&
          response['data'] != null &&
          response['data']['data'] != null) {
        final List<dynamic> subjectsData = response['data']['data'];
        
        // Obtener las materias que el tutor ya tiene
        final currentTutorSubjects = subjectsProvider.subjects;
        final currentSubjectIds = currentTutorSubjects.map((subject) => subject.subjectId).toSet();
        
        // Filtrar las materias que el tutor ya tiene
        final filteredSubjects = subjectsData.where((subject) => 
          !currentSubjectIds.contains(subject['id'])
        ).toList();
        
        setState(() {
          _availableSubjects = filteredSubjects
              .map((subject) => {
                    'id': subject['id'],
                    'name': subject['name'],
                  })
              .toList();
          _isLoadingSubjects = false;
          _subjectsLoadError = false;
          _currentPage = response['data']['current_page'] ?? 1;
          _lastPage = response['data']['last_page'] ?? 1;
        });
        
        print('🔍 DEBUG - Materias disponibles después del filtro: ${_availableSubjects.length}');
        print('🔍 DEBUG - Materias del tutor actuales: ${currentTutorSubjects.length}');
      } else {
        setState(() {
          _isLoadingSubjects = false;
          _subjectsLoadError = true;
        });
      }
    } catch (e) {
      print('Error loading all subjects: $e');
      setState(() {
        _isLoadingSubjects = false;
        _subjectsLoadError = true;
      });
    }
  }

  Future<void> _loadMoreSubjects() async {
    if (_isLoadingMore || _currentPage >= _lastPage) return;
    setState(() {
      _isLoadingMore = true;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final subjectsProvider = Provider.of<TutorSubjectsProvider>(context, listen: false);
      
      final nextPage = _currentPage + 1;
      final response = await getAllSubjects(authProvider.token!,
          page: nextPage, perPage: 20);
      if (response['status'] == 200 &&
          response['data'] != null &&
          response['data']['data'] != null) {
        final List<dynamic> subjectsData = response['data']['data'];
        
        // Obtener las materias que el tutor ya tiene
        final currentTutorSubjects = subjectsProvider.subjects;
        final currentSubjectIds = currentTutorSubjects.map((subject) => subject.subjectId).toSet();
        
        // Filtrar las materias que el tutor ya tiene
        final filteredSubjects = subjectsData.where((subject) => 
          !currentSubjectIds.contains(subject['id'])
        ).toList();
        
        setState(() {
          _availableSubjects.addAll(filteredSubjects.map((subject) => {
                'id': subject['id'],
                'name': subject['name'],
              }));
          _currentPage = response['data']['current_page'] ?? _currentPage;
          _lastPage = response['data']['last_page'] ?? _lastPage;
        });
        
        print('🔍 DEBUG - Cargar más: Materias filtradas añadidas: ${filteredSubjects.length}');
      }
    } catch (e) {
      print('Error loading more subjects: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _addSubjects() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjectIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor selecciona al menos una materia')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final subjectsProvider =
        Provider.of<TutorSubjectsProvider>(context, listen: false);

    int successCount = 0;
    int totalCount = _selectedSubjectIds.length;

    // Agregar materias una por una
    for (int subjectId in _selectedSubjectIds) {
      final success = await subjectsProvider.addTutorSubjectToApi(
        authProvider,
        subjectId,
        '', // Sin descripción
        _selectedImagePath,
      );

      if (success) {
        successCount++;
      }
    }

    setState(() {
      _isLoading = false;
    });

    Navigator.of(context).pop();

    // Refrescar la lista de materias del tutor después de agregar
    await subjectsProvider.loadTutorSubjects(authProvider);

    if (successCount == totalCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount materias agregadas exitosamente'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } else if (successCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '$successCount de $totalCount materias agregadas. Algunas fallaron.'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(subjectsProvider.error ?? 'Error al agregar las materias'),
          backgroundColor: AppColors.redColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkBlue,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryGreen, AppColors.orangeprimary],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Agregar Materias',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        'Selecciona múltiples materias',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Indicador de materias seleccionadas
            if (_selectedSubjectIds.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_selectedSubjectIds.length} materia${_selectedSubjectIds.length == 1 ? '' : 's'} seleccionada${_selectedSubjectIds.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 16),

            // Selector de materia
            Text(
              'Materias Disponibles',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            if (_isLoadingSubjects)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Cargando materias...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              )
            else if (_subjectsLoadError)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No se pudieron cargar las materias. Intenta más tarde.',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    // Campo de búsqueda
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Buscar materia...',
                          hintStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.search, color: Colors.white70),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon:
                                      Icon(Icons.clear, color: Colors.white70),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: AppColors.primaryGreen),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 250,
                      child: _availableSubjects.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: AppColors.primaryGreen.withOpacity(0.7),
                                    size: 48,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    '¡Ya tienes todas las materias disponibles!',
                                    style: TextStyle(
                                      color: AppColors.primaryGreen.withOpacity(0.8),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Has agregado todas las materias que están disponibles en el sistema.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: true,
                              child: ListView.builder(
                                controller: _scrollController,
                                itemCount: _availableSubjects.length +
                                    (_isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= _availableSubjects.length) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  final subject = _availableSubjects[index];
                                  return CheckboxListTile(
                                    value:
                                        _selectedSubjectIds.contains(subject['id']),
                                    onChanged: _subjectsLoadError
                                        ? null
                                        : (bool? value) {
                                            setState(() {
                                              if (value == true) {
                                                _selectedSubjectIds
                                                    .add(subject['id']);
                                              } else {
                                                _selectedSubjectIds
                                                    .remove(subject['id']);
                                              }
                                            });
                                          },
                                    title: Text(subject['name'],
                                        style: TextStyle(color: Colors.white)),
                                    activeColor: AppColors.primaryGreen,
                                    checkColor: Colors.white,
                                  );
                                },
                              ),
                            ),
                    ),
                    if (_currentPage < _lastPage &&
                        !_isLoadingMore &&
                        _searchQuery.trim().isEmpty)
                      TextButton.icon(
                        onPressed: _loadMoreSubjects,
                        icon: Icon(Icons.add, color: AppColors.primaryGreen),
                        label: Text('Cargar más',
                            style: TextStyle(color: AppColors.primaryGreen)),
                      ),
                  ],
                ),
              ),
            SizedBox(height: 24),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _isLoading || _subjectsLoadError ? null : _addSubjects,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _selectedSubjectIds.isEmpty
                                ? 'Agregar'
                                : 'Agregar ${_selectedSubjectIds.length} materia${_selectedSubjectIds.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
