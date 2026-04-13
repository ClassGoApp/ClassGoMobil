import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/api_structure/api_service.dart';

class TutorSubjectSelectionScreen extends StatefulWidget {
  const TutorSubjectSelectionScreen({Key? key}) : super(key: key);

  @override
  State<TutorSubjectSelectionScreen> createState() => _TutorSubjectSelectionScreenState();
}

class _TutorSubjectSelectionScreenState extends State<TutorSubjectSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _availableSubjects = [];
  final Set<int> _selectedSubjectIds = {};
  
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadAvailableSubjects(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _lastPage) {
      _loadAvailableSubjects(reset: false);
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _loadAvailableSubjects(reset: true);
    });
  }

  Future<void> _loadAvailableSubjects({required bool reset}) async {
    if (reset) {
      if (mounted) setState(() { _isLoading = true; _currentPage = 1; });
    } else {
      if (mounted) setState(() { _isLoadingMore = true; });
    }

    try {
      final query = _searchController.text.trim();
      
      final response = await getAllSubjects(
        null, 
        page: reset ? 1 : _currentPage + 1, 
        perPage: 20,
        keyword: query.isEmpty ? null : query
      );

      print("Respuesta del servidor: $response");

      if (!mounted) return;

      if (response['status'] == 200 && response['data'] != null) {
        final List<dynamic> subjectsData = response['data']['data'];
        
        final mapped = subjectsData.map((s) => {'id': s['id'], 'name': s['name']}).toList();
        
        print("Materias mapeadas listas para la pantalla: ${mapped.length}");
        
        setState(() {
          if (reset) {
            _availableSubjects = mapped;
          } else {
            _availableSubjects.addAll(mapped);
          }
          _currentPage = response['data']['current_page'] ?? 1;
          _lastPage = response['data']['last_page'] ?? 1;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print("ERROR CRÍTICO AL CARGAR MATERIAS: $e");
      if (mounted) setState(() { _isLoading = false; _isLoadingMore = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Elige tus Materias',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // BUSCADOR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: "Buscar materia...",
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.brandCyan),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.brandCyan))
                : ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: _availableSubjects.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _availableSubjects.length) {
                        return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
                      }
                      final item = _availableSubjects[index];
                      final isSelected = _selectedSubjectIds.contains(item['id']);
                      
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            isSelected ? _selectedSubjectIds.remove(item['id']) : _selectedSubjectIds.add(item['id']);
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.brandCyan.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? AppColors.brandCyan : Colors.grey.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                                color: isSelected ? AppColors.brandCyan : Colors.grey,
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  item['name'],
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? AppColors.brandCyan : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
        child: ElevatedButton(
          onPressed: _selectedSubjectIds.isEmpty ? null : () {
            final ids = _selectedSubjectIds.toList();
            print('🚀 [Paso 1 - Pantalla Materias] El usuario presionó registrarse. Enviando IDs: $ids');
            
            Navigator.pop(context, ids);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.primaryGreen,
            disabledBackgroundColor: Colors.grey[300], // Color cuando está bloqueado
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            _selectedSubjectIds.isEmpty 
              ? "Selecciona al menos una materia" 
              : "Registrarse (${_selectedSubjectIds.length} materias)",
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}