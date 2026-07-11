import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:provider/provider.dart';

import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/provider/tutor_subjects_provider.dart'; // Tu Especialista
import 'package:flutter_projects/provider/onboarding_provider.dart';

class StepOneSubjects extends StatefulWidget {
  const StepOneSubjects({Key? key}) : super(key: key);

  @override
  State<StepOneSubjects> createState() => _StepOneSubjectsState();
}

class _StepOneSubjectsState extends State<StepOneSubjects> {
  Timer? _debounce;
  String _searchQuery = '';
  // Diccionario Visual (Se mantiene para no guardar colores en base de datos)
  final Map<String, Map<String, dynamic>> _visualStyles = {
    'Contabilidad': {'icon': Icons.calculate_rounded, 'color': const Color(0xFF4A90E2)},
    'Química': {'icon': Icons.science_rounded, 'color': const Color(0xFF50E3C2)},
    'Programación': {'icon': Icons.terminal_rounded, 'color': const Color(0xFF9013FE)},
    'Inglés': {'icon': Icons.language_rounded, 'color': const Color(0xFFF5A623)},
    'Matemáticas': {'icon': Icons.functions_rounded, 'color': const Color(0xFFE1145C)},
    'Música': {'icon': Icons.music_note_rounded, 'color': const Color(0xFF8B572A)},
    'Default': {'icon': Icons.menu_book_rounded, 'color': AppColors.brandBlue},
  };

  @override
  void initState() {
    super.initState();
    // Disparar la carga de categorías reales al abrir el paso 1
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final subjectsProvider = Provider.of<TutorSubjectsProvider>(context, listen: false);
      
      // Solo cargar si la lista está vacía para no hacer peticiones innecesarias
      if (subjectsProvider.subjectGroups.isEmpty) {
        await subjectsProvider.loadGroups(auth.token!);
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error cargando grupos: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectsProvider = Provider.of<TutorSubjectsProvider>(context);
    final onboardingProvider = Provider.of<OnboardingProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSearchBar(subjectsProvider, auth),
          const SizedBox(height: 30),
          
          // Manejo de estado de carga para el Grid
          if (_searchQuery.isNotEmpty)
            _buildSearchResults(subjectsProvider, onboardingProvider)
          else if (subjectsProvider.isLoadingGroups)
            const Center(child: CircularProgressIndicator(color: AppColors.brandBlue))
          else if (subjectsProvider.subjectGroups.isEmpty)
            const Center(child: Text("No hay categorías disponibles", style: TextStyle(fontFamily: 'manrope')))
          else
            _buildCategoryGrid(subjectsProvider, onboardingProvider),
      ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Qué materias dominas?',
          style: TextStyle(fontFamily: 'outfit', fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.brandBlue),
        ),
        const SizedBox(height: 8),
        Text(
          'Selecciona las materias que te gustaría enseñar. Explora por categoría o búscalas directamente.',
          style: TextStyle(fontFamily: 'manrope', fontSize: 15, color: Colors.grey.shade600, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSearchBar(TutorSubjectsProvider subjectsProvider, AuthProvider auth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        style: const TextStyle(fontFamily: 'manrope', fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Buscar materia...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.brandCyan),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            if (value.isNotEmpty) {
              subjectsProvider.searchSubjects(
                token: auth.token!,
                userId: auth.userId!,
                keyword: value,
                isRefresh: true
              );
            }
          });
        },
      ),
    );
  }

  Widget _buildSearchResults(TutorSubjectsProvider subjectsProvider, OnboardingProvider onboardingProvider) {
    if (subjectsProvider.isSearching) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brandCyan));
    }
    
    if (subjectsProvider.availableSubjects.isEmpty) {
      return const Center(child: Text("No se encontraron materias."));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subjectsProvider.availableSubjects.length,
      itemBuilder: (context, index) {
        final subject = subjectsProvider.availableSubjects[index];
        final isSelected = onboardingProvider.tempSelectedSubjects.containsKey(subject['id']);
        return ListTile(
          title: Text(subject['name']),
          trailing: Icon(
            isSelected ? Icons.check_circle : Icons.circle_outlined,
            color: isSelected ? AppColors.brandBlue : Colors.grey,
          ),
          onTap: () {
            bool success = onboardingProvider.toggleTempSubject(subject['id'], subject['subject_group_id']);
            if (!success) {
              CustomToast.show(context, 'Solo puedes seleccionar hasta 3 materias al inicio.', isSuccess: false);
            }
          },
        );
      },
    );
  }

  Widget _buildCategoryGrid(TutorSubjectsProvider subjectsProvider, OnboardingProvider onboardingProvider) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: subjectsProvider.subjectGroups.length,
      itemBuilder: (context, index) {
        final category = subjectsProvider.subjectGroups[index];
        final String categoryName = category['name'] ?? 'Desconocida';
        final int categoryId = category['id'];

        final style = _visualStyles[categoryName] ?? _visualStyles['Default']!;
        final int selectedCount = onboardingProvider.getSelectedCountForGroup(categoryId);

        return _CategoryCard(
          name: categoryName,
          icon: style['icon'],
          color: style['color'],
          selectedCount: selectedCount,
          onTap: () => _openSubjectModal(context, categoryName, categoryId, style['color']),
        );
      },
    );
  }

  void _openSubjectModal(BuildContext context, String categoryName, int categoryId, Color brandColor) {
    // Al abrir el modal, disparamos la búsqueda de materias para esa categoría específica
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final subjectsProvider = Provider.of<TutorSubjectsProvider>(context, listen: false);
    
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);

    subjectsProvider.searchSubjects(
      token: auth.token!, 
      userId: auth.userId!, 
      groupId: categoryId, 
      isRefresh: true
    ).catchError((e) {
      if (kDebugMode) debugPrint("Error al cargar materias del grupo: $e");
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return ChangeNotifierProvider.value(
          value: onboardingProvider,
          child: _SubjectSelectionModal(
            categoryName: categoryName,
            categoryId: categoryId,
            brandColor: brandColor,
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// SUB-WIDGETS 
// -----------------------------------------------------------------------------

class _CategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final int selectedCount;
  final VoidCallback onTap;

  const _CategoryCard({required this.name, required this.icon, required this.color, required this.selectedCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = selectedCount > 0;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: hasSelection ? color.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: hasSelection ? color : Colors.grey.withOpacity(0.2), width: hasSelection ? 2.5 : 1.5),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'outfit', fontWeight: hasSelection ? FontWeight.bold : FontWeight.w600, color: hasSelection ? color : AppColors.brandBlue),
                  ),
                ],
              ),
            ),
          ),
          if (hasSelection)
            Positioned(
              top: -8, right: -8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                child: Text(selectedCount.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }
}

