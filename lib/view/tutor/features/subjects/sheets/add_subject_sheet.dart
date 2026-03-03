import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/provider/tutor_subjects_provider.dart';
import 'package:flutter_projects/api_structure/api_service.dart';

const String kFontFamily = 'outfit';

class AddSubjectSheet extends StatefulWidget {
  const AddSubjectSheet({Key? key}) : super(key: key);

  @override
  State<AddSubjectSheet> createState() => _AddSubjectSheetState();
}

class _AddSubjectSheetState extends State<AddSubjectSheet> {
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _availableSubjects = [];
  List<Map<String, dynamic>> _filteredSubjects = [];
  final Set<int> _selectedSubjectIds = {};
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableSubjects();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSubjects = _availableSubjects.where((subject) {
        return subject['name'].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  // 1. CARGAMOS LAS MATERIAS DISPONIBLES
  Future<void> _loadAvailableSubjects() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final subjectsProvider = Provider.of<TutorSubjectsProvider>(context, listen: false);
      
      if (authProvider.token == null) return;

      final response = await getAllSubjects(authProvider.token!, page: 1, perPage: 100);

      if (!mounted) return;

      if (response['status'] == 200 && response['data'] != null && response['data']['data'] != null) {
        final List<dynamic> subjectsData = response['data']['data'];
        
        final currentSubjectIds = subjectsProvider.subjects.map((s) => s.subjectId).toSet();
        
        // Filtramos las que ya tiene el tutor
        final filtered = subjectsData.where((s) => !currentSubjectIds.contains(s['id'])).toList();
        
        setState(() {
          _availableSubjects = filtered.map((s) => {'id': s['id'], 'name': s['name']}).toList();
          _filteredSubjects = List.from(_availableSubjects);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading all subjects: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // 2. GUARDAR SELECCIÓN MÚLTIPLE
  Future<void> _saveSelections() async {
    if (_selectedSubjectIds.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);

    // 1. Capturamos herramientas antes de los await
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final subjectsProvider = Provider.of<TutorSubjectsProvider>(context, listen: false);

    int successCount = 0;
    int totalCount = _selectedSubjectIds.length;

    try{
      // 2. Preparamos todas las peticiones a la Base de Datos
      List<Future<bool>> futures = []; 
       for (int subjectId in _selectedSubjectIds) {
         futures.add(subjectsProvider.addTutorSubjectToApi(
           authProvider,
           subjectId,
           '', 
           null, 
         ));
       }
      // 3. DISPARAMOS TODAS AL MISMO TIEMPO
      final results = await Future.wait(futures);

      // 4. CONTAMOS CUÁNTAS FUERON EXITOSAS
      successCount = results.where((success) => success).length;

      // 5. RECARGAMOS LA LISTA DE MATERIAS DEL TUTOR
      await subjectsProvider.loadTutorSubjects(authProvider);
      
    } catch (e) {
      print("❌ Error al agregar materias: $e");
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        navigator.pop();

        // 6. MOSTRAMOS EL SNACKBAR FINAL
        if(successCount == totalCount) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('$successCount materias agregadas'), backgroundColor: AppColors.primaryGreen)
          );
        } else if (successCount > 0) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('$successCount de $totalCount agregadas. Algunas fallaron.'), backgroundColor: Colors.orange)
          );
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(subjectsProvider.error ?? 'Error al agregar'), backgroundColor: AppColors.redColor)
          );
        }
      }
    } 
    //  if (!mounted) return;
    //   scaffoldMessenger.showSnackBar(SnackBar(content: Text(subjectsProvider.error ?? 'Error al agregar'), backgroundColor: AppColors.redColor));
    //   setState(() => _isSaving = false);
    //   return; 
  }

  void _toggleSelection(int id) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedSubjectIds.contains(id)) {
        _selectedSubjectIds.remove(id);
      } else {
        _selectedSubjectIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0C0E12) : const Color(0xFFF4F6F9);
    final cardColor = isDark ? const Color(0xFF16181D) : Colors.white;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88, // Deja un espacio arriba
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Píldora superior
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),

          // BUSCADOR (Diseño idéntico a tu foto)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: isDark ? Colors.white : AppColors.brandBlue, fontWeight: FontWeight.w600, fontFamily: kFontFamily),
                decoration: InputDecoration(
                  hintText: "Busca tus especialidades...",
                  hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey[400], fontFamily: kFontFamily),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.brandCyan),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white30 : Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            FocusScope.of(context).unfocus();
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // TÍTULO "MATERIAS DISPONIBLES"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "MATERIAS DISPONIBLES",
                style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, fontFamily: kFontFamily),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // LISTA DE MATERIAS
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.brandCyan))
                : _filteredSubjects.isEmpty
                    ? Center(child: Text("No se encontraron materias", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)))
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: _filteredSubjects.length,
                        itemBuilder: (context, index) {
                          final item = _filteredSubjects[index];
                          final isSelected = _selectedSubjectIds.contains(item['id']);

                          return _SelectableSubjectItem(
                            name: item['name'],
                            isSelected: isSelected,
                            isDark: isDark,
                            onTap: () => _toggleSelection(item['id']),
                          );
                        },
                      ),
          ),

          // LOS DOS BOTONES INFERIORES
          Container(
            padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text("Cancelar", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontWeight: FontWeight.bold, fontFamily: kFontFamily)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: (_selectedSubjectIds.isEmpty || _isSaving) ? null : _saveSelections,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.brandCyan,
                      disabledBackgroundColor: isDark ? Colors.white10 : Colors.grey[300],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            _selectedSubjectIds.isEmpty ? "Seleccionar" : "Añadir ${_selectedSubjectIds.length}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: kFontFamily),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// WIDGET INTERNO: EL ITEM DE LA LISTA CON EL "+"
class _SelectableSubjectItem extends StatelessWidget {
  final String name;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _SelectableSubjectItem({
    required this.name,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF16181D) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandBlue;
    
    final selectedBgColor = AppColors.brandCyan.withOpacity(0.08);
    final borderColor = isSelected ? AppColors.brandCyan : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            // Icono (+) o (Check)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: RotationTransition(turns: animation, child: child));
              },
              child: isSelected
                  ? const Icon(Icons.check_circle_rounded, key: ValueKey('check'), color: AppColors.brandCyan, size: 22)
                  : Icon(Icons.add_rounded, key: const ValueKey('add'), color: isDark ? Colors.white54 : AppColors.brandCyan, size: 22),
            ),
            
            const SizedBox(width: 16),
            
            // Nombre de la Materia
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: isSelected ? AppColors.brandCyan : textColor,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontFamily: kFontFamily,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}