import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/provider/tutor_subjects_provider.dart';
import 'package:flutter_projects/api_structure/api_service.dart';

const String _kFontFamily = 'manrope';
const String _kTitleFont = 'outfit';

class AddSubjectSheet extends StatefulWidget {
  final bool isRegistration;
  final Function(List<int>)? onRegistrationComplete;

  const AddSubjectSheet({
    Key? key, 
    this.isRegistration = false, 
    this.onRegistrationComplete,
  }) : super(key: key);

  @override
  State<AddSubjectSheet> createState() => _AddSubjectSheetState();
}

class _AddSubjectSheetState extends State<AddSubjectSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _availableSubjects = [];
  final Set<int> _selectedSubjectIds = {};
  
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isSaving = false;
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final subjectsProvider = Provider.of<TutorSubjectsProvider>(context, listen: false);
      
      final query = _searchController.text.trim();
      
      String? tokenToUse;
      if (!widget.isRegistration) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        tokenToUse = authProvider.token;
      }

      final response = await getAllSubjects(
        authProvider.token!, 
        page: reset ? 1 : _currentPage + 1, 
        perPage: 20,
        keyword: query.isEmpty ? null : query
      );

      if (!mounted) return;

      if (response['status'] == 200 && response['data'] != null) {
        final List<dynamic> subjectsData = response['data']['data'];
        List<Map<String, dynamic>> filtered = [];

        if (widget.isRegistration) {
          filtered = subjectsData
              .map((s) => {'id': s['id'], 'name': s['name']})
              .toList();
        } else {
          final subjectsProvider = Provider.of<TutorSubjectsProvider>(context, listen: false);
          final currentSubjectIds = subjectsProvider.subjects.map((s) => s.subjectId).toSet();
          
          filtered = subjectsData
              .where((s) => !currentSubjectIds.contains(s['id']))
              .map((s) => {'id': s['id'], 'name': s['name']})
              .toList();
        }
        // final currentSubjectIds = subjectsProvider.subjects.map((s) => s.subjectId).toSet();
        
        // final filtered = subjectsData
        //     .where((s) => !currentSubjectIds.contains(s['id']))
        //     .map((s) => {'id': s['id'], 'name': s['name']})
        //     .toList();
        
        setState(() {
          if (reset) {
            _availableSubjects = filtered;
          } else {
            _availableSubjects.addAll(filtered);
          }
          _currentPage = response['data']['current_page'] ?? 1;
          _lastPage = response['data']['last_page'] ?? 1;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _isLoadingMore = false; });
    }
  }

  Future<void> _saveSelections() async {
    if (_selectedSubjectIds.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);

    final navigator = Navigator.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final subjectsProvider = Provider.of<TutorSubjectsProvider>(context, listen: false);

    try {
      final results = await Future.wait(
        _selectedSubjectIds.map((id) => 
          subjectsProvider.addTutorSubjectToApi(authProvider, id, '', null)
        )
      );

      int successCount = results.where((s) => s).length;
      await subjectsProvider.loadTutorSubjects(authProvider);
      
      if (mounted) {
        navigator.pop();
        if (successCount > 0) {
          CustomToast.show(
            context, 
            "$successCount materia${successCount > 1 ? 's' : ''} añadida${successCount > 1 ? 's' : ''} correctamente.",
            isSuccess: true,
          );
        } else {
          CustomToast.show(
            context, 
            "No se pudieron añadir las materias. Intenta de nuevo.",
            isSuccess: false,
          );
          
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0C0E12) : const Color(0xFFF4F6F9);
    final cardColor = isDark ? const Color(0xFF16181D) : Colors.white;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),

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
                onChanged: _onSearchChanged,
                style: TextStyle(color: isDark ? Colors.white : AppColors.brandBlue, fontWeight: FontWeight.w600, fontFamily: _kFontFamily),
                decoration: InputDecoration(
                  hintText: "Buscar materia...",
                  hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey[400], fontFamily: _kTitleFont),
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.brandCyan),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandCyan))
              : _availableSubjects.isEmpty 
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: _availableSubjects.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _availableSubjects.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }
                        final item = _availableSubjects[index];
                        return _SelectableSubjectItem(
                          name: item['name'],
                          isSelected: _selectedSubjectIds.contains(item['id']),
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (_selectedSubjectIds.contains(item['id'])) {
                                _selectedSubjectIds.remove(item['id']);
                              } else {
                                _selectedSubjectIds.add(item['id']);
                              }
                            });
                          },
                        );
                      },
                    ),
          ),

          _buildBottomBar(isDark, cardColor),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SingleChildScrollView( 
      child: Padding(
        padding: const EdgeInsets.only(top: 40), 
        child: Column(
          children: [
            Icon(Icons.info_outline_rounded, size: 64, color: isDark ? Colors.white12 : Colors.grey[200]),
            const SizedBox(height: 16),
            Text(
              "No se encontraron materias nuevas.",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[500], fontFamily: _kTitleFont, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Es posible que ya las tengas agregadas o que no existan en el catálogo.",
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white24 : Colors.grey[400], fontSize: 12, fontFamily: _kTitleFont),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark, Color cardColor) {
    return Container(
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
              child: Text("Cancelar", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontWeight: FontWeight.bold, fontFamily: _kTitleFont)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: (_selectedSubjectIds.isEmpty || _isSaving) ? null : () {
              if (widget.isRegistration) {
                  widget.onRegistrationComplete?.call(_selectedSubjectIds.toList());
                  Navigator.pop(context);
                   // Solo cerramos y devolvemos los datos
                } else {
                  _saveSelections(); // Llama a tu API para guardar (Modo Edición)
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.brandCyan,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    _selectedSubjectIds.isEmpty ? "Seleccionar" : "Añadir ${_selectedSubjectIds.length}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: _kTitleFont),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableSubjectItem extends StatelessWidget {
  final String name;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _SelectableSubjectItem({required this.name, required this.isSelected, required this.isDark, required this.onTap});

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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isSelected
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.brandCyan, size: 22)
                  : Icon(Icons.add_rounded, color: isDark ? Colors.white54 : AppColors.brandCyan, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: isSelected ? AppColors.brandCyan : textColor,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontFamily: _kFontFamily,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