class _SubjectSelectionModal extends StatelessWidget {
  final String categoryName;
  final int categoryId;
  final Color brandColor;

  const _SubjectSelectionModal({required this.categoryName, required this.categoryId, required this.brandColor});

  @override
  Widget build(BuildContext context) {
    // Escuchamos los proveedores dentro del modal para que se reconstruya al cargar
    final subjectsProvider = Provider.of<TutorSubjectsProvider>(context);
    final onboardingProvider = Provider.of<OnboardingProvider>(context);

    // Filtramos solo las materias que corresponden a este grupo en la vista
    final List<Map<String, dynamic>> categorySubjects = subjectsProvider.availableSubjects
        .where((s) => s['subject_group_id'] == categoryId)
        .toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(categoryName, style: const TextStyle(fontFamily: 'outfit', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.brandBlue)),
              IconButton(icon: const Icon(Icons.close_rounded, color: Colors.grey), onPressed: () => Navigator.pop(context))
            ],
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: subjectsProvider.isSearching 
              ? Center(child: CircularProgressIndicator(color: brandColor))
              : categorySubjects.isEmpty
                  ? const Center(child: Text('No hay materias disponibles aquí.', style: TextStyle(fontFamily: 'manrope', color: Colors.grey)))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: categorySubjects.length,
                      itemBuilder: (context, index) {
                        final subject = categorySubjects[index];
                        final subjectId = subject['id'];
                        // Verificamos si este ID está en el Orquestador
                        final isSelected = onboardingProvider.tempSelectedSubjects.containsKey(subjectId);

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(subject['name'] ?? 'Sin nombre', style: const TextStyle(fontFamily: 'manrope', fontSize: 16)),
                          trailing: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: isSelected ? brandColor : Colors.transparent,
                              border: Border.all(color: isSelected ? brandColor : Colors.grey.shade400, width: 2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                          ),
                          onTap: () {
                            bool success = onboardingProvider.toggleTempSubject(subjectId, categoryId);
                            if (!success) {
                              CustomToast.show(context, "Límite alcanzado. Solo 3 materias permitidas.", isSuccess: false);
                            }
                          },
                        );
                      },
                    ),
          ),
          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Confirmar', style: TextStyle(fontFamily: 'outfit', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}